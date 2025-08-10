#!/usr/bin/env python3
"""
utils.py — shared helpers for Gaza High‑Res Imagery Scraper (v2)
- Centralizes DB, dedupe, save, and metadata logic.
- Adds HEAD-based skip via ETag/Last-Modified tracking.
- Adds provider tagging and PDF image ingestion.
"""
import os, sqlite3, time, hashlib, mimetypes, tempfile, subprocess, glob
from urllib.parse import urlparse
import requests

# -------- Config (override via env if desired) --------
DOWNLOAD_DIR = os.environ.get("GAZA_SCRAPER_DIR", "/home/comrade/Pictures/scraper")
DB_PATH = os.environ.get("GAZA_SCRAPER_DB", os.path.join(os.path.dirname(__file__), "crawler.db"))
HEADERS = {"User-Agent": os.environ.get("GAZA_SCRAPER_UA", "Mozilla/5.0 (compatible; GazaImageBot/2.0; +contact@example.com)")}
MIN_IMAGE_BYTES = int(os.environ.get("GAZA_MIN_BYTES", "80000"))  # ~80 KB default
RATE_LIMIT_SECONDS = float(os.environ.get("GAZA_RATE_LIMIT", "2.0"))

os.makedirs(DOWNLOAD_DIR, exist_ok=True)

# -------- DB setup --------
_conn = sqlite3.connect(DB_PATH)
_cur = _conn.cursor()
_cur.execute("""CREATE TABLE IF NOT EXISTS seen_urls(
    url TEXT PRIMARY KEY,
    last_seen INTEGER,
    last_status INTEGER,
    error TEXT
)""")
_cur.execute("""CREATE TABLE IF NOT EXISTS images(
    hash TEXT PRIMARY KEY,
    filename TEXT,
    image_url TEXT,
    source_url TEXT,
    provider TEXT,
    downloaded INTEGER,
    created_at INTEGER
)""")
_cur.execute("""CREATE TABLE IF NOT EXISTS resources(
    url TEXT PRIMARY KEY,
    etag TEXT,
    last_modified TEXT,
    content_length INTEGER,
    last_checked INTEGER
)""")
# best-effort schema upgrade if older DB exists
try:
    _cur.execute("ALTER TABLE images ADD COLUMN image_url TEXT")
except sqlite3.OperationalError:
    pass
try:
    _cur.execute("ALTER TABLE images ADD COLUMN provider TEXT")
except sqlite3.OperationalError:
    pass
try:
    _cur.execute("ALTER TABLE images ADD COLUMN created_at INTEGER")
except sqlite3.OperationalError:
    pass
_conn.commit()

def now_i():
    return int(time.time())

def hash_bytes(b: bytes) -> str:
    return hashlib.sha256(b).hexdigest()

def is_new_url(url: str) -> bool:
    _cur.execute("SELECT 1 FROM seen_urls WHERE url=?", (url,))
    return _cur.fetchone() is None

def mark_url_seen(url: str, status: int = 200, error: str = None):
    _cur.execute("INSERT OR REPLACE INTO seen_urls(url, last_seen, last_status, error) VALUES (?,?,?,?)",
                 (url, now_i(), status, error))
    _conn.commit()

def image_already_saved(h: str) -> bool:
    _cur.execute("SELECT 1 FROM images WHERE hash=?", (h,))
    return _cur.fetchone() is not None

def record_resource_head(url: str, etag: str, last_mod: str, length: int):
    _cur.execute("INSERT OR REPLACE INTO resources(url, etag, last_modified, content_length, last_checked) VALUES (?,?,?,?,?)",
                 (url, etag, last_mod, length if length is not None else None, now_i()))
    _conn.commit()

def get_resource_head(url: str):
    _cur.execute("SELECT etag, last_modified, content_length FROM resources WHERE url=?", (url,))
    row = _cur.fetchone()
    return row if row else (None, None, None)

def sanitize_filename(name: str) -> str:
    keep = "._-()[]{}"
    safe = "".join(ch if ch.isalnum() or ch in keep else "_" for ch in name)
    return safe[:200] if len(safe) > 200 else safe

def detect_ext_from_content_type(ct: str) -> str:
    if not ct:
        return ""
    ext = mimetypes.guess_extension(ct.split(";")[0].strip())
    return ext or ""

