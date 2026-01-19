#!/bin/bash

# WebSec-Suite Installation Script
# Run: chmod +x install.sh && ./install.sh

echo "Installing WebSec-Suite..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root or with sudo"
    echo "Usage: sudo ./install.sh"
    exit 1
fi

# Update system
echo "[*] Updating package lists..."
apt update

# Install tools
echo "[*] Installing Nmap..."
apt install -y nmap

echo "[*] Installing Nikto..."
apt install -y nikto

echo "[*] Installing Nuclei..."
# Method 1: From package
if apt install -y nuclei 2>/dev/null; then
    echo "[✓] Nuclei installed from package"
else
    # Method 2: From Go
    echo "[*] Installing Go..."
    apt install -y golang
    echo "[*] Installing Nuclei from Go..."
    go install -v github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest
    cp ~/go/bin/nuclei /usr/local/bin/
fi

echo "[*] Installing Wapiti..."
apt install -y wapiti

# Update Nuclei templates
echo "[*] Updating Nuclei templates..."
nuclei -update-templates

# Make main script executable
chmod +x websec-suite.sh

echo ""
echo "=========================================="
echo "✅ Installation Completed!"
echo "=========================================="
echo ""
echo "Usage:"
echo "  ./websec-suite.sh http://example.com"
echo "  ./websec-suite.sh https://example.com"
echo ""
echo "Quick test:"
echo "  ./websec-suite.sh http://testphp.vulnweb.com"
echo ""