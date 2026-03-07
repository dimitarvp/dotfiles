#!/bin/bash
# Reads ffprobe JSON from stdin and outputs the -pix_fmt flag.

# Check if stdin is empty
if [ -t 0 ]; then
	echo "Error: No data piped to stdin." >&2
	echo "Usage: ffprobe -select_streams v -of json ... | $0" >&2
	exit 1
fi

json_input=$(cat)

# Extract the pixel format of the first video stream.
pix_fmt=$(echo "$json_input" | jq -r '.streams[] | .pix_fmt' | head -n 1)

if [[ -z "$pix_fmt" ]]; then
	echo "Error: pix_fmt is empty" >&2
	exit 1
fi

echo "-pix_fmt $pix_fmt"
