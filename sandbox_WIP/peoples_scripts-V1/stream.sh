#!/usr/bin/env bash
set -euo pipefail

# Livestream recorder: captures a livestream from the beginning and saves it to Videos (Movies on Termux)
# Uses portable directories via common.sh helpers.

# Load common helpers
if [[ -f "$HOME/.scripts/common.sh" ]]; then
  # shellcheck disable=SC1091
  source "$HOME/.scripts/common.sh"
else
  echo "❌ Missing helper: ~/.scripts/common.sh   (Run: bash setup.sh)" >&2
  exit 1
fi

usage() {
  echo "Usage: stream.sh <URL> [cookies.txt]"
}

if [[ $# -lt 1 ]]; then
  usage
  exit 1
fi

url="$1"
cookies="${2:-}"

# Determine output directory for videos
out_dir="$(videos_dir)"
ensure_dir "$out_dir"

# Optional cookies argument for authenticated streams
cookie_arg=()
if [[ -n "$cookies" ]]; then
  cookie_arg=(--cookies "$cookies")
fi

# Download livestream from start, merge into MP4
tmp_prefix="temp_video"
yt-dlp --live-from-start --no-live -f "bestvideo+bestaudio/best" \
  --merge-output-format mp4 \
  "${cookie_arg[@]}" \
  -o "$tmp_prefix.%(ext)s" "$url"

# Locate the output file produced by yt-dlp
final_file="$(find . -maxdepth 1 -type f -name "$tmp_prefix.*" -print -quit || true)"
if [[ -z "$final_file" ]]; then
  echo "❌ No output file found." >&2
  exit 1
fi

clean_title="$(sanitize_filename "$(basename "$final_file")")"
mv -f "$final_file" "$out_dir/$clean_title"

# Trigger media scan for the saved video
media_scan "$out_dir/$clean_title" >/dev/null 2>&1 || true

# Remove temporary parts if any
rm -f "$tmp_prefix".* *.part 2>/dev/null || true

echo "✅ Saved: $out_dir/$clean_title"