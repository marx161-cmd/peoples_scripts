# utils.py
# Handles DB, deduplication, ETag checks, PDF parsing, provider tagging
import os
import sqlite3
import hashlib
import requests
from datetime import datetime

DB_PATH = os.path.join(os.path.dirname(__file__), 'scraper.db')

def init_db():
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()
    c.execute('CREATE TABLE IF NOT EXISTS files (hash TEXT PRIMARY KEY, url TEXT, date TEXT)')
    conn.commit()
    conn.close()

def file_seen(url, content):
    file_hash = hashlib.sha256(content).hexdigest()
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()
    c.execute('SELECT 1 FROM files WHERE hash=?', (file_hash,))
    exists = c.fetchone() is not None
    if not exists:
        c.execute('INSERT INTO files VALUES (?, ?, ?)', (file_hash, url, datetime.utcnow().isoformat()))
    conn.commit()
    conn.close()
    return exists
