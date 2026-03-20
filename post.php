<?php

$date = date('dMYHis');
$imageData = isset($_POST['cat']) ? $_POST['cat'] : '';

if (!empty($imageData)) {
    // Validate base64 data
    $filteredData = substr($imageData, strpos($imageData, ",") + 1);
    if ($filteredData === false || strlen($filteredData) > 10000000) {
        // Invalid or too large data
        exit();
    }
    
    $unencodedData = base64_decode($filteredData, true);
    if ($unencodedData === false) {
        // Invalid base64
        exit();
    }
    
    error_log("Received" . "\r\n", 3, "Log.log");
    
    $fp = fopen('cam' . $date . '.png', 'wb');
    if ($fp) {
        fwrite($fp, $unencodedData);
        fclose($fp);
    }
}

exit();
?>

