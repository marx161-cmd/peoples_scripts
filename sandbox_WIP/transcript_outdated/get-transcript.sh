#!/bin/bash

# Create a "Transcripts" folder if it doesn’t exist
mkdir -p ~/storage/shared/Documents/Transcripts

# Download English and German auto-subs (no video)
yt-dlp --write-auto-sub --sub-lang en,de --skip-download -o "%(title)s.%(ext)s" "$1"

# Clean and move transcripts for both languages
for lang in en de; do
  sub_file=$(find . -maxdepth 1 -name "*.$lang.vtt" -print -quit)
  if [ -f "$sub_file" ]; then
    # Clean the subtitle
    sed -E '/^[0-9]{2}:[0-9]{2}:[0-9]{2}.[0-9]{3}/d; s/<[^>]*>//g; s/&nbsp;/ /g; /^$/d' "$sub_file" | iconv -f UTF-8 -t UTF-8//IGNORE | awk '!seen[$0]++' > "${sub_file%.*}.txt"
    # Move to Transcripts folder
    mv "${sub_file%.*}.txt" ~/storage/shared/Documents/Transcripts/
  fi
done

# Scan the folder to make files visible
termux-media-scan ~/storage/shared/Documents/Transcripts/

# Delete leftover .vtt files
rm -f *.vtt
