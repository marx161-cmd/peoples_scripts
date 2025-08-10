#!/data/data/com.termux/files/usr/bin/bash

# Usage: ./get_ito_chapter.sh <chapter-url> <folder-name>

CHAPTER_URL="$1"
FOLDER_NAME="$2"

mkdir -p "$FOLDER_NAME"
cd "$FOLDER_NAME" || exit

# Step 1: Download HTML
curl -s "$CHAPTER_URL" -o page.html

# Step 2: Extract image URLs
grep -o 'https://[^"]*\.jpg' page.html > urls.txt

# Step 3: Download and rename images
a=1
while read -r url; do
  filename=$(printf "%s_%03d.jpg" "$FOLDER_NAME" "$a")
  wget -q "$url" -O "$filename"
  echo "Downloaded: $filename"
  a=$((a + 1))
done < urls.txt

# Clean up
rm page.html urls.txt
