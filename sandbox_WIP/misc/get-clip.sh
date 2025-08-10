#!/bin/bash

# Create Movies folder if missing
mkdir -p ~/storage/shared/Movies

# Check if time range is provided
if [ -z "$2" ]; then
  echo "Usage: ./get-clip.sh <video_url> <start-end>"
  echo "Example: ./get-clip.sh https://youtube.com/watch?v=XXXX '*00:01:20:00-00:01:50:00'"
  exit 1
fi

# Download specified clip range using yt-dlp
yt-dlp -f "bestvideo+bestaudio/best" --download-sections "$2" --merge-output-format mp4 -o "temp_clip.%(ext)s" "$1"

# Get final filename
final_file=$(find . -maxdepth 1 -name "temp_clip.*" -print -quit)

# Move to Movies and sanitize
clean_title=$(echo "$final_file" | sed 's/[^a-zA-Z0-9._-]/_/g')
mv "$final_file" ~/storage/shared/Movies/"$clean_title"

# Make visible to media apps
termux-media-scan ~/storage/shared/Movies/"$clean_title"

# Clean leftovers
rm -f temp_clip.* *.part
