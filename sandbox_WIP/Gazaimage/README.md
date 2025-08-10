# Gaza High‑Res Imagery Scraper — Setup Guide (v2)

**Goal:** Run two lightweight Python bots every night on Ubuntu to automatically download any new high‑resolution (Maxar / Planet / SkySat) satellite images or annotated damage maps of Gaza published on curated websites and on key OSINT social‑media feeds.  
This v2 implements bandwidth‑savers and reliability upgrades from your first draft.

---

## 1) One‑time system setup

```bash
sudo apt update
sudo apt install -y python3 python3-venv python3-pip git poppler-utils exiftool \
  libnss3 libatk-bridge2.0-0 libxss1 libgbm1
```

> `poppler-utils` provides `pdfimages` for PDF extraction. The extra libs are for Playwright's headless Chromium.

Create project + venv:
```bash
mkdir -p ~/gaza_scraper && cd ~/gaza_scraper
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install requests beautifulsoup4 python-dateutil playwright
playwright install chromium
```

Download the v2 files (place all files into `~/gaza_scraper/`):
- `utils.py`  (shared DB + save logic; HEAD/ETag skip; PDF ingest; provider tagging)
- `crawler.py` (curated websites)
- `social_scrape.py` (X/Bluesky)
- `seeds.txt` (edit without touching code)
- `feeds.csv` (name,url)


> **Output dir:** defaults to `/home/comrade/Pictures/scraper`.  
> You can override via env: `export GAZA_SCRAPER_DIR=/path/to/dir` before running.

---

## 2) Configure targets

Edit these two files as needed:

- `seeds.txt` — one seed URL per line; `#` for comments.
- `feeds.csv` — CSV with header `name,url`. One feed per line.

You can paste more Amnesty/HRW/UNOSAT links and relevant OSINT hubs here.

---

## 3) What changed vs v1 (why this is smoother)

- **No more double‑download** from social scraper — it calls a single `save_image_url()`.
- **HEAD/ETag/Last‑Modified skip:** if an image URL is unchanged, we **skip** downloading.
- **PDF images go into the DB** too — unified dedupe/history and provider tag `pdf`.
- **Provider tagging** (`Maxar`, `Planet`, `SkySat`, `UNOSAT`, etc.) recorded per image.
- **Externalized targets** (`seeds.txt`, `feeds.csv`) so you don’t edit code to add sources.
- **Polite pacing per domain** + shallow same‑domain crawl with a sensible cap.

---

## 4) Quick test (manual)

Inside your venv:
```bash
cd ~/gaza_scraper
source venv/bin/activate
python crawler.py
python social_scrape.py
```

You should see lines like: `[+] Saved https://… as 1a2b3c4d_filename.jpg [Maxar]`  
Images will appear in `/home/comrade/Pictures/scraper/` (or your overridden dir).

---

## 5) Nightly automation (cron)

Open your crontab:
```bash
crontab -e
```

Add (adjust paths if you changed them):
```
0 3 * * *  cd /home/comrade/gaza_scraper && /home/comrade/gaza_scraper/venv/bin/python crawler.py       >> /home/comrade/gaza_scraper/scrape.log 2>&1
15 3 * * * cd /home/comrade/gaza_scraper && /home/comrade/gaza_scraper/venv/bin/python social_scrape.py >> /home/comrade/gaza_scraper/social.log 2>&1
```

- **03:00** — curated site crawl (PDF extraction enabled)
- **03:15** — socials (gives X/Bluesky a few minutes for late drops)

Logs accumulate in `~/gaza_scraper/`.

---

## 6) Optional tweaks (drop‑in simple)

- **Telegram alerts:** add a few lines in `utils.save_image_from_bytes()` to `bot.send_message` when a new provider match appears (e.g., `"Maxar" in prov`).
- **More seeds/feeds:** just edit `seeds.txt` / `feeds.csv` — no code changes.
- **Tune filters:** in `crawler.py` adjust `KEYWORDS` if you want to be looser/tighter.

---

## 7) Troubleshooting

**Playwright Chromium fails to start**  
Install the extra libs above; if still failing, run `playwright install chromium` again inside the venv.

**Cron doesn’t run**  
Use full paths (already in the example). Check `grep CRON /var/log/syslog` and the two log files for errors.

**Disk space**  
Raise `GAZA_MIN_BYTES` (env var) to filter small images, or prune older images:  
`find /home/comrade/Pictures/scraper -type f -mtime +90 -delete`

---

## 8) Intentional limitations

- This is a **curated** scraper; it won’t brute‑force entire domains.
- Social scraping is best‑effort (public pages only). If feeds go private/login‑gated, consider their APIs or RSS mirrors.

---

## 9) Files & structure (recap)

```
~/gaza_scraper/
├── venv/
├── crawler.py
├── social_scrape.py
├── utils.py
├── seeds.txt
└── feeds.csv
```

DB: `crawler.db` (auto‑created alongside scripts)  
Images: `/home/comrade/Pictures/scraper/` (default)

—
