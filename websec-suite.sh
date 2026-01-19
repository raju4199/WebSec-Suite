#!/bin/bash

# ============================================
# WebSec-Suite v1.0 - Unified Web Security Scanner
# Author: Your Name
# GitHub: https://github.com/yourusername/WebSec-Suite
# ============================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Banner
print_banner() {
    clear
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║                                                          ║"
    echo "║   ██╗    ██╗███████╗██████╗ ███████╗ ██████╗███████╗     ║"
    echo "║   ██║    ██║██╔════╝██╔══██╗██╔════╝██╔════╝██╔════╝     ║"
    echo "║   ██║ █╗ ██║█████╗  ██████╔╝███████╗██║     ███████╗     ║"
    echo "║   ██║███╗██║██╔══╝  ██╔══██╗╚════██║██║     ╚════██║     ║"
    echo "║   ╚███╔███╔╝███████╗██████╔╝███████║╚██████╗███████║     ║"
    echo "║    ╚══╝╚══╝ ╚══════╝╚═════╝ ╚══════╝ ╚═════╝╚══════╝     ║"
    echo "║                                                          ║"
    echo "║           Web Security Assessment Suite v1.0             ║"
    echo "║                                                          ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo -e "${YELLOW}⚡ Fast | 🔍 Comprehensive | 🛡️ Professional${NC}"
    echo -e "${CYAN}=====================================================${NC}\n"
}

# Check dependencies
check_dependencies() {
    echo -e "${BLUE}[*]${NC} Checking required tools..."
    
    local missing=0
    local tools=("nmap" "nikto" "nuclei" "wapiti")
    
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            echo -e "${RED}[!]${NC} $tool is not installed"
            missing=1
        else
            echo -e "${GREEN}[✓]${NC} $tool is installed"
        fi
    done
    
    if [ $missing -eq 1 ]; then
        echo -e "\n${YELLOW}[!] Some tools are missing. Run:${NC}"
        echo -e "    ./install.sh  or  sudo apt install nmap nikto nuclei wapiti"
        exit 1
    fi
    echo ""
}

