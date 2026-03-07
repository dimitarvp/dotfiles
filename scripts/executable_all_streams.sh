#!/bin/bash

# --- Argument Validation ---
if [ "$#" -ne 1 ]; then
	echo "Usage: $0 <input_video_file>"
	echo "Example: $0 'Video.mp4'"
	exit 1
fi

# --- Check for Dependencies ---
if ! command -v ffprobe &>/dev/null; then
	echo "Error: ffprobe is not installed or not in your PATH."
	exit 1
fi

# --- Assign Arguments to Variables ---
INPUT_FILE="$1"

# --- File Validation ---
if [ ! -f "$INPUT_FILE" ]; then
	echo "Error: Input file not found at '$INPUT_FILE'"
	exit 1
fi

ffprobe -v error -show_entries stream=codec_name,profile,level,pix_fmt,time_base,color_space,color_primaries,color_transfer -output_format json "$1"
