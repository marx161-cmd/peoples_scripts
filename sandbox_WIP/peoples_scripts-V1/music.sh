#!/usr/bin/env bash
set -euo pipefail

# Music downloader: supports albums, playlists, and single tracks.
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
  echo "Usage: music.sh <URL>"
}

url="${1:-}"
if [[ -z "$url" ]]; then
  usage
  exit 1
fi

# Determine base output directory
base="$(music_dir)"
ensure_dir "$base"

# Template: choose playlist_title; fallback to playlist (index), then uploader, then uploader_id
tpl="$base/%(playlist_title,playlist,uploader,uploader_id)s/%(title)s.%(ext)s"

yt-dlp \
  -f "bestaudio" \
  -x --audio-format mp3 --audio-quality 0 \
  --embed-thumbnail --convert-thumbnails jpg \
  -o "$tpl" "$url"

# Scan the whole base directory for new files (Termux only; no-op on Ubuntu)
media_scan "$base" >/dev/null 2>&1 || true

echo "✅ Saved under: $base"