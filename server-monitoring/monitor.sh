#!/bin/bash

# Enhanced System Monitoring Script for Ubuntu
# Tracks max resource usage over 24 hours and identifies top files
# Added VM detection and swap warning features

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

#=========================#
#  Discord Alert Function #
#=========================#
VERBOSE=false  # Set to true for debugging

send_discord_alert() {
    local message="$1"
    local webhook_url="${DISCORD_WEBHOOK}"

    # Clean the URL
    webhook_url=$(echo "$webhook_url" | tr -d '"' | tr -d "'" | xargs)

    if [ "$VERBOSE" = true ]; then
        echo "DEBUG: Sending alert to Discord..."
        curl -H "Content-Type: application/json" \
             -X POST \
             -d "{\"content\": \"$message\"}" \
             "$webhook_url"
    else
        curl -s -H "Content-Type: application/json" \
             -X POST \
             -d "{\"content\": \"$message\"}" \
             "$webhook_url" >/dev/null 2>&1
    fi
}
# Log directory
LOG_DIR="$HOME/system_monitor_logs"
mkdir -p "$LOG_DIR"

# Current timestamp
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# VM Detection - Check if running in a virtualized environment
IS_VM=false
if [ -f /sys/hypervisor/uuid ] || grep -q -E 'vmx|svm|hypervisor' /proc/cpuinfo; then
    IS_VM=true
elif [ -f /sys/class/dmi/id/product_name ] && \
     grep -q -i -E 'vmware|virtualbox|kvm|qemu|amazon ec2|hyper-v' /sys/class/dmi/id/product_name; then
    IS_VM=true
fi

# Function to display section headers
section_header() {
    echo -e "\n${BLUE}===== $1 =====${NC}"
}

# Clear screen
clear

# Display current date and time
echo -e "${GREEN}Enhanced System Monitoring Report - $(date)${NC}"
echo -e "${GREEN}-------------------------------------------${NC}"

# 1. System Information
section_header "System Information"
echo -e "Hostname: ${YELLOW}$(hostname)${NC}"
echo -e "Uptime: ${YELLOW}$(uptime -p)${NC}"

# Get OS information
if command -v lsb_release &> /dev/null; then
    echo -e "Operating System: ${YELLOW}$(lsb_release -d | cut -f2-)${NC}"
elif [ -f /etc/os-release ]; then
    echo -e "Operating System: ${YELLOW}$(grep PRETTY_NAME /etc/os-release | cut -d '"' -f2)${NC}"
else
    echo -e "Operating System: ${YELLOW}Unknown${NC}"
fi

echo -e "Kernel Version: ${YELLOW}$(uname -r)${NC}"
echo -e "Architecture: ${YELLOW}$(uname -m)${NC}"
[ "$IS_VM" = true ] && echo -e "Environment: ${RED}Virtual Machine${NC}"

# 2. CPU Information
section_header "CPU Information"
echo -e "Processor: ${YELLOW}$(grep "model name" /proc/cpuinfo | head -n1 | cut -d ":" -f2 | sed 's/^[ \t]*//')${NC}"
echo -e "CPU Cores: ${YELLOW}$(nproc)${NC}"
echo -e "Current Load: ${YELLOW}$(uptime | awk -F 'load average:' '{print $2}')${NC}"
echo -e "Current CPU Usage: ${YELLOW}$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1"%"}')${NC}"

# Calculate max CPU load in last 24 hours
MAX_CPU_LOAD=$(cat /var/log/syslog /var/log/syslog.1 2>/dev/null | grep -a "CPU load" | awk -F 'load average: ' '{print $2}' | awk -F ', ' '{print $1, $2, $3}' | sort -nr | head -n1)
echo -e "Max CPU Load (24h): ${RED}${MAX_CPU_LOAD:-"Data not available"}${NC}"

