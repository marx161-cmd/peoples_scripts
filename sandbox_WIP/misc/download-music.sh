#!/bin/bash
#!/bin/bash  

# Download best audio, convert to MP3, and embed thumbnail  
yt-dlp -f "bestaudio" -x --audio-format mp3 --audio-quality 0 --embed-thumbnail --convert-thumbnails jpg "$1" -o "~/storage/shared/Music/%(title)s.%(ext)s"  

# Scan the Music folder  
termux-media-scan ~/storage/shared/Music/       yt-dlp -f "bestaudio" -x --audio-format mp3 --audio-quality 0 --embed-thumbnail --ppa "EmbedThumbnail+ffmpeg_o:-c:v mjpeg -vf crop=\"'if(gt(ih,iw),iw,if(gt(iw,ih),ih,iw)':'if(gt(iw,ih),ih,if(gt(ih,iw),iw,ih)'\"" "$1" -o "~/storage/shared/Music/%(title)s.%(ext)s"
     termux-media-scan ~/storage/shared/Music/yt-dlp -f 251 -x --audio-format mp3 "$1" -o ~/storage/shared/Music/"%(title)s.mp3"
termux-media-scan ~/storage/shared/Music/
