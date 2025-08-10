#!/bin/bash  

# Create folder  
mkdir -p ~/storage/shared/Documents/Transcripts  

# Download German subs  
yt-dlp --write-auto-sub --sub-lang de --skip-download -o "%(title)s.%(ext)s" "$1"  

# Clean, fix encoding, add timestamps  
de_sub=$(find . -maxdepth 1 -name "*.de.vtt" -print -quit)  
if [ -f "$de_sub" ]; then  
  sed -E 's/<[^>]*>//g; s/&nbsp;/ /g; /^$/d' "$de_sub" |  
  iconv -f UTF-8 -t UTF-8//TRANSLIT |  
  dos2unix |  
  perl -C -MEncode -pe '$_=decode("UTF-8", $_)' |  # Fix double-encoded chars  
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
  ' > "${de_sub%.*}.txt"  
  mv "${de_sub%.*}.txt" ~/storage/shared/Documents/Transcripts/  
fi  

# Cleanup  
rm -f *.vtt  
termux-media-scan ~/storage/shared/Documents/Transcripts/  
