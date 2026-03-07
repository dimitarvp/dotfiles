#!/bin/bash
# Reads ffprobe JSON from stdin and outputs the -channel_layout flag.

# Check if stdin is empty
if [ -t 0 ]; then
	echo "Error: No data piped to stdin." >&2
	echo "Usage: ffprobe -select_streams a -of json ... | $0" >&2
	exit 1
fi

json_input=$(cat)

# Extract the channel layout of the first audio stream.
layout=$(echo "$json_input" | jq -r '.streams[] | .channel_layout? // ""' | head -n 1)

if [ "$layout" != "" ]; then
	echo "-channel_layout $layout"
fi