# 3. Memory Information
section_header "RAM Information"
total_mem=$(free -h | grep "Mem:" | awk '{print $2}')
used_mem=$(free -h | grep "Mem:" | awk '{print $3}')
free_mem=$(free -h | grep "Mem:" | awk '{print $4}')
buff_cache=$(free -h | grep "Mem:" | awk '{print $6}')
available_mem=$(free -h | grep "Mem:" | awk '{print $7}')
current_mem_usage=$(free | grep Mem | awk '{print $3/$2 * 100.0}' | cut -c1-5)

echo -e "Total Memory: ${YELLOW}$total_mem${NC}"
echo -e "Used Memory: ${YELLOW}$used_mem${NC}"
echo -e "Free Memory: ${YELLOW}$free_mem${NC}"
echo -e "Buffers/Cache: ${YELLOW}$buff_cache${NC}"
echo -e "Available Memory: ${YELLOW}$available_mem${NC}"
echo -e "Current Memory Usage: ${YELLOW}$current_mem_usage%${NC}"

# Find max RAM usage in last 24 hours from syslog
MAX_RAM_USAGE=$(cat /var/log/syslog /var/log/syslog.1 2>/dev/null | grep -a "Memory usage" | awk -F 'usage: ' '{print $2}' | sort -nr | head -n1)
#echo -e "Max RAM Usage (24h): ${RED}${MAX_RAM_USAGE:-"Data not available"}${NC}"
echo -e "Max CPU Load (24h): ${RED}${MAX_CPU_LOAD:-'Data not available'}${NC}"

# 4. Swap Information
section_header "Swap Information"
SWAP_EXISTS=false
if swapon --show | grep -q .; then
    SWAP_EXISTS=true
    total_swap=$(free -h | grep "Swap:" | awk '{print $2}')
    used_swap=$(free -h | grep "Swap:" | awk '{print $3}')
    free_swap=$(free -h | grep "Swap:" | awk '{print $4}')
    echo -e "Total Swap: ${YELLOW}$total_swap${NC}"
    echo -e "Used Swap: ${YELLOW}$used_swap${NC}"
    echo -e "Free Swap: ${YELLOW}$free_swap${NC}"
else
    echo -e "${RED}No swap space detected${NC}"
fi

# 5. Disk Usage
section_header "Disk Usage"
echo -e "${YELLOW}$(df -h --total | grep -v "tmpfs" | grep -v "udev")${NC}"

# 6. Identify most modified files in last 24 hours
section_header "Most Modified Files (24h)"
echo -e "${YELLOW}Top 5 modified files:${NC}"
find / -type f -mtime -1 -printf "%s %p\n" 2>/dev/null | sort -nr | head -n 5 | awk '{print $1/1024/1024 " MB - " $2}'

# 7. Largest files on system
section_header "Largest Files on System"
echo -e "${YELLOW}Top 5 largest files:${NC}"
find / -type f -printf "%s %p\n" 2>/dev/null | sort -nr | head -n 5 | awk '{print $1/1024/1024 " MB - " $2}'

# 8. Process Information
section_header "Process Analysis"
echo -e "${YELLOW}Top 5 Memory-Consuming Processes:${NC}"
ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%mem | head -n 6

echo -e "\n${YELLOW}Top 5 CPU-Consuming Processes:${NC}"
ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%cpu | head -n 6

# 9. Historical Process Analysis (from syslog)
section_header "Historical Process Analysis (24h)"
echo -e "${YELLOW}Most frequent high-CPU processes:${NC}"
cat /var/log/syslog /var/log/syslog.1 2>/dev/null | grep -a "high CPU" | awk '{print $12}' | sort | uniq -c | sort -nr | head -n5

echo -e "\n${YELLOW}Most frequent high-RAM processes:${NC}"
cat /var/log/syslog /var/log/syslog.1 2>/dev/null | grep -a "high memory" | awk '{print $12}' | sort | uniq -c | sort -nr | head -n5

# 10. Network Information
section_header "Network Information"
echo -e "Public IP: ${YELLOW}$(curl -s ifconfig.me || echo "Not available")${NC}"
echo -e "Local IP: ${YELLOW}$(hostname -I | awk '{print $1}')${NC}"

