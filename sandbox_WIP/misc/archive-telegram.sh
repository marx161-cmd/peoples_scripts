#!/bin/bash  

# Channels to archive (add/remove as needed)  
CHANNELS=("GazaNow" "Quds_News_Network" "ShehabAgency")  

# Max size per channel (2GB = 2000000000 bytes)  
MAX_SIZE=$((2 * 1024 * 1024 * 1024))  

for CHANNEL in "${CHANNELS[@]}"; do  
  FOLDER="$HOME/storage/shared/TelegramArchive/$CHANNEL"  
  ARCHIVE_FILE="$FOLDER/${CHANNEL}_archive.txt"  
  LOG_FILE="$FOLDER/${CHANNEL}_log.txt"  

  # Get current folder size  
  CURRENT_SIZE=$(du -sb "$FOLDER" | cut -f1)  

  # Download only if under 2GB  
  if [ "$CURRENT_SIZE" -lt "$MAX_SIZE" ]; then  
    yt-dlp \  
      --download-archive "$ARCHIVE_FILE" \  
      --max-downloads 200 \                  # Approx 2GB if avg video = 10MB  
      --playlist-reverse \                   # Start with oldest missing content  
      --write-info-json \  
      --write-thumbnail \  
      --no-simulate \  
      -o "$FOLDER/%(upload_date)s_%(title)s.%(ext)s" \  
      "https://t.me/s/$CHANNEL" \  
      >> "$LOG_FILE" 2>&1  
  else  
    echo "Skipping $CHANNEL (already at $((CURRENT_SIZE/1024/1024))MB)"  
  fi  
done  

# Update Android media scanner  
termux-media-scan ~/storage/shared/TelegramArchive  
