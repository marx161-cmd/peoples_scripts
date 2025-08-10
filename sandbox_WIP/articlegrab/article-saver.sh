#!/bin/bash
# Save to: ~/article-saver.sh

OUTPUT_DIR="/storage/emulated/0/Documents/web_articles"
TEMP_FILE="$HOME/article_temp.txt"

if [ -z "$1" ]; then
    echo "Usage: bash article-saver.sh <URL>"
    exit 1
fi

# Generate filename from title or timestamp
get_filename() {
    local title=$(curl -sL "$1" | grep -oP '(?<=<title>)[^<]*(?=</title>)' | head -1)
    if [ -z "$title" ]; then
        date +"article_%Y%m%d-%H%M%S.txt"
    else
        echo "$title" | tr -cd '[:alnum:] ._-' | tr ' ' '_' | tr -s '_' | sed 's/_$//' | head -c 50
        echo ".txt"
    fi
}

OUTPUT_FILE="$OUTPUT_DIR/$(get_filename "$1")"

# Clean text function
clean_text() {
    local file="$1"
    # Remove Lynx artifacts
    sed -i 's/(BUTTON)//g; s/(IMAGE)//g; s/____________________//g' "$file"
    # Fix common encoding issues
    sed -i "s/æ/ae/g; s/Æ/AE/g; s/ø/o/g; s/Ø/O/g; s/å/a/g; s/Å/A/g" "$file"
    # Remove extra blank lines
    sed -i '/^[[:space:]]*$/d' "$file"
}

# Method 1: Readability-cli + Pandoc
if command -v readability-cli &>/dev/null && command -v pandoc &>/dev/null; then
    if curl -sL "$1" | readability-cli 2>/dev/null > "$TEMP_FILE"; then
        pandoc "$TEMP_FILE" -t plain -o "$OUTPUT_FILE" 2>/dev/null
        if [ -s "$OUTPUT_FILE" ]; then
            rm "$TEMP_FILE"
            clean_text "$OUTPUT_FILE"
            echo "Saved using Readability+Pandoc: $(basename "$OUTPUT_FILE")"
            termux-media-scan "$OUTPUT_FILE" 2>/dev/null
            exit 0
        fi
    fi
fi

# Method 2: Lynx
if command -v lynx &>/dev/null; then
    lynx --dump --nolist "$1" 2>/dev/null > "$OUTPUT_FILE"
    if [ -s "$OUTPUT_FILE" ]; then
        clean_text "$OUTPUT_FILE"
        echo "Saved using Lynx: $(basename "$OUTPUT_FILE")"
        termux-media-scan "$OUTPUT_FILE" 2>/dev/null
        exit 0
    fi
fi

# Method 3: Pandoc fallback
if command -v pandoc &>/dev/null; then
    curl -sL "$1" | pandoc -f html -t plain -o "$OUTPUT_FILE" 2>/dev/null
    if [ -s "$OUTPUT_FILE" ]; then
        clean_text "$OUTPUT_FILE"
        echo "Saved using raw Pandoc: $(basename "$OUTPUT_FILE")"
        termux-media-scan "$OUTPUT_FILE" 2>/dev/null
        exit 0
    fi
fi

# Method 4: Basic text extraction
curl -sL "$1" | sed -e 's/<[^>]*>//g' > "$OUTPUT_FILE"
if [ -s "$OUTPUT_FILE" ]; then
    clean_text "$OUTPUT_FILE"
    echo "Partial success! Saved basic text: $(basename "$OUTPUT_FILE")"
    termux-media-scan "$OUTPUT_FILE" 2>/dev/null
    exit 0
fi

# All methods failed
echo "Error: Failed to extract article text" >&2
rm -f "$OUTPUT_FILE" "$TEMP_FILE" 2>/dev/null
exit 
