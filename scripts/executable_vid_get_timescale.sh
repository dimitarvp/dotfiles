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

time_base=$(echo "$json_input" | jq -r '.streams[] | .time_base ' | head -n 1)

# If time base is empty or not a number, exit with error.
if [[ -z "$time_base" ]]; then
	echo "Error: time_base is empty" >&2
	exit 1
fi

# Extract the denominator (the part after the '/')
timescale="${time_base##*/}"

echo "-video_track_timescale $timescale"
