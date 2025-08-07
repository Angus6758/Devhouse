#!/bin/bash

  

# System Monitoring Alert Script

# Sends email alerts when resource thresholds are breached

  

# Color definitions for output

RED='\033[0;31m'

GREEN='\033[0;32m'

YELLOW='\033[0;33m'

NC='\033[0m' # No Color

  

# Configuration variables

CONFIG_FILE="$(dirname "$0")/.env"

LOG_DIR="$(dirname "$0")/system_monitor_logs"

MAIL_LOG="$LOG_DIR/mail.log"

TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

  

# Initialize dry run mode flag

DRY_RUN=false

  

# Parse command-line arguments

for arg in "$@"; do

    case $arg in

        --test)

        DRY_RUN=true

        shift

        ;;

        *)

        echo -e "${YELLOW}Unknown option: $arg${NC}"

        exit 1

        ;;

    esac

done

  

# Create log directory if missing

mkdir -p "$LOG_DIR"

  

# Logging function

log_event() {

    local log_entry="[$TIMESTAMP] $1"

    echo -e "$log_entry" >> "$MAIL_LOG"

    echo -e "$log_entry"  # Also print to terminal

}

  

# Validate required commands

if ! command -v mail &> /dev/null && ! $DRY_RUN; then

    echo -e "${RED}Error: 'mail' command not found. Install with:"

    echo -e "sudo apt install mailutils${NC}"

    log_event "ERROR: 'mail' command not found"

    exit 1

fi

  

# Check if .env file exists

if [ ! -f "$CONFIG_FILE" ]; then

    echo -e "${RED}Error: Configuration file (.env) not found${NC}"

    log_event "ERROR: Configuration file (.env) not found"

    exit 1

fi

  

# Load environment variables

source "$CONFIG_FILE"

  

# Validate required variables

MISSING_VARS=()

[ -z "$ALERT_EMAIL" ] && MISSING_VARS+=("ALERT_EMAIL")

[ -z "$SERVICE_NAME" ] && MISSING_VARS+=("SERVICE_NAME")

[ -z "$THRESHOLD_TYPE" ] && MISSING_VARS+=("THRESHOLD_TYPE")

[ -z "$CURRENT_VALUE" ] && MISSING_VARS+=("CURRENT_VALUE")

  

if [ ${#MISSING_VARS[@]} -gt 0 ]; then

    echo -e "${RED}Error: Missing required variables in .env:"

    printf ' - %s\n' "${MISSING_VARS[@]}"

    echo -e "${NC}"

    log_event "ERROR: Missing variables: ${MISSING_VARS[*]}"

    exit 1

fi

  

# Set hostname (fallback to system hostname)

HOSTNAME="${HOSTNAME:-$(hostname)}"

  

# Construct email content

SUBJECT="ALERT: $SERVICE_NAME - ${THRESHOLD_TYPE} Threshold Breached on $HOSTNAME"

  

BODY=$(cat <<EOF

SYSTEM MONITORING ALERT

  

Hostname:      $HOSTNAME

Service:       $SERVICE_NAME

Alert Type:    ${THRESHOLD_TYPE} Threshold Breached

Current Value: $CURRENT_VALUE%

Timestamp:     $TIMESTAMP

  

ACTION REQUIRED:

Please investigate the resource usage immediately. 

Consider scaling resources or optimizing workloads.

  

-- 

Monitoring System

$(hostname)

EOF

)

  

# Handle dry run mode

if $DRY_RUN; then

    echo -e "${YELLOW}"

    echo "===== DRY RUN - EMAIL WOULD BE SENT ====="

    echo -e "${GREEN}To:${NC} $ALERT_EMAIL"

    echo -e "${GREEN}Subject:${NC} $SUBJECT"

    echo -e "${GREEN}Body:${NC}\n$BODY"

    echo -e "${YELLOW}===================================${NC}"

    log_event "DRY RUN: Alert prepared for $THRESHOLD_TYPE breach ($CURRENT_VALUE%)"

    exit 0

fi

  

# Send actual email

echo -e "$BODY" | mail -s "$SUBJECT" "$ALERT_EMAIL"

  

# Verify send status

if [ $? -eq 0 ]; then

    echo -e "${GREEN}Alert email sent successfully to $ALERT_EMAIL${NC}"

    log_event "SENT: $THRESHOLD_TYPE alert ($CURRENT_VALUE%) to $ALERT_EMAIL"

else

    echo -e "${RED}Error: Failed to send alert email${NC}"

    log_event "FAILED: $THRESHOLD_TYPE alert ($CURRENT_VALUE%) to $ALERT_EMAIL"

    exit 1

fi
