#!/data/data/com.termux/files/usr/bin/bash
export GAZA_SCRAPER_DIR="/storage/emulated/0/Pictures/gaza_scraped"
source venv/bin/activate
python crawler.py
python social_scrape_nitter.py