# 11. System Temperature (if available)
section_header "System Temperature"
if [ "$IS_VM" = true ]; then
    echo -e "${YELLOW}Temperature monitoring not available in virtualized environments${NC}"
elif command -v sensors &> /dev/null; then
    temp_output=$(sensors | grep -E 'Core|Package|temp1' | grep -E -v '\+(0\.0).*C')
    if [ -n "$temp_output" ]; then
        echo -e "${YELLOW}$temp_output${NC}"
    else
        echo -e "${YELLOW}No temperature data available${NC}"
    fi
else
    echo -e "${RED}Note: Install 'lm-sensors' package for temperature monitoring${NC}"
fi

# Save current stats to log file
echo "$(date), CPU: $(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1"%"}'), RAM: $current_mem_usage%" >> "$LOG_DIR/system_stats_$(date +%Y%m%d).log"

# Show swap warning if no swap detected
if [ "$SWAP_EXISTS" = false ]; then
    echo -e "\n${RED}NOTE: No swap space detected!${NC}"
    echo -e "${RED}For better system stability, consider adding swap space:"
    echo -e "https://linuxize.com/post/create-a-linux-swap-file/${NC}"
fi

echo -e "\n${GREEN}End of Report${NC}"
echo -e "Log file created at: ${YELLOW}$LOG_DIR/system_stats_$(date +%Y%m%d).log${NC}"

# 12. Threshold Checks & Alerting
section_header "Threshold Checks & Alerts"

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/.env"
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
else
    echo -e "${RED}Config file missing. Alerts disabled.${NC}"
fi
# Sanitize webhook: remove any surrounding quotes
DISCORD_WEBHOOK="${DISCORD_WEBHOOK%\"}"
DISCORD_WEBHOOK="${DISCORD_WEBHOOK#\"}"

# CPU Check
current_cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
if (( $(echo "$current_cpu_usage > $CPU_THRESHOLD" | bc -l) )); then
    echo -e "${RED}CPU threshold breached! ${current_cpu_usage}% > ${CPU_THRESHOLD}%${NC}"
    export THRESHOLD_TYPE="CPU" CURRENT_VALUE="${current_cpu_usage%.*}"
    send_discord_alert "🚨 CPU threshold breached on $(hostname): ${CURRENT_VALUE}%"
fi

# Memory Check
if (( $(echo "$current_mem_usage > $MEM_THRESHOLD" | bc -l) )); then
    echo -e "${RED}Memory threshold breached! ${current_mem_usage}% > ${MEM_THRESHOLD}%${NC}"
    export THRESHOLD_TYPE="RAM" CURRENT_VALUE="${current_mem_usage%.*}"
    send_discord_alert "🚨 RAM threshold breached on $(hostname): ${CURRENT_VALUE}%"
fi

# Disk Check (using root partition)
root_disk_usage=$(df -h / | awk 'NR==2 {print $5}' | tr -d '%')
if [ -n "$root_disk_usage" ] && [ "$root_disk_usage" -gt "$DISK_THRESHOLD" ]; then
    echo -e "${RED}Disk threshold breached! ${root_disk_usage}% > ${DISK_THRESHOLD}%${NC}"
    export THRESHOLD_TYPE="DISK" CURRENT_VALUE="$root_disk_usage"
    send_discord_alert "🚨 Disk usage threshold breached on $(hostname): ${CURRENT_VALUE}%"
fi

# Swap Check
if [ "$(free | grep Swap | awk '{print $2}')" -ne 0 ]; then  # Only if swap exists
    swap_usage=$(free | grep Swap | awk '{print $3/$2 * 100}')
    if (( $(echo "$swap_usage > $SWAP_THRESHOLD" | bc -l) )); then
        echo -e "${RED}Swap threshold breached! ${swap_usage%.*}% > ${SWAP_THRESHOLD}%${NC}"
        export THRESHOLD_TYPE="SWAP" CURRENT_VALUE="${swap_usage%.*}"
        send_discord_alert "🚨 Swap usage threshold breached on $(hostname): ${CURRENT_VALUE}%"
    fi
fi
