#!/usr/bin/env bash
set -euo pipefail

# Wrapper around aria2c for big downloads; saves to Downloads/aria2c using portable helpers

# Load common helpers
if [[ -f "$HOME/.scripts/common.sh" ]]; then
  # shellcheck disable=SC1091
  source "$HOME/.scripts/common.sh"
else
  echo "❌ Missing helper: ~/.scripts/common.sh   (Run: bash setup.sh)" >&2
  exit 1
fi

usage() {
  echo "Usage: dl.sh <URL1> [URL2 ...]"
}

if [[ $# -lt 1 ]]; then
  usage
  exit 1
fi

# Determine download base directory
base="$(downloads_dir)/aria2c"
ensure_dir "$base"

aria2c --continue=true --max-connection-per-server=16 --split=16 \
  --dir="$base" --auto-file-renaming=true --check-integrity=true "$@"

# Trigger media scan on base directory
media_scan "$base" >/dev/null 2>&1 || true

echo "✅ Downloads in: $base"