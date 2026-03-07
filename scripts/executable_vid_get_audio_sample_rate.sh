#!/bin/bash
# Reads ffprobe JSON from stdin and outputs the -ar (audio rate) flag.

# Check if stdin is empty
if [ -t 0 ]; then
	echo "Error: No data piped to stdin." >&2
	echo "Usage: ffprobe -select_streams a -of json ... | $0" >&2
	exit 1
fi

json_input=$(cat)

# Extract the sample rate of the first audio stream.
sample_rate=$(echo "$json_input" | jq -r '.streams[] | .sample_rate? // ""' | head -n 1)

if [ "$sample_rate" != "" ]; then
	echo "-ar $sample_rate"
fi
