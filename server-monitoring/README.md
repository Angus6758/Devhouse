# System Monitoring Script for Linux Servers

## Overview
This enhanced system monitoring script provides comprehensive insights into Linux server performance, resource utilization, and critical metrics. Designed for Ubuntu systems, it offers real-time monitoring, historical analysis, and Discord alerting capabilities.

![System Monitoring Dashboard](https://via.placeholder.com/800x400.png?text=System+Monitoring+Dashboard)

## Key Features
- **Comprehensive System Reporting**:
  - CPU, RAM, and disk usage monitoring
  - Process analysis (top resource consumers)
  - Historical resource usage tracking
  - Network configuration details
  - Temperature monitoring (physical servers)
  
- **Smart Alerting System**:
  - Discord notifications for threshold breaches
  - Configurable thresholds for CPU, memory, disk
  - Swap space detection and recommendations
  
- **Advanced Analysis Tools**:
  - Identification of largest/modified files
  - Virtual machine detection
  - 24-hour resource trend analysis

## Requirements
- Ubuntu 20.04+ (tested on 24.04 LTS)
- Basic dependencies: `curl`, `bc`, `lm-sensors` (for temp monitoring)
- Discord webhook URL for alerts

## Installation
1. Clone the repository:
```bash
git clone https://github.com/yourusername/system-monitor.git
cd system-monitor
```
2. Make the script executable:
```bash
chmod +x monitor.sh
```
3. Create configuration file:
```bash
cp .env.example .env
```
4. Edit the .env file with your settings:
```bash
nano .env
```
## Configuration
Configure your settings in the .env file:
```bash
# Discord Webhook URL
DISCORD_WEBHOOK="your_discord_webhook_url_here"

# System Identification
SERVICE_NAME="Production Server"
HOSTNAME="server-hostname"

# Alert Thresholds (percentage)
CPU_THRESHOLD="80"
MEM_THRESHOLD="85"
DISK_THRESHOLD="90"
SWAP_THRESHOLD="50"

# Cron Job Schedule (every 5 minutes)
CRON_INTERVAL="*/5 * * * *"
```
## Usage
### Run Manually
```bash
./monitor.sh
```
### Schedule with Cron
1. Open crontab:
```bash
crontab -e
```
2. Add the following line (adjust path as needed):
```bash
*/5 * * * * /path/to/system-monitor/monitor.sh
```
### Sample Output
```bash
Enhanced System Monitoring Report - Fri Aug  8 08:50:50 UTC 2025
-------------------------------------------

===== System Information =====
Hostname: server-hostname
Uptime: up 23 minutes
Operating System: Ubuntu 24.04.2 LTS
Environment: Virtual Machine

===== Resource Usage =====
CPU Usage: 4.8% | Memory: 42.84% | Disk: 26%

===== Threshold Checks & Alerts =====
Memory threshold breached! 42.84% > 1%
Disk threshold breached! 26% > 1%
```
## Customization

### Adjust Thresholds
Modify the values in .env to match your alerting needs:
```bash
CPU_THRESHOLD="80"
MEM_THRESHOLD="85"
DISK_THRESHOLD="90"
```
### Add Temperature Monitoring
For physical servers:
```bash
sudo apt install lm-sensors
sudo sensors-detect
```
### Enable Detailed Logging
Uncomment these lines in the script:
```bash
# To enable debug output:
# VERBOSE=true

# To log curl responses:
# curl ... >> /path/to/curl.log 2>&1
```
## Troubleshooting

### Discord alerts not working?
1. Verify webhook URL in .env
2. Test webhook with curl:
```bash
curl -H "Content-Type: application/json" -X POST -d '{"content":"Test"}' YOUR_WEBHOOK_URL
```
3. Check script permissions: chmod +x monitor.sh

### No temperature data?
- Physical servers: Install lm-sensors
- Virtual machines: Temperature monitoring not available

### Cron job issues?
- Use absolute paths in cron
- Check system mail for cron errors
- Verify environment variables in cron

## Contributing
Contributions are welcome! Please open an issue or submit a pull request:
1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Open a pull request

"An ounce of monitoring is worth a pound of troubleshooting." - System Admin Proverb
