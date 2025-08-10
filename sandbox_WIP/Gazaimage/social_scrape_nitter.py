# social_scrape_nitter.py
import os, requests
from utils import init_db, file_seen

SAVE_DIR = "/storage/emulated/0/Pictures/gaza_scraped"
FEEDS = [line.strip().lstrip("@") for line in open("feeds_x.txt") if line.strip() and not line.startswith("#")]
NITTER_BASES = ["https://nitter.net", "https://nitter.it", "https://nitter.moomoo.me"]
KEYWORDS = ["Gaza", "Palestine", "satellite", "drone", "aerial", "imagery", "IDF", "strike", "damage"]

def main():
    init_db()
    os.makedirs(SAVE_DIR, exist_ok=True)
    for feed in FEEDS:
        for base in NITTER_BASES:
            url = f"{base}/{feed}"
            try:
                r = requests.get(url)
                if any(k.lower() in r.text.lower() for k in KEYWORDS):
                    fname = os.path.join(SAVE_DIR, f"{feed}.html")
                    if not file_seen(url, r.content):
                        with open(fname, "wb") as f:
                            f.write(r.content)
                        print(f"Saved {fname}")
                break
            except Exception as e:
                print(f"Error fetching {url}: {e}")

if __name__ == "__main__":
    main()
