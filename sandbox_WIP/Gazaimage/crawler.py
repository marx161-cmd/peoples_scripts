#!/usr/bin/env python3
"""
crawler.py — curated domain scraper for Gaza High‑Res Imagery (v2)
- Reads seed URLs from seeds.txt
- Extracts inline <img> > MIN_IMAGE_BYTES and images from linked PDFs
- Same-domain shallow crawl (depth=1) with polite pacing
"""
import os, time, re
from urllib.parse import urljoin, urlparse
import requests
from bs4 import BeautifulSoup

from utils import (HEADERS, RATE_LIMIT_SECONDS, is_new_url, mark_url_seen,
                   save_image_url, extract_images_from_pdf)

BASE_DIR = os.path.dirname(__file__)
SEEDS_FILE = os.path.join(BASE_DIR, "seeds.txt")

KEYWORDS = re.compile(r"(maxar|skysat|planet|unosat|satellite|gaza|damage|before[- ]after|2023|2024|2025)", re.I)
MAX_LINKS_PER_PAGE = 25

_last_request = {}  # domain -> last ts

def _pause_for_domain(url: str):
    dom = urlparse(url).netloc
    last = _last_request.get(dom, 0)
    wait = RATE_LIMIT_SECONDS - (time.time() - last)
    if wait > 0:
        time.sleep(wait)
    _last_request[dom] = time.time()

def _get(url: str, timeout=20):
    _pause_for_domain(url)
    return requests.get(url, headers=HEADERS, timeout=timeout)

def process_pdf(pdf_url: str, referrer: str):
    try:
        r = _get(pdf_url, timeout=60)
        if r.status_code == 200 and r.content and len(r.content) > 1024:
            count = extract_images_from_pdf(r.content, referrer=referrer)
            if count:
                print(f"[+] Extracted {count} images from PDF: {pdf_url}")
    except Exception as e:
        print(f"[!] PDF fetch failed {pdf_url}: {e}")

def crawl_page(url: str, depth: int = 1):
    try:
        r = _get(url, timeout=30)
        status = r.status_code
        if status != 200:
            mark_url_seen(url, status=status, error=f"HTTP {status}")
            return
        soup = BeautifulSoup(r.text, "html.parser")

        # 1) Inline images
        seen = set()
        for img in soup.find_all("img"):
            src = img.get("src") or ""
            if not src:
                continue
            full = urljoin(url, src)
            if full in seen:
                continue
            seen.add(full)
            # crude keyword filter to prefer satellite crops
            if KEYWORDS.search(full) or KEYWORDS.search(img.get("alt") or ""):
                save_image_url(full, referrer=url)

        # 2) Linked PDFs (damage assessments often embed crops)
        for a in soup.find_all("a", href=True):
            href = a["href"]
            if href.lower().endswith(".pdf"):
                pdf_url = urljoin(url, href)
                process_pdf(pdf_url, referrer=url)

        # 3) Shallow same-domain crawl
        if depth > 0:
            domain = urlparse(url).netloc
            links = []
            for a in soup.find_all("a", href=True):
                link = urljoin(url, a["href"])
                if urlparse(link).netloc == domain and link.startswith("http"):
                    links.append(link)
            # de-dup and cap
            nxt = []
            seenl = set()
            for l in links:
                if l not in seenl and len(nxt) < MAX_LINKS_PER_PAGE:
                    seenl.add(l)
                    nxt.append(l)
            for link in nxt:
                crawl_page(link, depth=depth-1)

        mark_url_seen(url, status=200)
    except Exception as e:
        mark_url_seen(url, status=599, error=str(e))
        print(f"[!] Crawl error {url}: {e}")

def main():
    if not os.path.exists(SEEDS_FILE):
        print(f"[!] seeds.txt not found at {SEEDS_FILE}")
        return
    with open(SEEDS_FILE, "r", encoding="utf-8") as f:
        seeds = [ln.strip() for ln in f if ln.strip() and not ln.strip().startswith("#")]
    for seed in seeds:
        crawl_page(seed, depth=1)

if __name__ == "__main__":
    main()
