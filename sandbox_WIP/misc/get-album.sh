#!/bin/bash

# Download entire album or single song
yt-dlp -f "bestaudio" -x --audio-format mp3 --audio-quality 0 \
--embed-thumbnail --convert-thumbnails jpg \
-o ~/storage/shared/Music/%(playlist_title)s/%(title)s.%(ext)s "$1"

# Scan for visibility
termux-media-scan ~/storage/shared/Music/
am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d file:///storage/emulated/0/Music/
