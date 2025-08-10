#!/usr/bin/env bash
set -euo pipefail
source "$HOME/.scripts/common.sh"

echo "Platform: $(is_termux && echo Termux || echo Ubuntu/Linux)"
echo "Documents: $(documents_dir)"
echo "Pictures:  $(pictures_dir)"
echo "Music:     $(music_dir)"
echo "Videos:    $(videos_dir)"
echo "Downloads: $(downloads_dir)"

echo -n "Clipboard test: "
if txt="$(clipboard_get 2>/dev/null)"; then
  # Show up to 120 chars to avoid dumping huge stuff
  echo "OK -> ${txt:0:120}"
else
  echo "No clipboard provider found."
fi