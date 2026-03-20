#!/bin/bash
# Cleanup script for CamPhish v2
# Removes all unnecessary files and logs

echo "Starting cleanup of CamPhish v2 files..."

# Remove log files
echo "Removing log files..."
rm -f *.log
rm -f .cloudflared.log
rm -f .last_video_sent

# Remove temporary location files
echo "Removing temporary location files..."
rm -f location_*.txt
rm -f ip_location_*.txt
rm -f current_location.txt
rm -f current_location.bak
rm -f current_ip_location.txt

# Remove fingerprint files
echo "Removing fingerprint files..."
rm -f fingerprint_*.txt
rm -f current_fingerprint.txt

# Remove captured images
echo "Removing captured images..."
rm -f cam*.png

# Remove captured videos
echo "Removing captured videos..."
rm -f video_*.webm

# Remove saved data files
echo "Removing saved data files..."
rm -f saved.ip.txt
rm -f saved.locations.txt
rm -f saved.ip_locations.txt
rm -f saved.fingerprints.txt
rm -f ip.txt

# Remove temporary HTML files
echo "Removing temporary HTML files..."
rm -f index.php
rm -f index2.html
rm -f index3.html

# Clean saved directories but keep them
echo "Cleaning saved directories..."
if [ -d "saved_locations" ]; then
    rm -f saved_locations/*
fi
if [ -d "saved_fingerprints" ]; then
    rm -f saved_fingerprints/*
fi
if [ -d "saved_videos" ]; then
    rm -f saved_videos/*
fi

# Remove any other temporary files
echo "Removing other temporary files..."
rm -f LocationLog.log
rm -f LocationError.log
rm -f FingerprintLog.log
rm -f IPLocationLog.log
rm -f Log.log

echo "Cleanup completed successfully!"