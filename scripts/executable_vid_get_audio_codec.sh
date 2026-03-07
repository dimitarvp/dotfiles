#!/bin/bash
# Reads ffprobe JSON from stdin and outputs the -c:a (audio codec) flag.

# Check if stdin is empty
if [ -t 0 ]; then
	echo "Error: No data piped to stdin." >&2
	echo "Usage: ffprobe -select_streams a -of json ... | $0" >&2
	exit 1
fi

json_input=$(cat)

# Extract the codec name of the first audio stream.
codec_name=$(echo "$json_input" | jq -r '.streams[] | .codec_name? // ""' | head -n 1)

if [ "$codec_name" != "" ]; then
	echo "-c:a $codec_name"
fi
