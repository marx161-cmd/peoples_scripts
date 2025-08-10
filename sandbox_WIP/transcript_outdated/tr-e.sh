#!/usr/bin/env bash
set -euo pipefail
source "$HOME/.scripts/common.sh"

LANG_CODE="en"   # change to "de" for German; or make a copy named get-transcriptde.sh with LANG_CODE="de"
OUTDIR="$(documents_dir)/Transcripts"
ensure_dir "$OUTDIR"

# 1) URL argument or clipboard
URL="${1:-}"
if [[ -z "$URL" ]]; then
  if URL="$(clipboard_get 2>/dev/null)"; then
    :  # got it from clipboard
  else
    echo "Usage: $0 <YouTube URL>  (or copy URL to clipboard and run without args)"
    exit 1
  fi
fi

echo "📥 Downloading subtitles for: $URL"
yt-dlp --write-auto-sub --sub-lang "$LANG_CODE" --skip-download -o "%(title)s.%(ext)s" "$URL"

# 2) Find the *.vtt we just created
sub_file="$(find . -maxdepth 1 -type f -name "*.${LANG_CODE}.vtt" -print -quit)"
if [[ -z "${sub_file:-}" ]]; then
  echo "❌ No auto-generated ${LANG_CODE} subtitles found."
  exit 1
fi

# 3) Clean + add 5-min timestamps
# (on Ubuntu, if dos2unix is missing we just strip CR with tr)
clean_txt="$(mktemp)"
{
  sed -E 's/<[^>]*>//g; s/&nbsp;/ /g; /^$/d' "$sub_file" |
  { command -v dos2unix >/dev/null 2>&1 && dos2unix || tr -d "\r"; } |
  awk '
    BEGIN { last=0 }
    /^[0-9]{2}:[0-9]{2}:[0-9]{2}[.,][0-9]{3}/ {
      split($1, t, /[:.,]/);
      s = t[1]*3600 + t[2]*60 + t[3];
      if (s - last >= 300) {
        printf "\n[%02d:%02d:%02d]\n", t[1], t[2], t[3];
        last = s;
      }
      next;
    }
    !seen[$0]++
  '
} > "$clean_txt"

# 4) Save into Documents/Transcripts on both systems
base="${sub_file%.*}"         # drop .vtt
base="${base%.*}"             # drop .en/.de
safe="$(sanitize_filename "$base")"
mv "$clean_txt" "$OUTDIR/$safe.txt"
rm -f -- *.vtt

media_scan "$OUTDIR/$safe.txt"  # does nothing on Ubuntu
echo "✅ Saved: $OUTDIR/$safe.txt"