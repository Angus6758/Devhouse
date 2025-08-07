#!/bin/bash

# Advanced Monitoring Setup Script
# Configures system monitoring with Discord webhook notifications

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to validate URL format
validate_webhook() {
    local discord_regex='^https://discord\.com/api/webhooks/[0-9]+/[a-zA-Z0-9_-]+$'
    [[ "$1" =~ $discord_regex ]]
}

# Function to validate percentage
validate_percentage() {
    [[ "$1" =~ ^[0-9]+$ ]] && [ "$1" -ge 1 ] && [ "$1" -le 100 ]
}

# Function to validate cron interval
validate_cron_interval() {
    [[ "$1" =~ ^[0-9]+$ ]] && [ "$1" -ge 1 ]
}

# Display header
echo -e "${GREEN}"
echo "╔══════════════════════════════════════════════════╗"
echo "║       DISCORD MONITORING SETUP SCRIPT           ║"
echo "╚══════════════════════════════════════════════════╝"
echo -e "${NC}"

# 1. Check if monitor.sh exists
if [ ! -f "monitor.sh" ]; then
    echo -e "${RED}Error: monitor.sh not found in current directory${NC}"
    exit 1
fi

# 2. Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${YELLOW}Warning: Not running as root. Cron jobs will be installed for current user."
    echo -e "Some monitoring features might require root privileges.${NC}\n"
fi

# 3. Prompt user for configuration
echo -e "${BLUE}Please enter monitoring configuration:${NC}"

# Discord webhook validation
while true; do
    echo -e "\n${YELLOW}Create a Discord webhook:"
    echo -e "1. Go to your Discord server settings"
    echo -e "2. Select 'Integrations' → 'Webhooks' → 'New Webhook'"
    echo -e "3. Copy the webhook URL${NC}"
    read -r -p "Enter Discord webhook URL: " DISCORD_WEBHOOK
    
    if validate_webhook "$DISCORD_WEBHOOK"; then
        # Test the webhook
        echo -e "${BLUE}Testing webhook...${NC}"
        response=$(curl -sS -H "Content-Type: application/json" -X POST -d '{"content":"🚀 Monitoring system successfully configured!"}' "$DISCORD_WEBHOOK")
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}Webhook test successful!${NC}"
            break
        else
            echo -e "${RED}Webhook test failed. Please check your URL and try again.${NC}"
        fi
    else
        echo -e "${RED}Invalid webhook URL format. Please try again.${NC}"
    fi
done

# Service name
read -r -p "Name for this service/machine: " SERVICE_NAME

# Threshold validations
while true; do
    read -r -p "CPU usage threshold (% 1-100): " CPU_THRESHOLD
    if validate_percentage "$CPU_THRESHOLD"; then
        break
    else
        echo -e "${RED}Invalid percentage. Enter a number between 1-100.${NC}"
    fi
done

while true; do
    read -r -p "Memory usage threshold (% 1-100): " MEM_THRESHOLD
    if validate_percentage "$MEM_THRESHOLD"; then
        break
    else
        echo -e "${RED}Invalid percentage. Enter a number between 1-100.${NC}"
    fi
done

while true; do
    read -r -p "Disk usage threshold (% 1-100): " DISK_THRESHOLD
    if validate_percentage "$DISK_THRESHOLD"; then
        break
    else
        echo -e "${RED}Invalid percentage. Enter a number between 1-100.${NC}"
    fi
done

while true; do
    read -r -p "Swap usage threshold (% 1-100): " SWAP_THRESHOLD
    if validate_percentage "$SWAP_THRESHOLD"; then
        break
    else
        echo -e "${RED}Invalid percentage. Enter a number between 1-100.${NC}"
    fi
done

# Cron interval validation
while true; do
    echo -e "\n${BLUE}Cron interval options:${NC}"
    echo "1. Every 5 minutes"
    echo "2. Every 10 minutes"
    echo "3. Every 15 minutes"
    echo "4. Every 30 minutes"
    echo "5. Every hour"
    echo "6. Custom"
    read -r -p "Select option (1-6): " CRON_OPTION

    case $CRON_OPTION in
        1) CRON_INTERVAL="*/5 * * * *"; break ;;
        2) CRON_INTERVAL="*/10 * * * *"; break ;;
        3) CRON_INTERVAL="*/15 * * * *"; break ;;
        4) CRON_INTERVAL="*/30 * * * *"; break ;;
        5) CRON_INTERVAL="0 * * * *"; break ;;
        6)
            echo -e "\n${YELLOW}Enter custom cron pattern (e.g., '*/7 * * * *' for every 7 minutes)${NC}"
            echo "Format: [minute] [hour] [day of month] [month] [day of week]"
            read -r -p "Cron pattern: " CRON_INTERVAL
            if [ $(echo "$CRON_INTERVAL" | wc -w) -eq 5 ]; then
                break
            else
                echo -e "${RED}Invalid cron pattern. Must contain 5 time fields.${NC}"
            fi
            ;;
        *) echo -e "${RED}Invalid option. Please select 1-6.${NC}" ;;
    esac
