#!/bin/bash

# Create Movies folder if missing
mkdir -p ~/storage/shared/Movies

# Check if cookies.txt is provided
if [ -n "$2" ]; then
  cookies="--cookies $2"
else
  cookies=""
fi

# Download livestream from start to current point, best quality
yt-dlp --live-from-start --no-live -f "bestvideo+bestaudio/best" --merge-output-format mp4 $cookies -o "temp_video.%(ext)s" "$1"

# Get final filename from yt-dlp's output
final_file=$(find . -maxdepth 1 -name "temp_video.*" -print -quit)

# Move to Movies folder and sanitize filename
clean_title=$(echo "$final_file" | sed 's/[^a-zA-Z0-9._-]/_/g')
mv "$final_file" ~/storage/shared/Movies/"$clean_title"

# Scan for visibility
termux-media-scan ~/storage/shared/Movies/"$clean_title"

# Cleanup temp files
rm -f temp_video.* *.part
