#!/usr/bin/env bash
set -euo pipefail

# Load common helpers from ~/.scripts/common.sh; if missing, instruct user to run setup.sh
if [[ -f "$HOME/.scripts/common.sh" ]]; then
  # shellcheck disable=SC1091
  source "$HOME/.scripts/common.sh"
else
  echo "❌ Missing helper: ~/.scripts/common.sh   (Run: bash setup.sh)" >&2
  exit 1
fi

# Print usage information
usage() {
  cat <<'USAGE'
Usage: trans.sh [-l en|de] [URL]

- If URL is omitted, tries clipboard.
- Default language is en.
- Saves to: Documents/Transcripts/<title>.txt
USAGE
}

# Default values
lang="en"
url=""

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    -l|--lang)
      lang="${2:-}"
      if [[ -z "$lang" ]]; then echo "❌ Missing value for -l|--lang" >&2; usage; exit 1; fi
      shift 2
      ;;
    -h|--help)
      usage; exit 0
      ;;
    *)
      # Accept only a single positional argument (URL)
      if [[ -z "$url" ]]; then
        url="$1"
      else
        echo "❌ Unexpected arg: $1" >&2; usage; exit 1
      fi
      shift
      ;;
  esac
done

# Validate language option
case "$lang" in
  en|de) : ;;
  *) echo "❌ Unsupported language: $lang (use en or de)"; usage; exit 1 ;;
esac

# Fallback to clipboard if URL not provided
if [[ -z "${url:-}" ]]; then
  if txt="$(clipboard_get 2>/dev/null || true)"; then
    url="$txt"
  fi
fi

# Ensure URL is set
if [[ -z "${url:-}" ]]; then
  echo "❌ No URL provided and clipboard is empty." >&2
  usage
  exit 1
fi

# Resolve output folder using portable helper
target_dir="$(documents_dir)/Transcripts"
ensure_dir "$target_dir"

echo "📥 Downloading auto-$lang subtitles for:"
echo "    $url"
echo "➡️  Target folder: $target_dir"

# Create a temporary directory for downloads
tmpdir="$(mktemp -d)"
cleanup() { rm -rf "$tmpdir"; }
trap cleanup EXIT

cd "$tmpdir"

# Download only the auto-generated subtitles in the chosen language
if ! yt-dlp --write-auto-sub --sub-lang "$lang" --skip-download -o "%(title)s.%(ext)s" "$url"; then
  echo "❌ yt-dlp failed to fetch subtitles." >&2
  exit 1
fi

# Find the downloaded VTT file for the chosen language
vtt_file="$(find . -maxdepth 1 -type f -name "*.${lang}.vtt" -print -quit || true)"
if [[ -z "$vtt_file" || ! -f "$vtt_file" ]]; then
  echo "❌ No ${lang} subtitles (.vtt) found. The video may not have auto-subs." >&2
  exit 1
fi

# Derive a safe title for the output file
base="$(basename "${vtt_file%.*.*}")"
safe_title="$(sanitize_filename "$base")"
out_txt="${safe_title}.txt"

# Process the VTT file: strip markup, transliterate if German, insert timestamps every 5 minutes, de-duplicate lines
if [[ "$lang" == "de" ]]; then
  # German: transliteration and optional dos2unix
  sed -E 's/<[^>]*>//g; s/&nbsp;/ /g; /^[[:space:]]*$/d' "$vtt_file" \
  | { command -v iconv >/dev/null 2>&1 && iconv -f UTF-8 -t UTF-8//TRANSLIT || cat; } \
  | { command -v dos2unix >/dev/null 2>&1 && dos2unix 2>/dev/null || cat; } \
  | awk '
      BEGIN { last_stamp = 0 }
      /^[0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]{3}/ {
        split($1, t, /[:.]/);
        sec = t[1]*3600 + t[2]*60 + t[3];
        if (sec - last_stamp >= 300) {
          printf "\n[%02d:%02d:%02d]\n", t[1], t[2], t[3];
          last_stamp = sec;
        }
        next;
      }
      !seen[$0]++' > "$out_txt"
else
  # English: no transliteration
  sed -E 's/<[^>]*>//g; s/&nbsp;/ /g; /^[[:space:]]*$/d' "$vtt_file" \
  | awk '
      BEGIN { last_stamp = 0 }
      /^[0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]{3}/ {
        split($1, t, /[:.]/);
        sec = t[1]*3600 + t[2]*60 + t[3];
        if (sec - last_stamp >= 300) {
          printf "\n[%02d:%02d:%02d]\n", t[1], t[2], t[3];
          last_stamp = sec;
        }
        next;
      }
      !seen[$0]++' > "$out_txt"
fi

# Move the processed transcript to the target folder
mv -f "$out_txt" "$target_dir/"

# Trigger media scan (no-op on Ubuntu)
media_scan "$target_dir/$out_txt" >/dev/null 2>&1 || true

echo "✅ Saved: $target_dir/$out_txt"