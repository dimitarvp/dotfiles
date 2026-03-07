#!/bin/bash

# A script to speed up a middle section of a video by re-encoding it
# in a way that is compatible for a final, fast stream copy concatenation.
# It programmatically analyzes the source video to match codec parameters,
# and calculates the required speed based on a desired final duration.
#
# Usage:
# ./vidaccel.sh <input_file> <start_time> <end_time> <target_duration_s> <output_file>
# Example:
# ./vidaccel.sh "Video.mkv" "00:15:22" "00:17:50" 10 "Video_fast.mkv"

# --- Script Setup ---
set -e

# --- Argument Validation ---
if [ "$#" -ne 5 ]; then
	echo "Usage: $0 <input_file> <start_time> <end_time> <target_duration_s> <output_file>"
	echo "Example: $0 'Video.mp4' '00:15:22' '00:17:50' 10 'Video_fast.mp4'"
	exit 1
fi

# --- Check for Dependencies ---
if ! command -v ffmpeg bc ffprobe jq &>/dev/null; then
	echo "Error: some or all of ffmpeg, ffprobe, bc, and jq are not installed or not in your PATH."
	exit 1
fi

DISPLAY_ARGS=("-hide_banner" "-loglevel" "quiet" "-stats")

# --- Assign Arguments to Variables ---
INPUT_FILE="$1"
START_TIMESTAMP="$2"
END_TIMESTAMP="$3"
FINAL_DURATION_SECONDS="$4"
OUTPUT_FILE="$5"

# Calculate speed from target duration
echo "Step 1: Calculating required speed multiplier..."
# Standardized on GNU date syntax as requested.
START_SECONDS=$(date -u -d "$START_TIMESTAMP" "+%s")
END_SECONDS=$(date -u -d "$END_TIMESTAMP" "+%s")
ORIGINAL_DURATION=$(echo "$END_SECONDS - $START_SECONDS" | bc)
if (($(echo "$FINAL_DURATION_SECONDS >= $ORIGINAL_DURATION" | bc -l))); then
	echo "Error: Desired final duration (${FINAL_DURATION_SECONDS}s) must be shorter than the original segment duration (${ORIGINAL_DURATION}s)."
	exit 1
fi
SPEED_MULTIPLIER=$(echo "scale=4; $ORIGINAL_DURATION / $FINAL_DURATION_SECONDS" | bc -l)
printf "  Original segment duration: %ds\n" "$ORIGINAL_DURATION"
printf "  Desired final duration:    %ds\n" "$FINAL_DURATION_SECONDS"
printf "  Calculated speed-up:       %.2fx\n" "$SPEED_MULTIPLIER"

# --- File Validation & Setup ---
if [ ! -f "$INPUT_FILE" ]; then
	echo "Error: Input file not found at '$INPUT_FILE'"
	exit 1
fi
BASENAME=$(basename -- "$INPUT_FILE")
EXTENSION="${BASENAME##*.}"
FILENAME="${BASENAME%.*}"
if [ "$BASENAME" == "$FILENAME" ] || [ "$EXTENSION" = "" ]; then
	echo "Error: Input file '$INPUT_FILE' appears to have no file extension."
	exit 1
fi
TEMP_DIR=$(mktemp -d)
trap 'echo "Cleaning up temporary files..."; rm -r "$TEMP_DIR"' EXIT

PART1="${TEMP_DIR}/${FILENAME}_part1.${EXTENSION}"
PART2_ORIGINAL="${TEMP_DIR}/${FILENAME}_part2_original.${EXTENSION}"
PART2_FAST="${TEMP_DIR}/${FILENAME}_part2_fast.${EXTENSION}"
PART3="${TEMP_DIR}/${FILENAME}_part3.${EXTENSION}"
CONCAT_FILE="${TEMP_DIR}/mylist.txt"

# Dynamic stream analysis and flag generation
echo "Step 2: Analyzing original video stream parameters..."
eval "$(
	ffprobe -v error \
		-show_entries stream=codec_type,codec_name,sample_rate,channel_layout,profile,level,pix_fmt,time_base \
		-of json "$INPUT_FILE" |
		jq -r '
    ([.streams[] | select(.codec_type=="video")][0] // {}) as $v |
    ([.streams[] | select(.codec_type=="audio")][0] // {}) as $a |
    "V_CODEC_NAME=\($v.codec_name // "")", "V_PROFILE=\($v.profile // "")",
    "V_LEVEL=\($v.level // "")", "V_PIX_FMT=\($v.pix_fmt // "")",
    "V_TIME_BASE=\($v.time_base // "")", "A_CODEC=\($a.codec_name // "")",
    "A_SAMPLE_RATE=\($a.sample_rate // "")", "A_CHANNEL_LAYOUT=\($a.channel_layout // "")"
  '
)"
if [ "$V_CODEC_NAME" = "" ]; then
	echo "❌ Error: No primary video stream found in '$INPUT_FILE'. Cannot proceed."
	exit 1
fi

### MODIFIED: Codec-Aware Flag Building
# Build an array of ffmpeg flags based on the analyzed parameters
FFMPEG_FLAGS=()
# Universal video flags that apply to most codecs
if [ "$V_PIX_FMT" != "" ]; then FFMPEG_FLAGS+=("-pix_fmt" "$V_PIX_FMT"); fi
if [ "$V_TIME_BASE" != "" ]; then FFMPEG_FLAGS+=("-video_track_timescale" "${V_TIME_BASE##*/}"); fi

# Codec-specific flags
case $V_CODEC_NAME in
h264 | hevc)
	FFMPEG_FLAGS+=("-c:v" "libx264") # Assuming h264 for this case, can be expanded
	if [ "$V_PROFILE" != "" ]; then FFMPEG_FLAGS+=("-profile:v" "$V_PROFILE"); fi
	if [[ -n "$V_LEVEL" && "$V_LEVEL" != "-99" ]]; then FFMPEG_FLAGS+=("-level:v" "$(echo "scale=1; $V_LEVEL / 10" | bc)"); fi
	;;
