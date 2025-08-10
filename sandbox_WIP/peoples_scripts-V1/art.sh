#!/usr/bin/env bash
set -euo pipefail

# Article saver: extracts readable article text from a URL (or clipboard) and saves it to Documents/web_articles
# Portable across Termux and Ubuntu thanks to common.sh helpers

# Load common helpers
if [[ -f "$HOME/.scripts/common.sh" ]]; then
  # shellcheck disable=SC1091
  source "$HOME/.scripts/common.sh"
else
  echo "❌ Missing helper: ~/.scripts/common.sh   (Run: bash setup.sh)" >&2
  exit 1
fi

# Usage message
usage() {
  echo "Usage: art.sh [URL] (or from clipboard)"
}

# Get URL from arg or clipboard
url="${1:-}"
if [[ -z "$url" ]]; then
  url="$(clipboard_get 2>/dev/null || true)"
fi
if [[ -z "$url" ]]; then
  usage
  exit 1
fi

# Determine output directory
out_dir="$(documents_dir)/web_articles"
ensure_dir "$out_dir"

# Derive a base filename from the page title or fallback timestamp
page_title="$(curl -sL "$url" | grep -oP '(?<=<title>)[^<]+' | head -1 || true)"
base="${page_title:-"article_$(date +%Y%m%d-%H%M%S)"}"
file="$out_dir/$(sanitize_filename "$base").txt"
tmp="$(mktemp)"

# Helper to clean up the extracted article
clean_text() {
  # Remove button/image placeholders and consecutive underscores
  sed -i 's/(BUTTON)//g; s/(IMAGE)//g; s/____________________//g' "$file"
  # Remove blank lines
  sed -i '/^[[:space:]]*$/d' "$file"
}

success=false

# Extraction method 1: readability-cli + pandoc
if command -v readability-cli >/dev/null 2>&1 && command -v pandoc >/dev/null 2>&1; then
  if curl -sL "$url" | readability-cli > "$tmp" 2>/dev/null; then
    if pandoc "$tmp" -t plain -o "$file" 2>/dev/null; then
      rm -f "$tmp"
      clean_text
      echo "Saved (Readability+Pandoc): $(basename "$file")"
      success=true
    fi
  fi
fi

# Extraction method 2: lynx
if [[ $success == false ]] && command -v lynx >/dev/null 2>&1; then
  if lynx --dump --nolist "$url" > "$file" 2>/dev/null && [[ -s "$file" ]]; then
    clean_text
    echo "Saved (Lynx): $(basename "$file")"
    success=true
  fi
fi

# Extraction method 3: pandoc directly
if [[ $success == false ]] && command -v pandoc >/dev/null 2>&1; then
  if curl -sL "$url" | pandoc -f html -t plain -o "$file" 2>/dev/null && [[ -s "$file" ]]; then
    clean_text
    echo "Saved (Pandoc): $(basename "$file")"
    success=true
  fi
fi

# Extraction method 4: naive strip
if [[ $success == false ]]; then
  if curl -sL "$url" | sed -e 's/<[^>]*>//g' > "$file" && [[ -s "$file" ]]; then
    clean_text
    echo "Saved (Basic): $(basename "$file")"
    success=true
  fi
fi

# If any method succeeded, trigger media scan and exit
if [[ $success == true ]]; then
  media_scan "$file" 2>/dev/null || true
  exit 0
fi

# Otherwise, report failure
echo "❌ Failed to extract article text." >&2
rm -f "$file" "$tmp" 2>/dev/null || true
exit 1