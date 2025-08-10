#!/data/data/com.termux/files/usr/bin/sh
# run_crawl.sh — Termux helper to run both crawlers with venv + Android storage path
set -e
cd ~/gaza_scraper
. venv/bin/activate
export GAZA_SCRAPER_DIR="/storage/emulated/0/Pictures/gaza_scraped"
# optional tuning:
# export GAZA_MIN_BYTES=80000
# export GAZA_RATE_LIMIT=2.0
python crawler.py
python social_scrape_termux.py