av1)
	FFMPEG_FLAGS+=("-c:v" "libsvtav1")
	# NOTE: libsvtav1 does not use -profile:v or -level:v in the same way.
	# We intentionally omit them to allow the encoder to work correctly.
	# More advanced logic could map AV1 profiles (Main, High, Professional) to
	# the encoder's specific tier options if needed, but omitting is safer.
	;;
*)
	FFMPEG_FLAGS+=("-c:v" "$V_CODEC_NAME")
	;;
esac

# Audio flags (only if an audio stream exists)
if [ "$A_CODEC" != "" ]; then
	FFMPEG_FLAGS+=("-c:a" "$A_CODEC")
	if [ "$A_SAMPLE_RATE" != "" ]; then FFMPEG_FLAGS+=("-ar" "$A_SAMPLE_RATE"); fi
	if [ "$A_CHANNEL_LAYOUT" != "" ]; then FFMPEG_FLAGS+=("-channel_layout" "$A_CHANNEL_LAYOUT"); fi
fi

# --- Main Logic ---
CONCAT_LIST=()
if [ "$START_TIMESTAMP" != "00:00:00" ]; then
	echo "Step 3: Creating pre-acceleration segment..."
	ffmpeg -i "$INPUT_FILE" -to "$START_TIMESTAMP" -c copy -y "$PART1" "${DISPLAY_ARGS[@]}"
	CONCAT_LIST+=("$PART1")
else
	echo "Step 3: Skipping pre-acceleration segment (starting from 00:00:00)."
fi

echo "Step 4: Isolating and re-encoding middle segment..."
ffmpeg -ss "$START_TIMESTAMP" -to "$END_TIMESTAMP" -i "$INPUT_FILE" -c copy -y "$PART2_ORIGINAL" "${DISPLAY_ARGS[@]}"

REMAINING_SPEED=$SPEED_MULTIPLIER
ATEMPO_FILTER=""
while (($(echo "$REMAINING_SPEED > 2.0" | bc -l))); do
	ATEMPO_FILTER+="atempo=2.0,"
	REMAINING_SPEED=$(echo "$REMAINING_SPEED / 2.0" | bc)
done
ATEMPO_FILTER+="atempo=$REMAINING_SPEED"

RECODE_CMD=("ffmpeg" "-i" "$PART2_ORIGINAL" "-vf" "setpts=PTS/${SPEED_MULTIPLIER}")
if [ "$A_CODEC" != "" ]; then
	RECODE_CMD+=("-af" "$ATEMPO_FILTER")
fi
RECODE_CMD+=("${FFMPEG_FLAGS[@]}" "-y" "$PART2_FAST" "${DISPLAY_ARGS[@]}")
"${RECODE_CMD[@]}"

CONCAT_LIST+=("$PART2_FAST")

echo "Step 5: Creating post-acceleration segment..."
if ffmpeg -v error -ss "$END_TIMESTAMP" -i "$INPUT_FILE" -c copy -y "$PART3" "${DISPLAY_ARGS[@]}"; then
	PART3_DUR=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$PART3" || echo 0)
	if (($(echo "$PART3_DUR > 0.1" | bc -l))); then
		CONCAT_LIST+=("$PART3")
	else
		echo "  (Post-acceleration segment is empty, will be excluded)"
	fi
else
	echo "  (End of video reached, no post-acceleration segment needed)"
fi

for f in "${CONCAT_LIST[@]}"; do
	printf "file '%s'\n" "$f" >>"$CONCAT_FILE"
done

echo "Step 6: Stitching all parts together..."
ffmpeg -f concat -safe 0 -i "$CONCAT_FILE" -c copy -y "$OUTPUT_FILE" "${DISPLAY_ARGS[@]}"

echo "Step 7: Verifying final video integrity..."
EXPECTED_DURATION=0
for f in "${CONCAT_LIST[@]}"; do
	DUR=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$f" || echo 0)
	EXPECTED_DURATION=$(echo "$EXPECTED_DURATION + $DUR" | bc)
done
ACTUAL_DURATION=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$OUTPUT_FILE")
DURATION_MISMATCH=$(echo "scale=2; diff = $EXPECTED_DURATION - $ACTUAL_DURATION; if (diff < 0) diff = -diff; diff > 1.0" | bc)

if [ "$DURATION_MISMATCH" -eq 1 ]; then
	echo "⚠️  Warning: The final video duration does not match the sum of its parts."
	echo "   Expected duration: ~${EXPECTED_DURATION}s"
	echo "   Actual duration:   ${ACTUAL_DURATION}s"
	echo "   A segment was likely dropped. The final file is at: $OUTPUT_FILE"
else
	echo "✅ Success! Your final video has been saved to: $OUTPUT_FILE"
fi