def provider_from(referrer: str, img_url: str = "") -> str:
    s = f"{referrer} {img_url}".lower()
    if "maxar" in s:
        return "Maxar"
    if "planet" in s:
        return "Planet"
    if "skysat" in s:
        return "SkySat"
    if "unosat" in s:
        return "UNOSAT"
    if "forensic-architecture" in s:
        return "ForensicArchitecture"
    if "amnesty" in s:
        return "Amnesty"
    if "bellingcat" in s:
        return "Bellingcat"
    if "aljazeera" in s:
        return "AlJazeera"
    return "web"

def save_image_from_bytes(content: bytes, image_url: str, referrer: str, suggested_name: str = None, provider: str = None):
    if not content or len(content) < MIN_IMAGE_BYTES:
        return None
    h = hash_bytes(content)
    if image_already_saved(h):
        return None
    # filename
    base = suggested_name or os.path.basename(urlparse(image_url).path) or "unnamed"
    base = sanitize_filename(base)
    # add extension if missing
    if "." not in os.path.basename(base):
        # best-effort: derive from URL or leave without ext
        pass
    fname = f"{h[:8]}_{base}"
    path = os.path.join(DOWNLOAD_DIR, fname)
    with open(path, "wb") as f:
        f.write(content)
    prov = provider or provider_from(referrer, image_url)
    _cur.execute("""INSERT OR REPLACE INTO images(hash, filename, image_url, source_url, provider, downloaded, created_at)
                    VALUES (?,?,?,?,?,?,?)""",
                 (h, fname, image_url, referrer, prov, 1, now_i()))
    _conn.commit()
    print(f"[+] Saved {image_url} as {fname} [{prov}]")
    return path

def save_image_url(img_url: str, referrer: str):
    """Download using HEAD->(optional skip)->GET, then save+dedupe."""
    try:
        hr = requests.head(img_url, headers=HEADERS, timeout=15, allow_redirects=True)
        if hr.status_code != 200:
            return
        ct = hr.headers.get("Content-Type", "") or ""
        if "image" not in ct.lower() and not any(k in img_url.lower() for k in (".jpg", ".jpeg", ".png", ".tif", ".tiff", ".webp")):
            return
        size = hr.headers.get("Content-Length")
        etag = hr.headers.get("ETag")
        last_mod = hr.headers.get("Last-Modified")
        # HEAD skip if unchanged
        prev_etag, prev_lm, prev_len = get_resource_head(img_url)
        if etag and last_mod and prev_etag == etag and prev_lm == last_mod:
            # unchanged since last time; skip fetching
            record_resource_head(img_url, etag, last_mod, int(size) if size else None)
            return
        gr = requests.get(img_url, headers=HEADERS, timeout=30)
        if gr.status_code != 200:
            return
        # choose reasonable extension if missing
        ext = detect_ext_from_content_type(ct)
        suggested = os.path.basename(urlparse(img_url).path) or ("download" + (ext or ""))
        save_image_from_bytes(gr.content, img_url, referrer, suggested_name=suggested)
        # record resource head for next time
        record_resource_head(img_url, etag, last_mod, int(size) if size else None)
    except Exception as e:
        print(f"[!] Img fail {img_url}: {e}")

def extract_images_from_pdf(pdf_bytes: bytes, referrer: str):
    """Use pdfimages to extract embedded images and store them in DB. Returns count saved."""
    saved = 0
    with tempfile.TemporaryDirectory() as td:
        pdf_path = os.path.join(td, "tmp.pdf")
        with open(pdf_path, "wb") as f:
            f.write(pdf_bytes)
        # -all to keep original encodings; -p to include page numbers in names
        try:
            subprocess.run(["pdfimages", "-all", "-p", pdf_path, os.path.join(td, "pdfimg")],
                           check=False, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        except FileNotFoundError:
            print("[!] pdfimages not found. Install poppler-utils.")
            return 0
        # Collect all extracted files
        for fp in glob.glob(os.path.join(td, "pdfimg*")):
            try:
                with open(fp, "rb") as imf:
                    content = imf.read()
                    prior = image_already_saved(hash_bytes(content))
                    if prior:
                        continue
                    res = save_image_from_bytes(content, image_url=f"{referrer}#pdf", referrer=referrer, suggested_name=os.path.basename(fp), provider="pdf")
                    if res:
                        saved += 1
            except Exception as exc:
                print(f"[!] Failed to ingest {fp}: {exc}")
    return saved
