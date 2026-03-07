#!/bin/bash
# Reads ffprobe JSON from stdin and outputs the appropriate -level:v flag.
# Assumes the first video stream (v:0) is the target.

# Check if stdin is empty
if [ -t 0 ]; then
	echo "Error: No data piped to stdin." >&2
	echo "Usage: ffprobe -select_streams v -of json | $0" >&2
	exit 1
fi

json_input=$(cat)

level=$(echo "$json_input" | jq -r '.streams[] | .level' | head -n 1)

# If level is empty or not a number, exit with error.
if [[ -z "$level" || ! "$level" =~ ^[0-9]+$ ]]; then
	echo "Error: level $level is not a number" >&2
	exit 1
fi

# Transform level '42' to flag value '4.2'
level_result="$(echo "scale=1; $level / 10" | bc)"

echo "-level:v ""$level_result"
