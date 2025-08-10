#!/bin/bash  

#!/data/data/com.termux/files/usr/bin/bash

url="$1"

if [ -z "$url" ]; then
  url=$(termux-clipboard-get)
fi

if [ -z "$url" ]; then
  echo "❌ No URL provided or found in clipboard."
  exit 1
fi

echo "📥 Downloading subtitles for: $url"

# Create folder  
mkdir -p ~/storage/shared/Documents/Transcripts  

# Download English subs  
yt-dlp --write-auto-sub --sub-lang en --skip-download -o "%(title)s.%(ext)s" "$url"  

# Clean and add 5-minute timestamps  
en_sub=$(find . -maxdepth 1 -name "*.en.vtt" -print -quit)  
if [ -f "$en_sub" ]; then  
  sed -E 's/<[^>]*>//g; s/&nbsp;/ /g; /^$/d' "$en_sub" |  
  awk '  
    BEGIN { last_stamp = 0 }  
    /^[0-9]{2}:[0-9]{2}:[0-9]{2}.[0-9]{3}/ {  
      split($1, t, /[:.]/);  
      sec = t[1]*3600 + t[2]*60 + t[3];  
      if (sec - last_stamp >= 300) {  
        printf "\n[%02d:%02d:%02d]\n", t[1], t[2], t[3];  
        last_stamp = sec;  
      }  
      next;  
    }  
    !seen[$0]++  
  ' > "${en_sub%.*}.txt"  
  mv "${en_sub%.*}.txt" ~/storage/shared/Documents/Transcripts/  
fi  

# Cleanup  
rm -f *.vtt  
termux-media-scan ~/storage/shared/Documents/Transcripts/  
