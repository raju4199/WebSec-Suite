# 🛡️ WebSec-Suite - Unified Web Security Scanner

[![GitHub stars](https://img.shields.io/github/stars/yourusername/WebSec-Suite?style=for-the-badge)](https://github.com/yourusername/WebSec-Suite)
[![License](https://img.shields.io/badge/License-MIT-blue?style=for-the-badge)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Linux-lightgrey?style=for-the-badge)](https://github.com/yourusername/WebSec-Suite)

**WebSec-Suite** is a comprehensive web security assessment tool that combines multiple scanners into a single, easy-to-use interface. It automates the process of web vulnerability assessment from reconnaissance to detailed application testing.

---

## 📋 Features

- **🔍 Complete Reconnaissance** - Nmap for network and service discovery
- **🛡️ Server Security** - Nikto for server misconfigurations
- **⚡ Vulnerability Detection** - Nuclei with 5000+ templates
- **🎯 Application Testing** - Wapiti for SQLi, XSS, and more
- **📊 Professional Reporting** - HTML and Markdown reports
- **⚙️ Easy to Use** - Single command, automatic workflow
- **🚀 Fast & Efficient** - Parallel scanning, smart timeout handling

---

## 🚀 Quick Start

### Prerequisites
- Linux (Kali, Ubuntu, Debian, Parrot OS)
- Root/sudo access (recommended)
- 2GB RAM minimum

### Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/WebSec-Suite.git
cd WebSec-Suite

# Run installation script
sudo ./install.sh

# Or install manually
sudo apt update
sudo apt install -y nmap nikto nuclei wapiti

### Basic Usage
# Make script executable
chmod +x websec-suite.sh

# Scan a website
./websec-suite.sh http://example.com

# Scan with HTTPS
./websec-suite.sh https://example.com

# Quick scan (skips Wapiti)
./websec-suite.sh --quick http://example.com

### Scanning Options
# Full comprehensive scan (default)
./websec-suite.sh http://target.com

# Quick scan (faster, less thorough)
./websec-suite.sh --quick http://target.com

# Scan with custom port
./websec-suite.sh http://target.com:8080

# Get help
./websec-suite.sh --help


### Test Targets (for practice)
# Test on vulnerable practice sites
./websec-suite.sh http://testphp.vulnweb.com
./websec-suite.sh http://demo.testfire.net
./websec-suite.sh http://bwapp.bwapp.org