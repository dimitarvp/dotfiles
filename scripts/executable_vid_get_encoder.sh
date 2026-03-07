#!/bin/bash
# Reads ffprobe JSON from stdin and outputs the appropriate -c:v encoder flag.
# Assumes the first video stream (v:0) is the target.

# Check if stdin is empty
if [ -t 0 ]; then
	echo "Error: No data piped to stdin." >&2
	echo "Usage: ffprobe -select_streams v -of json | $0" >&2
	exit 1
fi

json_input=$(cat)

codec_name=$(echo "$json_input" | jq -r '.streams[] | .codec_name' | head -n 1)

# Map the codec name to the ffmpeg encoder name
case $codec_name in
h264) encoder="libx264" ;;
hevc) encoder="libx265" ;;
av1) encoder="libsvtav1" ;; # Or libaom-av1, librav1e
vp9) encoder="libvpx-vp9" ;;
*) encoder="$codec_name" ;; # Fallback for simple names
esac

echo "-c:v $encoder"
