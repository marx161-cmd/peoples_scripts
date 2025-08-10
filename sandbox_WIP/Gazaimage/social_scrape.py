#!/usr/bin/env python3
"""
social_scrape.py — JS feed grabber (X/Bluesky) for Gaza imagery (v2)
- Reads feeds from feeds.csv (name,url)
- Uses Playwright to render and scrape recent <img> CDN URLs
- Avoids double-download by calling utils.save_image_url once
"""
import os, csv, time
from urllib.parse import urlparse
from playwright.sync_api import sync_playwright

from utils import save_image_url

BASE_DIR = os.path.dirname(__file__)
FEEDS_FILE = os.path.join(BASE_DIR, "feeds.csv")

def grab_feed_images(url: str, max_images: int = 15):
    imgs = []
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        page = browser.new_page()
        try:
            page.goto(url, wait_until="networkidle", timeout=60000)
            # light scroll to load more
            page.mouse.wheel(0, 2000)
            page.wait_for_timeout(1500)
        except Exception as e:
            print(f"[!] Timeout loading {url}: {e}")
            browser.close()
            return imgs
        # Collect visible <img> tags that look like media
        handles = page.locator("img").element_handles()
        for h in handles:
            src = h.get_attribute("src") or ""
            if not src:
                continue
            if any(s in src for s in ["pbs.twimg.com/media", ".cdn.bsky.app/img/", "/media/"]):
                imgs.append(src)
                if len(imgs) >= max_images:
                    break
        browser.close()
    return imgs

def main():
    if not os.path.exists(FEEDS_FILE):
        print(f"[!] feeds.csv not found at {FEEDS_FILE}")
        return
    with open(FEEDS_FILE, "r", encoding="utf-8") as f:
        r = csv.reader(f)
        for row in r:
            if not row or row[0].startswith("#"):
                continue
            name, url = (row + [""])[:2]
            if not url:
                continue
            print(f"=== Scanning {name or url} …")
            try:
                for img_url in grab_feed_images(url, max_images=15):
                    save_image_url(img_url, referrer=url)
            except Exception as exc:
                print(f"[!] {name} error: {exc}")

if __name__ == "__main__":
    main()
