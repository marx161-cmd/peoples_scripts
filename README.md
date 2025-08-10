# 📲 Termux Script Suite by Marx161-cmd

Tested on:
- Android 13 (Oppo Find X2 Pro)
- Termux v0.118.3
- All scripts working with various URLs

---

## 📦 Included Scripts

### 1. Article Saver (`article-saver.sh`)
Extract clean article text from any website URL

**Features:**
- Removes ads/menus
- Uses multiple extraction methods
- Outputs to Android Documents folder

**Usage:**
```bash
./article-saver.sh "https://www.example.com/article"
```

---

### 2. Transcript Downloaders

#### English Versions:
- `get-transcript-en.sh` - Manual URL input
- `get-transcripten.sh` - Auto-fetches URL from clipboard (requires Termux:API)

#### German Versions:
- `get-transcript-de.sh` - Manual URL input
- `get-transcriptde.sh` - Auto-fetches URL from clipboard (requires Termux:API)

**Features:**
- Downloads YouTube subtitles
- Cleans and formats transcripts
- Adds 5-minute timestamps
- Outputs to Documents/Transcripts

**Usage:**
```bash
# Manual version
./get-transcript-de.sh "https://youtu.be/VIDEO_ID"

# Clipboard version (copies URL from clipboard)
./get-transcripten.sh
```

---

## 🧰 Dependencies

Install these packages first:
```bash
pkg update
pkg install -y curl lynx pandoc termux-api dos2unix libiconv python
pip install readability-lxml yt-dlp
```

Don't forget to run:
```bash
termux-setup-storage
```

---

## 🔧 Setup Instructions

1. Clone this repository:
```bash
git clone https://github.com/yourusername/termux-scripts.git
cd termux-scripts
```

2. Make scripts executable:
```bash
chmod +x *.sh
```

3. Run the installer:
```bash
./install.sh
```

---

## ⚠️ Important Notes

- Clipboard scripts require the [Termux:API app](https://f-droid.org/packages/com.termux.api/)
- German scripts handle special characters and umlauts
- All files are saved in Termux shared storage locations

---

## 📃 License
MIT License - See [LICENSE.md](LICENSE.md)
