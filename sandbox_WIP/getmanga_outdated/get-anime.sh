#!/bin/bash

# Create Movies folder if missing
mkdir -p ~/storage/shared/Movies

# Download best video quality using browser headers
yt-dlp \
  --add-header "Referer: https://animepahe.ru/" \
  --add-header "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64)" \
  -f "bestvideo+bestaudio/best" --merge-output-format mp4 \
  -o "temp_video.%(ext)s" "$1"

# Get final filename from yt-dlp's output
final_file=$(find . -maxdepth 1 -name "temp_video.*" -print -quit)

# Move to Movies folder and sanitize filename
clean_title=$(echo "$final_file" | sed 's/[^a-zA-Z0-9._-]/_/g')
mv "$final_file" ~/storage/shared/Movies/"$clean_title"

# Scan for visibility
termux-media-scan ~/storage/shared/Movies/"$clean_title"

# Cleanup temp files
rm -f temp_video.* *.part
