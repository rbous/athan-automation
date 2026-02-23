#!/bin/bash

# Configuration
API_URL="https://api.mrie.dev/prayertimes/aylmer-mosque-gatineau-j9h-4j6-canada"
GOOGLE_HOME_NAME="Home mini"
FAJR_ATHAN_URL="http://www.smartazan.com/data/media/Fajar.mp3"
REGULAR_ATHAN_URL="http://www.smartazan.com/data/media/Azan.mp3"
LOG_FILE="$HOME/athan-automation/athan.log"

# Create log file if it doesn't exist
mkdir -p "$(dirname "$LOG_FILE")"
touch "$LOG_FILE"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Get current date
DAY=$(date +%-d)
MONTH=$(date +%-m)

log "Fetching prayer times for $DAY/$MONTH"

# Fetch prayer times
RESPONSE=$(curl -s "$API_URL/$DAY/$MONTH")

if [ $? -ne 0 ] || [ -z "$RESPONSE" ]; then
    log "ERROR: Failed to fetch prayer times"
    exit 1
fi

log "API Response: $RESPONSE"

# Parse prayer times using jq
FAJR=$(echo "$RESPONSE" | jq -r '.fajr' | cut -d'T' -f2 | cut -d':' -f1,2)
DHUHR=$(echo "$RESPONSE" | jq -r '.dhuhr' | cut -d'T' -f2 | cut -d':' -f1,2)
ASR=$(echo "$RESPONSE" | jq -r '.asr' | cut -d'T' -f2 | cut -d':' -f1,2)
MAGHREB=$(echo "$RESPONSE" | jq -r '.maghreb' | cut -d'T' -f2 | cut -d':' -f1,2)
ISHA=$(echo "$RESPONSE" | jq -r '.isha' | cut -d'T' -f2 | cut -d':' -f1,2)

log "Prayer times: Fajr:$FAJR Dhuhr:$DHUHR Asr:$ASR Maghreb:$MAGHREB Isha:$ISHA"

# Create temporary crontab file
TEMP_CRON=$(mktemp)

# Keep existing cron jobs (excluding old athan jobs)
crontab -l 2>/dev/null | grep -v "# ATHAN" > "$TEMP_CRON"

# Add new athan jobs with different URLs for Fajr
cat >> "$TEMP_CRON" << EOF
# ATHAN AUTOMATION - Generated $(date)
$(echo "$FAJR" | awk -F: '{print $2 " " $1}') * * * /home/rayane/athan-automation/play-athan.sh "Fajr" "$FAJR_ATHAN_URL" # ATHAN
$(echo "$DHUHR" | awk -F: '{print $2 " " $1}') * * * /home/rayane/athan-automation/play-athan.sh "Dhuhr" "$REGULAR_ATHAN_URL" # ATHAN
$(echo "$ASR" | awk -F: '{print $2 " " $1}') * * * /home/rayane/athan-automation/play-athan.sh "Asr" "$REGULAR_ATHAN_URL" # ATHAN
$(echo "$MAGHREB" | awk -F: '{print $2 " " $1}') * * * /home/rayane/athan-automation/play-athan.sh "Maghreb" "$REGULAR_ATHAN_URL" # ATHAN
$(echo "$ISHA" | awk -F: '{print $2 " " $1}') * * * /home/rayane/athan-automation/play-athan.sh "Isha" "$REGULAR_ATHAN_URL" # ATHAN
EOF

# Install new crontab
crontab "$TEMP_CRON"
rm "$TEMP_CRON"

log "Crontab updated successfully"
