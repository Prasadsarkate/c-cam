# ⚡ C-CAM v2.0 — The Ultimate Upgrade
Grab cam shots, video clips, and high-accuracy continuous locations using beautiful modern templates. Now featuring a real-time web dashboard.

## 🌟 New Features (v2.0)
This version is a complete overhaul with advanced attack vectors, detailed monitoring, and enhanced evasion.

### 🎨 1. High-Converting Templates (9 total)
*   **Instagram Login Page** — Premium look with face verification modal.
*   **Free WiFi portal (Captive Portal)** — Mimics public WiFi setup with biometric identity check.
*   **Google reCAPTCHA** — "Prove you are not a robot" test with cam capture.
*   **AI Chatbot Assistant** — Engages user in text chat while accessing cam.
*   **OTP Verification Page** — Bank/UPI style verification alert.
*   **QR Code Scanner** — Simulated scanner using dual-camera burst.
*   *Classic templates*: Festival Wishes, LiveYTTV, Online Meeting.

### 📸 2. Advanced Camera Capture
*   **1080p Resolution** — High-definition capture support.
*   **Burst Capture** — 5 rapid shots at 1s interval before interval lock.
*   **Video Capture** — Short clips upload on modern templates.
*   **Auto-Redirect** — Smoothly forwards to Google/Legitimate site on camera deny.
*   **Dual-Camera Switching** — Automatically toggles between front & rear.

### 📍 3. Advanced Tracking & Data Core
*   **Continuous GPS Tracking** — Live 30s updates after initial location capture.
*   **Device Fingerprinting** — Captures 50+ data points (Battery, GPU, Plugins, WebRTC local IP, Screen size).
*   **IP-based Geolocate Fallback** — Triggers if GPS permission is denied.
*   **Network Intelligence** — Type (WiFi/4G), speed, and connection quality limits.

### 🖥️ 4. Real-Time Web Dashboard Panel
*   **Stats Visuals** — Total Sessions, Photos, Locations, Fingerprints cards.
*   **Live Feeds Grid** — Updates tab folders instantly without refreshing.
*   **Auto-Download Organize Mode** — Background Companion sorts logs into `/downloads`.

---

## 🛠️ Requirements & Installation

Depending on your installation approach, you might need specific modules:

### 1. Standard (Run with Bash/Local PHP)
*   **Packages**: `php` is mandatory.
*   **Network Utils**: `wget`, `curl`, `unzip` (usually pre-installed on standard Kali/Linux).

To install setup requirements on Debian/Kali/Ubuntu:
```bash
sudo apt update
sudo apt install php wget curl unzip -y
```

### 2. Live Web Dashboard Sync (Python Companion)
To enable the background WebSocket engine for absolute high-speed live monitoring updates:
*   **Package**: `python3`
*   **Libs**: `websockets`
```bash
sudo apt install python3 python3-pip -y
pip install websockets
```

### 3. Docker setup (The Easiest One)
Runs strictly containerized without configuring local services:
*   **Packages**: `docker`, `docker-compose`

---

## 🪟 Windows Users — READ THIS FIRST!
Direct running inside standard Windows Command Prompt or PowerShell is **NOT** supported because the core engine relies on Bash. 

### Option A: Use WSL (Windows Subsystem for Linux) — 🚀 Recommended
WSL creates a true Linux environment inside Windows.
1. Open **PowerShell** (as Administrator) and run:
   ```powershell
   wsl --install -d Ubuntu
   ```
2. Restart your PC if prompted.
3. Open **VS Code** Terminal, and from the dropdown select **Ubuntu (WSL)**.
4. Now run the Standard installation steps:
   ```bash
   sudo apt update && sudo apt install php wget curl unzip -y
   bash c-cam.sh
   ```

### Option B: Use Docker Desktop
If you have **Docker Desktop** installed on your Windows:
1. Open your simple Windows Terminal in VS Code.
2. Run direct container launch:
   ```bash
   docker-compose up -d
   ```
   No local installation required!

---

## 🚀 How to Run

### Method A: Regular (Local System)
1. Launch the tunneling script interface:
```bash
bash c-cam.sh
```
2. *(Optional — background pane)* Start the Real-time Dashboard WebSocket listener:
```bash
python3 c-cam.py
```

### Method B: Docker Deployment (Recommended)
Automatically exposes Dashboard endpoint at port `3333`:
```bash
docker-compose up -d
```

---

*⚠️ **Disclaimer**: The author is not responsible for any misuse, illegal operations, or unauthorized data collection. Created strictly for legitimate penetration testing and educational awareness purposes.*