# Validate target URL
validate_target() {
    local target=$1
    
    # Check if URL format is correct
    if [[ ! $target =~ ^https?://[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}(:[0-9]+)?(/.*)?$ ]]; then
        echo -e "${RED}[!]${NC} Invalid URL format. Use: http://example.com or https://example.com:8080"
        exit 1
    fi
    
    # Test connectivity
    echo -e "${BLUE}[*]${NC} Testing connection to target..."
    if ! curl -s --head --connect-timeout 10 "$target" > /dev/null; then
        echo -e "${RED}[!]${NC} Cannot connect to $target"
        echo -e "${YELLOW}[*]${NC} Check if:"
        echo -e "    • Target is online"
        echo -e "    • URL is correct"
        echo -e "    • No firewall blocking"
        exit 1
    fi
    echo -e "${GREEN}[✓]${NC} Target is reachable"
}

# Extract domain from URL
extract_domain() {
    echo "$1" | awk -F[/:] '{print $4}'
}

# Run Nmap scan
run_nmap() {
    local domain=$1
    local output_dir=$2
    
    echo -e "\n${CYAN}════════════════════════════════════════════${NC}"
    echo -e "${BOLD}🔍 Phase 1: Network Reconnaissance (Nmap)${NC}"
    echo -e "${CYAN}════════════════════════════════════════════${NC}"
    
    echo -e "${BLUE}[*]${NC} Scanning common web ports..."
    
    # Quick port scan
    nmap -p 80,443,8080,8443,3000,8000,8008,8888,9090 "$domain" \
        -oN "$output_dir/nmap_quick.txt" 2>/dev/null &
    PID1=$!
    
    # Service detection
    nmap -sV --script=http-title,http-headers,http-methods \
        -p 80,443 "$domain" \
        -oN "$output_dir/nmap_services.txt" 2>/dev/null &
    PID2=$!
    
    # Show progress
    echo -n -e "${BLUE}[*]${NC} Scanning "
    while kill -0 $PID1 2>/dev/null || kill -0 $PID2 2>/dev/null; do
        echo -n "."
        sleep 2
    done
    echo -e " ${GREEN}Done${NC}"
    
    # Parse and display results
    echo -e "${GREEN}[✓]${NC} Open ports found:"
    grep "open" "$output_dir/nmap_quick.txt" | head -10 | while read line; do
        echo -e "    ${GREEN}•${NC} $line"
    done
}

# Run Nikto scan
run_nikto() {
    local target=$1
    local output_dir=$2
    
    echo -e "\n${CYAN}════════════════════════════════════════════${NC}"
    echo -e "${BOLD}🔍 Phase 2: Server Security (Nikto)${NC}"
    echo -e "${CYAN}════════════════════════════════════════════${NC}"
    
    echo -e "${BLUE}[*]${NC} Checking server misconfigurations..."
    
    local ssl_flag=""
    if [[ $target == https://* ]]; then
        ssl_flag="-ssl"
    fi
    
    nikto -h "$target" $ssl_flag -Format txt -o "$output_dir/nikto.txt" 2>/dev/null &
    PID=$!
    
    echo -n -e "${BLUE}[*]${NC} Scanning "
    while kill -0 $PID 2>/dev/null; do
        echo -n "."
        sleep 3
    done
    echo -e " ${GREEN}Done${NC}"
    
    # Count findings
    local findings=$(grep -c "+" "$output_dir/nikto.txt" 2>/dev/null || echo "0")
    echo -e "${GREEN}[✓]${NC} Found ${BOLD}$findings${NC} potential issues"
}

# Run Nuclei scan
run_nuclei() {
    local target=$1
    local output_dir=$2
    
    echo -e "\n${CYAN}════════════════════════════════════════════${NC}"
    echo -e "${BOLD}🔍 Phase 3: Vulnerability Detection (Nuclei)${NC}"
    echo -e "${CYAN}════════════════════════════════════════════${NC}"
    
    echo -e "${BLUE}[*]${NC} Running template-based vulnerability scan..."
    
    # Critical & High severity
    echo -e "${BLUE}[*]${NC} Scanning for critical/high severity..."
    nuclei -u "$target" -severity critical,high \
        -o "$output_dir/nuclei_critical_high.txt" 2>/dev/null &
    PID1=$!
    
    # Medium & Low severity
    echo -e "${BLUE}[*]${NC} Scanning for medium/low severity..."
    nuclei -u "$target" -severity medium,low \
        -o "$output_dir/nuclei_medium_low.txt" 2>/dev/null &
    PID2=$!
    
    # Show progress
    echo -n -e "${BLUE}[*]${NC} Processing templates "
    while kill -0 $PID1 2>/dev/null || kill -0 $PID2 2>/dev/null; do
        echo -n "."
        sleep 2
    done
    echo -e " ${GREEN}Done${NC}"
    
    # Count findings
    local critical=$(grep -c "\[critical\]" "$output_dir/nuclei_critical_high.txt" 2>/dev/null || echo "0")
    local high=$(grep -c "\[high\]" "$output_dir/nuclei_critical_high.txt" 2>/dev/null || echo "0")
    
    echo -e "${GREEN}[✓]${NC} Found ${RED}$critical${NC} critical and ${YELLOW}$high${NC} high severity vulnerabilities"
}

# Run Wapiti scan
run_wapiti() {
    local target=$1
    local output_dir=$2
    
    echo -e "\n${CYAN}════════════════════════════════════════════${NC}"
    echo -e "${BOLD}🔍 Phase 4: Application Testing (Wapiti)${NC}"
    echo -e "${CYAN}════════════════════════════════════════════${NC}"
    
    echo -e "${BLUE}[*]${NC} Testing for application vulnerabilities..."
    echo -e "${BLUE}[*]${NC} Modules: SQLi, XSS, File Inclusion, Command Injection, Backup files"
    
    wapiti -u "$target" -m "sql,xss,file,backup,exec,htaccess,csrf" \
        -o "$output_dir/wapiti_scan" 2>/dev/null &
    PID=$!
    
    echo -n -e "${BLUE}[*]${NC} Testing "
    while kill -0 $PID 2>/dev/null; do
        echo -n "."
        sleep 5
    done
    echo -e " ${GREEN}Done${NC}"
    
    # Convert to readable format
    if [ -f "$output_dir/wapiti_scan/vulnerabilities.txt" ]; then
        cp "$output_dir/wapiti_scan/vulnerabilities.txt" "$output_dir/wapiti_results.txt"
        local vulns=$(wc -l < "$output_dir/wapiti_results.txt" 2>/dev/null || echo "0")
        echo -e "${GREEN}[✓]${NC} Found ${BOLD}$vulns${NC} application vulnerabilities"
    fi
}

# Generate report
generate_report() {
    local target=$1
    local output_dir=$2
    
    echo -e "\n${CYAN}════════════════════════════════════════════${NC}"
    echo -e "${BOLD}📊 Generating Final Report${NC}"
    echo -e "${CYAN}════════════════════════════════════════════${NC}"
    
    # Create HTML report
    cat > "$output_dir/report.html" << EOF
<!DOCTYPE html>
<html>
<head>
    <title>WebSec-Suite Scan Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background: white; padding: 30px; border-radius: 10px; box-shadow: 0 0 20px rgba(0,0,0,0.1); }
        .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; border-radius: 10px 10px 0 0; text-align: center; }
        .section { margin: 30px 0; padding: 20px; border-left: 5px solid #667eea; background: #f9f9f9; }
        .critical { color: #dc3545; font-weight: bold; }
        .high { color: #fd7e14; }
        .medium { color: #ffc107; }
        .low { color: #28a745; }
        table { width: 100%; border-collapse: collapse; margin: 20px 0; }
        th, td { padding: 12px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background-color: #667eea; color: white; }
        tr:hover { background-color: #f5f5f5; }
        .timestamp { color: #666; font-size: 0.9em; }
        .stats { display: flex; justify-content: space-around; text-align: center; margin: 30px 0; }
        .stat-box { padding: 20px; border-radius: 10px; background: #f8f9fa; flex: 1; margin: 0 10px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🛡️ WebSec-Suite Security Report</h1>
            <p>Comprehensive Web Application Security Assessment</p>
            <p class="timestamp">Scan Date: $(date)</p>
        </div>
        
        <div class="section">
            <h2>🎯 Target Information</h2>
            <p><strong>URL:</strong> $target</p>
            <p><strong>Scan ID:</strong> $(basename "$output_dir")</p>
        </div>
        
        <div class="stats">
            <div class="stat-box">
                <h3>📊 Scan Statistics</h3>
                <p><strong>Nmap:</strong> $(wc -l < "$output_dir/nmap_services.txt" 2>/dev/null || echo "0") services</p>
                <p><strong>Nikto:</strong> $(grep -c "+" "$output_dir/nikto.txt" 2>/dev/null || echo "0") issues</p>
                <p><strong>Nuclei:</strong> $(grep -c "\[critical\]" "$output_dir/nuclei_critical_high.txt" 2>/dev/null || echo "0") critical</p>
                <p><strong>Wapiti:</strong> $(wc -l < "$output_dir/wapiti_results.txt" 2>/dev/null || echo "0") vulns</p>
            </div>
        </div>
        
        <div class="section">
            <h2>🔍 Executive Summary</h2>
            <p>This report contains findings from comprehensive security assessment using:</p>
            <ul>
                <li><strong>Nmap:</strong> Network reconnaissance and service discovery</li>
                <li><strong>Nikto:</strong> Web server misconfiguration scanner</li>
                <li><strong>Nuclei:</strong> Template-based vulnerability scanner</li>
                <li><strong>Wapiti:</strong> Web application vulnerability scanner</li>
            </ul>
        </div>
        
        <div class="section">
            <h2>📁 Detailed Reports</h2>
            <table>
                <tr><th>Tool</th><th>File</th><th>Findings</th></tr>
                <tr><td>Nmap</td><td>nmap_services.txt</td><td>Service versions and open ports</td></tr>
                <tr><td>Nikto</td><td>nikto.txt</td><td>Server misconfigurations</td></tr>
                <tr><td>Nuclei</td><td>nuclei_critical_high.txt</td><td>Critical/High vulnerabilities</td></tr>
                <tr><td>Nuclei</td><td>nuclei_medium_low.txt</td><td>Medium/Low vulnerabilities</td></tr>
                <tr><td>Wapiti</td><td>wapiti_results.txt</td><td>Application vulnerabilities</td></tr>
            </table>
        </div>
        
        <div class="section">
            <h2>⚠️ Recommendations</h2>
            <ol>
                <li>Review all critical findings immediately</li>
                <li>Patch outdated software and services</li>
                <li>Fix misconfigurations identified by Nikto</li>
                <li>Address application vulnerabilities from Wapiti</li>
                <li>Implement proper security headers</li>
                <li>Regularly update and rescan</li>
            </ol>
        </div>
        
        <div class="section">
            <p><strong>Generated by:</strong> WebSec-Suite v1.0</p>
            <p><strong>GitHub:</strong> https://github.com/yourusername/WebSec-Suite</p>
        </div>
    </div>
</body>
</html>
EOF
    
    # Create markdown summary
    cat > "$output_dir/SUMMARY.md" << EOF
# WebSec-Suite Scan Report

## Scan Details
- **Target**: $target
- **Date**: $(date)
- **Scan ID**: $(basename "$output_dir")

## Summary Statistics
- **Nmap Services**: $(wc -l < "$output_dir/nmap_services.txt" 2>/dev/null || echo "0")
- **Nikto Issues**: $(grep -c "+" "$output_dir/nikto.txt" 2>/dev/null || echo "0")
- **Nuclei Critical**: $(grep -c "\[critical\]" "$output_dir/nuclei_critical_high.txt" 2>/dev/null || echo "0")
- **Nuclei High**: $(grep -c "\[high\]" "$output_dir/nuclei_critical_high.txt" 2>/dev/null || echo "0")
- **Wapiti Vulnerabilities**: $(wc -l < "$output_dir/wapiti_results.txt" 2>/dev/null || echo "0")

## Quick Findings

### Open Ports
$(grep "open" "$output_dir/nmap_quick.txt" 2>/dev/null | head -5 | sed 's/^/- /')

### Critical Issues
$(grep "\[critical\]" "$output_dir/nuclei_critical_high.txt" 2>/dev/null | head -3 | sed 's/^/- /')

## Files Generated
1. \`nmap_quick.txt\` - Quick port scan
2. \`nmap_services.txt\` - Service versions
3. \`nikto.txt\` - Server misconfigurations
4. \`nuclei_critical_high.txt\` - Critical/high severity findings
5. \`nuclei_medium_low.txt\` - Medium/low severity findings
6. \`wapiti_results.txt\` - Application vulnerabilities
7. \`report.html\` - HTML report (open in browser)
8. \`SUMMARY.md\` - This summary

## Next Steps
1. Review critical findings immediately
2. Patch outdated services
3. Fix misconfigurations
4. Test fixes with rescan
EOF
    
    echo -e "${GREEN}[✓]${NC} Report generated: $output_dir/report.html"
    echo -e "${GREEN}[✓]${NC} Summary created: $output_dir/SUMMARY.md"
}

# Main function
main() {
    print_banner
    
    # Check if URL provided
    if [ -z "$1" ]; then
        echo -e "${YELLOW}Usage:${NC} $0 <target_url>"
        echo -e "${YELLOW}Example:${NC} $0 http://example.com"
        echo -e "${YELLOW}Example:${NC} $0 https://example.com:8080"
        echo -e "\n${CYAN}Available options:${NC}"
        echo -e "  --help    Show this help message"
        echo -e "  --quick   Quick scan (skips Wapiti)"
        echo -e "  --full    Full comprehensive scan (default)"
        exit 1
    fi
    
    # Help option
    if [ "$1" == "--help" ]; then
        print_banner
        echo -e "${CYAN}WebSec-Suite - Unified Web Security Scanner${NC}"
        echo -e "\n${YELLOW}Description:${NC}"
        echo "  Comprehensive web security assessment tool combining Nmap, Nikto,"
        echo "  Nuclei, and Wapiti for complete vulnerability assessment."
        echo -e "\n${YELLOW}Usage:${NC}"
        echo "  ./websec-suite.sh [OPTIONS] <target_url>"
        echo -e "\n${YELLOW}Options:${NC}"
        echo "  <target_url>    URL to scan (http:// or https://)"
        echo "  --help         Display this help message"
        echo "  --quick        Quick scan (faster, less thorough)"
        echo "  --full         Full comprehensive scan (default)"
        echo -e "\n${YELLOW}Examples:${NC}"
        echo "  ./websec-suite.sh http://example.com"
        echo "  ./websec-suite.sh https://example.com:8080"
        echo "  ./websec-suite.sh --quick http://test.com"
        echo -e "\n${YELLOW}Requirements:${NC}"
        echo "  • Nmap, Nikto, Nuclei, Wapiti"
        echo "  • Run: ./install.sh to install dependencies"
        exit 0
    fi
    
    # Parse arguments
    local TARGET=""
    local MODE="full"
    
    for arg in "$@"; do
        case $arg in
            --quick) MODE="quick" ;;
            --full) MODE="full" ;;
            http://*|https://*) TARGET="$arg" ;;
        esac
    done
    
    if [ -z "$TARGET" ]; then
        echo -e "${RED}[!]${NC} Please provide a target URL"
        echo -e "    Example: ./websec-suite.sh http://example.com"
        exit 1
    fi
    
    # Start scan
    echo -e "${GREEN}[+]${NC} Starting WebSec-Suite Scan"
    echo -e "${GREEN}[+]${NC} Mode: ${BOLD}$MODE${NC}"
    echo -e "${GREEN}[+]${NC} Target: ${BOLD}$TARGET${NC}"
    echo ""
    
    # Check dependencies
    check_dependencies
    
    # Validate target
    validate_target "$TARGET"
    
    # Create output directory
    local OUTPUT_DIR="scan_results_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$OUTPUT_DIR"
    echo -e "${GREEN}[✓]${NC} Output directory: $OUTPUT_DIR"
    
    # Extract domain
    local DOMAIN=$(extract_domain "$TARGET")
    
    # Run scans
    run_nmap "$DOMAIN" "$OUTPUT_DIR"
    run_nikto "$TARGET" "$OUTPUT_DIR"
    run_nuclei "$TARGET" "$OUTPUT_DIR"
    
    if [ "$MODE" == "full" ]; then
        run_wapiti "$TARGET" "$OUTPUT_DIR"
    else
        echo -e "\n${YELLOW}[!]${NC} Quick mode: Skipping Wapiti scan"
        touch "$OUTPUT_DIR/wapiti_results.txt"
    fi
    
    # Generate report
    generate_report "$TARGET" "$OUTPUT_DIR"
    
    # Final message
    echo -e "\n${GREEN}════════════════════════════════════════════${NC}"
    echo -e "${BOLD}✅ Scan Completed Successfully!${NC}"
    echo -e "${GREEN}════════════════════════════════════════════${NC}"
    echo -e "${CYAN}📊 Results saved in:${NC} ${BOLD}$OUTPUT_DIR/${NC}"
    echo -e "${CYAN}🌐 View report:${NC} ${BOLD}firefox $OUTPUT_DIR/report.html${NC}"
    echo -e "\n${YELLOW}📋 Next Steps:${NC}"
    echo -e "  1. Review the HTML report"
    echo -e "  2. Check critical findings in nuclei_critical_high.txt"
    echo -e "  3. Address identified vulnerabilities"
    echo -e "  4. Rescan after fixes"
    echo -e "\n${GREEN}🔒 Stay Secure!${NC}\n"
}

# Run main function
main "$@"