done

# Create/update .env file
echo -e "\n${BLUE}Creating configuration file...${NC}"
CONFIG_FILE=".env"

if [ -f "$CONFIG_FILE" ]; then
    echo -e "${YELLOW}Configuration file (.env) already exists.${NC}"
    read -r -p "Overwrite? (y/n): " OVERWRITE
    if [[ ! "$OVERWRITE" =~ ^[Yy] ]]; then
        echo -e "${RED}Setup aborted. Configuration not changed.${NC}"
        exit 0
    fi
fi

# Write configuration
cat > "$CONFIG_FILE" <<EOL
DISCORD_WEBHOOK="$DISCORD_WEBHOOK"
SERVICE_NAME="$SERVICE_NAME"
HOSTNAME="$(hostname)"
CPU_THRESHOLD="$CPU_THRESHOLD"
MEM_THRESHOLD="$MEM_THRESHOLD"
DISK_THRESHOLD="$DISK_THRESHOLD"
SWAP_THRESHOLD="$SWAP_THRESHOLD"
CRON_INTERVAL="$CRON_INTERVAL"
EOL

echo -e "${GREEN}Configuration saved to $CONFIG_FILE${NC}"

# Make monitor.sh executable
echo -e "\n${BLUE}Setting up monitor.sh...${NC}"
chmod +x monitor.sh
echo -e "${GREEN}monitor.sh made executable${NC}"

# Setup cron job
echo -e "\n${BLUE}Configuring cron job...${NC}"
CRON_JOB="$CRON_INTERVAL $(pwd)/monitor.sh >> $(pwd)/monitor.log 2>&1"
TEMP_CRON=$(mktemp)

# Preserve existing cron jobs
crontab -l > "$TEMP_CRON" 2>/dev/null

# Remove existing jobs for this script
sed -i "\|$(pwd)/monitor.sh|d" "$TEMP_CRON"

# Add new job
echo "$CRON_JOB" >> "$TEMP_CRON"

# Install new cron file
crontab "$TEMP_CRON"
rm "$TEMP_CRON"

# Success message
echo -e "${GREEN}"
echo "╔══════════════════════════════════════════════════╗"
echo "║          SETUP COMPLETED SUCCESSFULLY!           ║"
echo "╚══════════════════════════════════════════════════╝"
echo -e "${NC}"
echo -e "📢 ${BLUE}Alerts will be sent to Discord${NC}"
echo -e "🖥️  ${BLUE}Monitoring service: ${YELLOW}$SERVICE_NAME${NC}"
echo -e "⏱️  ${BLUE}Monitoring frequency:${NC} $CRON_INTERVAL"
echo -e "📊 ${BLUE}Threshold configuration:${NC}"
echo -e "   - CPU: ${YELLOW}$CPU_THRESHOLD%${NC}"
echo -e "   - Memory: ${YELLOW}$MEM_THRESHOLD%${NC}"
echo -e "   - Disk: ${YELLOW}$DISK_THRESHOLD%${NC}"
echo -e "   - Swap: ${YELLOW}$SWAP_THRESHOLD%${NC}"
echo -e "\n${BLUE}Log file location:${NC} $(pwd)/monitor.log"
echo -e "\n${GREEN}System monitoring is now active!${NC}"

# Immediate actions
echo -e "\n${YELLOW}=== IMMEDIATE ACTIONS ===${NC}"

# Run monitor now
read -p "$(echo -e ${YELLOW}"Run monitor.sh now for initial system check? (y/n): "${NC})" RUN_NOW
if [[ "$RUN_NOW" =~ ^[Yy]$ ]]; then
    echo -e "${GREEN}Executing monitor.sh...${NC}"
    ./monitor.sh
    echo -e "${GREEN}Initial check completed!${NC}"
fi

# Backup .env file
read -p "$(echo -e ${YELLOW}"Backup current .env configuration? (y/n): "${NC})" BACKUP_ENV
if [[ "$BACKUP_ENV" =~ ^[Yy]$ ]]; then
    BACKUP_DIR="system_monitor_logs"
    mkdir -p "$BACKUP_DIR"
    BACKUP_FILE="${BACKUP_DIR}/env_backup_$(date +%Y%m%d_%H%M%S).conf"
    cp .env "$BACKUP_FILE"
    echo -e "${GREEN}Configuration backed up to: ${YELLOW}$BACKUP_FILE${NC}"
fi

echo -e "\n${GREEN}Setup process completed!${NC}"
