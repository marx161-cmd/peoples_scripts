#!/usr/bin/env python3
"""
social_scrape_termux.py — X/Twitter-only social scraper for Termux
- Avoids Playwright/Chromium.
- Uses snscrape to fetch latest media URLs from specified usernames.
- Saves via utils.save_image_url (dedupe + DB + provider tagging).
"""
import os, sys
from typing import List
from utils import save_image_url
try:
    import snscrape.modules.twitter as sntwitter
except Exception as e:
    print("[!] snscrape not installed. Install with: pip install snscrape")
    sys.exit(1)

BASE_DIR = os.path.dirname(__file__)
FEEDS_FILE = os.path.join(BASE_DIR, "feeds_x.txt")

MAX_TWEETS_PER_USER = int(os.environ.get("GAZA_MAX_TWEETS", "40"))
MAX_IMAGES_PER_USER = int(os.environ.get("GAZA_MAX_IMAGES", "15"))

def load_users(path: str) -> List[str]:
    users = []
    if not os.path.exists(path):
        return users
    with open(path, "r", encoding="utf-8") as f:
        for ln in f:
            ln = ln.strip()
            if not ln or ln.startswith("#"):
                continue
            users.append(ln.lstrip("@"))
    return users

def main():
    users = load_users(FEEDS_FILE)
    if not users:
        print(f"[!] No users found in {FEEDS_FILE}. Add one handle per line (e.g., obretix).")
        return

    for user in users:
        print(f"=== Scanning @{user} …")
        images_seen = 0
        try:
            scraper = sntwitter.TwitterUserScraper(user)
            for i, tweet in enumerate(scraper.get_items()):
                if i >= MAX_TWEETS_PER_USER or images_seen >= MAX_IMAGES_PER_USER:
                    break
                media = getattr(tweet, "media", None)
                if not media:
                    continue
                # Permalink (referrer)
                ref = f"https://x.com/{user}/status/{tweet.id}"
                for m in media:
                    # Photos only; GIF/video skipped for now
                    if isinstance(m, sntwitter.Photo):
                        url = getattr(m, "fullUrl", None) or getattr(m, "url", None)
                        if url:
                            save_image_url(url, referrer=ref)
                            images_seen += 1
                            if images_seen >= MAX_IMAGES_PER_USER:
                                break
        except Exception as exc:
            print(f"[!] @{user} error: {exc}")

if __name__ == "__main__":
    main()
