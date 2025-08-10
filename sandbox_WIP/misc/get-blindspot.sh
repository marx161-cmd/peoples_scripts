#!/data/data/com.termux/files/usr/bin/bash

# URL is hardcoded in this version
CHAPTER_URL="https://w7.junji-ito.com/manga/venus-in-the-blind-spot-chapter-1/"

# Folder name from URL
FOLDER_NAME="venus_blind_ch1"
TARGET="/storage/emulated/0/Pictures/Ito Grab"

# Make folder
mkdir -p "$TARGET/$FOLDER_NAME"
cd "$TARGET/$FOLDER_NAME" || exit

echo "Downloading chapter from: $CHAPTER_URL"
echo "Saving to: $TARGET/$FOLDER_NAME"

# Fetch HTML with fake user-agent
curl -s -A "Mozilla/5.0" "$CHAPTER_URL" -o page.html

# Extract image URLs for jpg/png/webp (limit 50)
grep -o 'https[^"]*\.jpg\|png\|webp' page.html | head -n 50 > urls.txt

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

echo "Done! Chapter saved to $TARGET/$FOLDER_NAME"
