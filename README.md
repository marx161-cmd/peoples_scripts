# 📲 peoples_scripts

Cross‑platform Bash helpers that work on **Termux (Android)** and **Ubuntu/Linux**.  
All scripts auto‑detect the platform and write to the correct user folders via a shared helper: `~/.scripts/common.sh`.

Tested on:
- Android 13 (Termux v0.118+)
- Ubuntu 22.04+
- Works with YouTube, general webpages, livestreams, and large downloads

---

## 📦 Included scripts

### `trans.sh`
Download **auto‑generated subtitles** from a video and save a clean transcript.
- Language: `-l en` (default) or `-l de`
- URL arg or **clipboard** fallback
- 5‑minute timestamps
- De‑only transliteration (iconv `//TRANSLIT`)
- De‑dupes repeated lines  
**Saves to:** `Documents/Transcripts/<title>.txt`

**Usage**

```bash
trans.sh -l en "https://youtu.be/VIDEO"
# or
trans.sh -l de        # uses clipboard if URL omitted

> Termux Widget wrappers (optional):
Put these tiny wrappers in ~/.shortcuts to get EN/DE buttons:

# trans-e.sh
#!/usr/bin/env bash
exec "$HOME/scripts/trans.sh" -l en "$@"

# trans-d.sh
#!/usr/bin/env bash
exec "$HOME/scripts/trans.sh" -l de "$@"

Then chmod +x ~/.shortcuts/trans-*.sh.
---

art.sh

Extracts readable article text (Readability → Pandoc → Lynx → basic strip fallback).
Saves to: Documents/web_articles/<title>.txt

Usage

art.sh "https://example.com/article"
# or: art.sh  (uses clipboard if URL omitted)


---

music.sh

Downloads albums/playlists/tracks via yt-dlp, converts to MP3, embeds thumbnail.
Saves to: Music/<playlist|uploader>/<title>.mp3

Usage

music.sh "https://www.youtube.com/playlist?list=..."


---

stream.sh

Record livestreams (e.g., YouTube) to MP4.
Saves to: Videos (Ubuntu) or Movies (Termux/Android)

Usage

stream.sh "https://www.youtube.com/watch?v=LIVE_ID"


---

dl.sh

Aria2c wrapper for big downloads with sane defaults.
Saves to: Downloads/aria2c/

Usage

dl.sh "https://big.example/file.iso" "https://mirror/file.iso"


---

🧰 Dependencies

You don’t have to install them manually—setup.sh handles it.
It installs per‑platform packages and drops the shared helper at ~/.scripts/common.sh.

Termux (Android)

python-yt-dlp, ffmpeg, aria2, lynx, pandoc, nodejs, termux-api, jq

(optional) readability-cli via npm (installed only if npm present)


Ubuntu

yt-dlp, ffmpeg, aria2, lynx, pandoc, xdg-user-dirs, xclip, wl-clipboard, nodejs, npm, jq

readability-cli via npm



---

🚀 Install

git clone https://github.com/marx161-cmd/peoples_scripts.git
cd peoples_scripts

# Make scripts runnable
chmod +x *.sh

# Run setup (installs deps + ~/.scripts/common.sh)
./setup.sh

# (Optional QoL) Add ~/scripts to PATH so you can run scripts from anywhere
mkdir -p ~/scripts
cp -f trans.sh art.sh music.sh stream.sh dl.sh ~/scripts/
if ! grep -q 'export PATH="$HOME/scripts:$PATH"' ~/.bashrc 2>/dev/null; then
  echo 'export PATH="$HOME/scripts:$PATH"' >> ~/.bashrc
  source ~/.bashrc
fi

Termux storage bridge (first time only):

termux-setup-storage


---

🧪 Quick tests

# Verify helper + paths + clipboard
bash test-common.sh

# Transcript (clipboard fallback)
trans.sh -l en
# Article saver
art.sh "https://en.wikipedia.org/wiki/Bash_(Unix_shell)"
# Music
music.sh "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
# Livestream (when live)
stream.sh "https://www.youtube.com/watch?v=LIVE_ID"
# Big download
dl.sh "https://speed.hetzner.de/1GB.bin"


---

📂 Where files go (auto‑detected)

Documents: ~/Documents (Ubuntu) or ~/storage/shared/Documents (Termux)

Pictures:  ~/Pictures or ~/storage/shared/Pictures

Music:     ~/Music or ~/storage/shared/Music

Videos:    ~/Videos or ~/storage/shared/Movies

Downloads: ~/Downloads or ~/storage/shared/Download


All paths come from ~/.scripts/common.sh and must not be hardcoded.


---

⚠️ Notes

Clipboard on Termux requires the Termux:API app.

On Wayland/X11 (Ubuntu), clipboard uses wl-paste → xclip → xsel fallback.

termux-setup-storage may “rebuild links”—it never deletes your real files.



---

📜 License

MIT
