#!/data/data/com.termux/files/usr/bin/bash

# Create target folder
TARGET="/storage/emulated/0/Pictures/Ito Grab"
mkdir -p "$TARGET"

# Loop through Tomie chapters 1 to 20
for i in $(seq 1 20); do
  CHAPTER_URL="https://w7.junji-ito.com/manga/tomie-chapter-$i/"
  FOLDER_NAME="tomie_ch${i}"
  echo "Downloading Chapter $i..."

  # Create folder and download HTML
  mkdir -p "$FOLDER_NAME"
  cd "$FOLDER_NAME" || exit
  curl -s "$CHAPTER_URL" -o page.html

  # Extract and limit to 50 image URLs
  grep -o 'https://[^"]*\.jpg' page.html | head -n 50 > urls.txt

  # Download and rename images
  a=1
  while read -r url; do
    filename=$(printf "%s_%03d.jpg" "$FOLDER_NAME" "$a")
    wget -q "$url" -O "$filename"
    echo "Downloaded: $filename"
    a=$((a + 1))
  done < urls.txt

  # Cleanup and move folder
  rm page.html urls.txt
  cd ..
  mv "$FOLDER_NAME" "$TARGET/"
done
