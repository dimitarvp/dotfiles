#!/bin/bash
# Reads ffprobe JSON from stdin and outputs the -profile:v flag.

# Check if stdin is empty
if [ -t 0 ]; then
	echo "Error: No data piped to stdin." >&2
	echo "Usage: ffprobe -select_streams v -of json ... | $0" >&2
	exit 1
fi

json_input=$(cat)

# Extract the profile of the first video stream
profile=$(echo "$json_input" | jq -r '.streams[] | .profile' | head -n 1)

if [[ -z "$profile" ]]; then
	echo "Error: profile is empty" >&2
	exit 1
fi

echo "-profile:v $profile"
