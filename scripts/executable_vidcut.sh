#!/bin/bash

# A script to cut out a middle section of a video without re-encoding.
# It dynamically handles the file extension and intelligently handles
# edge cases where the cut is at the beginning or end of the video.
#
# Usage:
# ./vidcut.sh <input_file> <start_timestamp> <end_timestamp> <output_file>
# Example:
# ./vidcut.sh "Video.mkv" "00:15:22" "00:17:50" "Video_cut.mkv"

# --- Script Setup ---
set -e

# --- Argument Validation ---
if [ "$#" -ne 4 ]; then
	echo "Usage: $0 <input_file> <start_timestamp> <end_timestamp> <output_file>"
	echo "Example: $0 'Video.mp4' '00:06:37' '00:10:00' 'Video_cut.mp4'"
	exit 1
fi

# --- Check for Dependencies ---
if ! command -v ffmpeg &>/dev/null; then
	echo "Error: ffmpeg is not installed or not in your PATH."
	exit 1
fi

### ADDED: Centralized ffmpeg display arguments for consistency
DISPLAY_ARGS=("-hide_banner" "-loglevel" "quiet" "-stats")

# --- Assign Arguments to Variables ---
INPUT_FILE="$1"
START_TIMESTAMP="$2"
END_TIMESTAMP="$3"
OUTPUT_FILE="$4"

# --- File Validation ---
if [ ! -f "$INPUT_FILE" ]; then
	echo "Error: Input file not found at '$INPUT_FILE'"
	exit 1
fi

# --- Extract Filename Parts ---
BASENAME=$(basename -- "$INPUT_FILE")
EXTENSION="${BASENAME##*.}"
FILENAME="${BASENAME%.*}"
if [ "$BASENAME" == "$FILENAME" ] || [ "$EXTENSION" = "" ]; then
	echo "Error: Input file '$INPUT_FILE' appears to have no file extension."
	exit 1
fi

### MODIFIED: Added automatic cleanup trap for robustness
# --- Define Intermediate Filenames ---
TEMP_DIR=$(mktemp -d)
trap 'echo "Cleaning up temporary files..."; rm -r "$TEMP_DIR"' EXIT
LEFT_PART="${TEMP_DIR}/${FILENAME}_left.${EXTENSION}"
RIGHT_PART="${TEMP_DIR}/${FILENAME}_right.${EXTENSION}"
CONCAT_FILE="${TEMP_DIR}/mylist.txt"

### MODIFIED: Complete overhaul of the main logic for edge-case handling
# --- Main Logic ---
# We build a dynamic list of parts to concatenate, handling edge cases gracefully.
CONCAT_LIST=()

# --- Create Left Part (before the cut) ---
# Only create a "before" segment if the start time is not 0.
if [ "$START_TIMESTAMP" != "00:00:00" ]; then
	echo "Step 1: Creating the first part (from beginning to $START_TIMESTAMP)..."
	ffmpeg -i "$INPUT_FILE" -to "$START_TIMESTAMP" -c copy -y "$LEFT_PART" "${DISPLAY_ARGS[@]}"
	CONCAT_LIST+=("$LEFT_PART")
else
	echo "Step 1: Skipping the first part (cut starts at 00:00:00)."
fi

# --- Create Right Part (after the cut) ---
# We run the command and check its success. ffmpeg will fail if the seek time
# is past the end of the file, which is what we want.
echo "Step 2: Creating the second part (from $END_TIMESTAMP to end)..."
if ffmpeg -ss "$END_TIMESTAMP" -i "$INPUT_FILE" -c copy -y "$RIGHT_PART" "${DISPLAY_ARGS[@]}"; then
	# If ffmpeg succeeded, check if the resulting file actually has content.
	# This handles cases where the timestamp is exactly at the end.
	PART2_DUR=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$RIGHT_PART" || echo 0)
	if (($(echo "$PART2_DUR > 0.1" | bc -l 2>/dev/null || echo 0))); then
		CONCAT_LIST+=("$RIGHT_PART")
	else
		echo "  (The second part is empty, will be excluded from final video)"
	fi
else
	echo "  (End of video reached, no second part will be created)"
fi

# --- Final Assembly ---
echo "Step 3: Assembling the final video..."
# Determine the final action based on how many valid parts we created.
NUM_PARTS=${#CONCAT_LIST[@]}

if [ "$NUM_PARTS" -eq 2 ]; then
	# The standard case: two parts need to be joined.
	echo "  (Joining two parts...)"
	printf "file '%s'\nfile '%s'\n" "${CONCAT_LIST[0]}" "${CONCAT_LIST[1]}" >"$CONCAT_FILE"
	ffmpeg -f concat -safe 0 -i "$CONCAT_FILE" -c copy -y "$OUTPUT_FILE" "${DISPLAY_ARGS[@]}"
elif [ "$NUM_PARTS" -eq 1 ]; then
	# Edge case: only one part was created (trim from start or end).
	# Just move the single part to the destination, which is faster than concat.
	echo "  (Only one part needed, moving to final destination...)"
	mv "${CONCAT_LIST[0]}" "$OUTPUT_FILE"
elif [ "$NUM_PARTS" -eq 0 ]; then
	# Edge case: the user tried to cut the entire video.
	echo "❌ Error: The specified timestamps would result in an empty video. No output file created."
	exit 1
fi

echo "✅ Success! Your final video has been saved to: $OUTPUT_FILE"
