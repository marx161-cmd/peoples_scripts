# Gaza Scraper — Termux guide (v2, no Playwright)

This variant runs on Android via Termux with **no Chromium/Playwright**.  
It includes:
- `crawler.py` (curated websites + PDF extraction)
- `social_scrape_termux.py` (X/Twitter via snscrape)
- `utils.py` (DB + dedupe + provider tags)
- `seeds.txt`, `feeds_x.txt`
- `run_crawl.sh` helper

Images save to `/storage/emulated/0/Pictures/gaza_scraped` (changeable).

---

## 0) Grant storage & disable battery optimizations
In Termux:
```bash
termux-setup-storage
```
Android Settings → Apps → Termux → Battery → **Unrestricted** (or exclude from battery optimization).

---

## 1) Packages

```bash
pkg update && pkg upgrade
pkg install python git poppler exiftool cronie
```

- `poppler` provides `pdfimages` for PDF extraction.
- `cronie` lets you use cron on Android (we'll run it via Termux:Boot).

## 2) Project & venv
```bash
mkdir -p ~/gaza_scraper && cd ~/gaza_scraper
python -m venv venv
. venv/bin/activate
pip install --upgrade pip
pip install requests beautifulsoup4 python-dateutil snscrape
```

Copy these files into `~/gaza_scraper/`:
- `utils.py`, `crawler.py`, `social_scrape_termux.py`, `seeds.txt`, `feeds_x.txt`, `run_crawl.sh`

Make scripts executable:
```bash
chmod +x run_crawl.sh social_scrape_termux.py
```

## 3) Set the Android output folder
Add to your `~/.bashrc` (or export before each run):
```bash
echo 'export GAZA_SCRAPER_DIR=/storage/emulated/0/Pictures/gaza_scraped' >> ~/.bashrc
```

## 4) Quick test
```bash
. venv/bin/activate
python crawler.py
python social_scrape_termux.py
```
You should see `[+] Saved …` lines and files in `/storage/emulated/0/Pictures/gaza_scraped`.

## 5) Nightly schedule options

### Option A — Cron + Termux:Boot (reliable, no Play Store needed)
1. Install **Termux:Boot** (F-Droid). Open it once so it can register.
2. Create the boot script so `crond` starts automatically:
```
mkdir -p ~/.termux/boot
cat > ~/.termux/boot/01-start-cron.sh <<'EOF'
#!/data/data/com.termux/files/usr/bin/sh
termux-wake-lock
crond
EOF
chmod +x ~/.termux/boot/01-start-cron.sh
```
3. Create cron entries:
```
crontab -e
```
Add (adjust time if you want):
```
0 3 * * *  cd /data/data/com.termux/files/home/gaza_scraper && /data/data/com.termux/files/home/gaza_scraper/venv/bin/python crawler.py       >> /data/data/com.termux/files/home/gaza_scraper/scrape.log 2>&1
15 3 * * * cd /data/data/com.termux/files/home/gaza_scraper && /data/data/com.termux/files/home/gaza_scraper/venv/bin/python social_scrape_termux.py >> /data/data/com.termux/files/home/gaza_scraper/social.log 2>&1
```
4. Reboot phone once to verify Termux:Boot starts `crond`. Check logs after 03:30.

> Tip: Keep Termux exempt from battery optimization; otherwise Android may kill `crond`.

### Option B — Manual or Widget
Run from the Termux widget or a homescreen shortcut:
```
~/gaza_scraper/run_crawl.sh
```

---

## Notes & limits
- X rate limits can fluctuate; `snscrape` is best-effort but generally works without API keys.
- Bluesky isn’t included here to avoid credentials and JS rendering. If you want it, I can add an **atproto**-based scraper (needs a Bluesky app password).
- PDF images are stored & deduped in the same DB as web images.
- You can tune sizes or rate limits via env vars: `GAZA_MIN_BYTES`, `GAZA_RATE_LIMIT`.

—
