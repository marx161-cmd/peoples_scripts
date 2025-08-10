#!/usr/bin/env bash
set -euo pipefail
source "$HOME/.scripts/common.sh"

OUTDIR="$(documents_dir)/web_articles"
ensure_dir "$OUTDIR"
TMP="$(mktemp)"

# URL from arg or clipboard
URL="${1:-}"
if [[ -z "$URL" ]]; then
  if URL="$(clipboard_get 2>/dev/null)"; then :; else
    echo "Usage: $0 <URL>  (or copy URL to clipboard and run without args)"
    exit 1
  fi
fi

# Generate filename from <title> or timestamp
get_filename() {
  local title
  title="$(curl -sL "$URL" | grep -oP '(?<=<title>)[^<]+' | head -1 || true)"
  if [[ -z "$title" ]]; then
    date +"article_%Y%m%d-%H%M%S.txt"
  else
    printf '%s' "$title" | tr -cd '[:alnum:] ._-' | tr ' ' '_' | tr -s '_' | sed 's/_$//' | cut -c1-50
    printf '.txt'
  fi
}

OUTFILE="$OUTDIR/$(get_filename)"

clean_text() {
  local f="$1"
  # Remove Lynx artifacts, fix encoding-ish, squeeze blank lines
  sed -i 's/(BUTTON)//g; s/(IMAGE)//g; s/____________________//g' "$f"
  sed -i "s/æ/ae/g; s/Æ/AE/g; s/ø/o/g; s/Ø/O/g; s/å/a/g; s/Å/A/g" "$f"
  sed -i '/^[[:space:]]*$/d' "$f"
}

# Method 1: readability-cli + pandoc
if command -v readability-cli >/dev/null 2>&1 && command -v pandoc >/dev/null 2>&1; then
  if curl -sL "$URL" | readability-cli > "$TMP" 2>/dev/null; then
    if pandoc "$TMP" -t plain -o "$OUTFILE" 2>/dev/null && [[ -s "$OUTFILE" ]]; then
      clean_text "$OUTFILE"; rm -f "$TMP"
      echo "Saved using Readability+Pandoc: $(basename "$OUTFILE")"
      media_scan "$OUTFILE"
      exit 0
    fi
  fi
fi

# Method 2: lynx
if command -v lynx >/dev/null 2>&1; then
  if lynx --dump --nolist "$URL" > "$OUTFILE" 2>/dev/null && [[ -s "$OUTFILE" ]]; then
    clean_text "$OUTFILE"
    echo "Saved using Lynx: $(basename "$OUTFILE")"
    media_scan "$OUTFILE"
    exit 0
  fi
fi

# Method 3: pandoc fallback
if command -v pandoc >/dev/null 2>&1; then
  if curl -sL "$URL" | pandoc -f html -t plain -o "$OUTFILE" 2>/dev/null && [[ -s "$OUTFILE" ]]; then
    clean_text "$OUTFILE"
    echo "Saved using raw Pandoc: $(basename "$OUTFILE")"
    media_scan "$OUTFILE"
    exit 0
  fi
fi

# Method 4: super basic strip
curl -sL "$URL" | sed -e 's/<[^>]*>//g' > "$OUTFILE" || true
if [[ -s "$OUTFILE" ]]; then
  clean_text "$OUTFILE"
  echo "Partial success! Saved basic text: $(basename "$OUTFILE")"
  media_scan "$OUTFILE"
  exit 0
fi

echo "Error: Failed to extract article text" >&2
rm -f "$OUTFILE" "$TMP"
exit 1