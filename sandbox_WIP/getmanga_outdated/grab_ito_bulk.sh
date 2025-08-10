#!/data/data/com.termux/files/usr/bin/bash

# Create target folder if it doesn't exist
TARGET="/storage/emulated/0/Pictures/Ito Grab"
mkdir -p "$TARGET"

# Loop through chapter numbers 2 to 20
for i in $(seq 2 20); do
  CHAPTER_URL="https://w7.junji-ito.com/manga/uzumaki-chapter-$i/"
  FOLDER_NAME="uzumaki_ch${i}"
  echo "Downloading Chapter $i..."

  # Run the download script
  ./get_ito_chapter.sh "$CHAPTER_URL" "$FOLDER_NAME"

  # Move the folder to Pictures
  mv "$FOLDER_NAME" "$TARGET/"
done
