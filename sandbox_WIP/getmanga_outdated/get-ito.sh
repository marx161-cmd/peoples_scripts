#!/data/data/com.termux/files/usr/bin/bash

# Usage: ./get-ito.sh <chapter-url>

CHAPTER_URL="$1"

# Auto-create folder from slug
FOLDER_NAME=$(basename "$CHAPTER_URL" | tr -d '/')
mkdir -p "$FOLDER_NAME"
cd "$FOLDER_NAME" || exit

# Download HTML
curl -s "$CHAPTER_URL" -o page.html

# Extract image URLs (limit to 50)
grep -o 'https://[^"]*\.jpg' page.html | head -n 50 > urls.txt

# Download images
a=1
while read -r url; do
  filename=$(printf "%s_%03d.jpg" "$FOLDER_NAME" "$a")
  wget -q "$url" -O "$filename"
  echo "Downloaded: $filename"
  a=$((a + 1))
done < urls.txt

# Clean up
rm page.html urls.txt
