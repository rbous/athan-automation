#!/bin/bash

PRAYER_NAME="$1"
ATHAN_URL="$2"
GOOGLE_HOME_NAME="Home mini"
GOOGLE_HOME_IP="192.168.2.16"
LOG_FILE="$HOME/athan-automation/athan.log"
MAX_RETRIES=3
RETRY_DELAY=30  # seconds

# Volume settings
FAJR_VOLUME=70
OTHER_VOLUME=40

# Default URLs if not provided
if [ -z "$ATHAN_URL" ]; then
    if [ "$PRAYER_NAME" == "Fajr" ]; then
        ATHAN_URL="http://www.smartazan.com/data/media/Fajar.mp3"
    else
        ATHAN_URL="http://www.smartazan.com/data/media/Azan.mp3"
    fi
fi

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Function to execute catt command with fallback
catt_with_fallback() {
    local command="$1"
    shift
    local args="$@"
    
    # Try device name first
    if catt -d "$GOOGLE_HOME_NAME" $command $args 2>/dev/null; then
        return 0
    else
        # Try IP address as fallback
        if catt -d "$GOOGLE_HOME_IP" $command $args 2>/dev/null; then
            return 0
        else
            return 1
        fi
    fi
}

# Function to check if device is available
check_device() {
    catt scan | grep -q -E "(Home mini|192\.168\.2\.16)"
    return $?
}

# Ensure PATH includes pipx binaries
export PATH="$HOME/.local/bin:$PATH"

log "Starting athan for $PRAYER_NAME prayer"

# Get current volume from status with retries
ORIGINAL_VOLUME=""
for i in $(seq 1 $MAX_RETRIES); do
    STATUS_OUTPUT=$(catt_with_fallback status)
    if [ $? -eq 0 ] && [ -n "$STATUS_OUTPUT" ]; then
        ORIGINAL_VOLUME=$(echo "$STATUS_OUTPUT" | grep "^Volume:" | grep -oE '[0-9]+')
        if [ -n "$ORIGINAL_VOLUME" ]; then
            log "Current volume: $ORIGINAL_VOLUME%"
            break
        fi
    fi
    
    if [ $i -lt $MAX_RETRIES ]; then
        log "Attempt $i/$MAX_RETRIES: Could not get volume, retrying in $RETRY_DELAY seconds..."
        sleep $RETRY_DELAY
    fi
done

if [ -z "$ORIGINAL_VOLUME" ]; then
    log "WARNING: Could not get current volume after $MAX_RETRIES attempts, assuming 50%"
    ORIGINAL_VOLUME=50
fi

# Set athan volume based on prayer
if [ "$PRAYER_NAME" == "Fajr" ]; then
    ATHAN_VOLUME=$FAJR_VOLUME
    log "Setting Fajr volume to $FAJR_VOLUME%"
else
    ATHAN_VOLUME=$OTHER_VOLUME
    log "Setting volume to $OTHER_VOLUME% for $PRAYER_NAME"
fi

# Main athan playback with retries
for i in $(seq 1 $MAX_RETRIES); do
    log "Attempt $i/$MAX_RETRIES: Playing athan for $PRAYER_NAME"
    
    # Check if device is available first
    if ! check_device; then
        log "WARNING: Device not found in scan"
        if [ $i -eq $MAX_RETRIES ]; then
            log "CRITICAL: Device not available after $MAX_RETRIES attempts"
            exit 1
        fi
        log "Waiting $RETRY_DELAY seconds before retry..."
        sleep $RETRY_DELAY
        continue
    fi
    
    # Set volume for athan
    if catt_with_fallback volume "$ATHAN_VOLUME"; then
        log "Volume set to $ATHAN_VOLUME%"
    else
        log "WARNING: Failed to set volume (attempt $i/$MAX_RETRIES)"
    fi
    
    # Try to cast the athan
    if catt_with_fallback cast "$ATHAN_URL"; then
        log "SUCCESS: Athan started playing for $PRAYER_NAME"
        
        # Wait for athan to finish (3 minutes based on duration)
        log "Waiting for athan to complete..."
        sleep 180  # 3 minutes
        
        # Restore original volume
        log "Restoring volume to $ORIGINAL_VOLUME%"
        if catt_with_fallback volume "$ORIGINAL_VOLUME"; then
            log "Volume restored to $ORIGINAL_VOLUME%"
        else
            log "WARNING: Failed to restore original volume"
        fi
        
        log "Athan session completed successfully for $PRAYER_NAME"
        exit 0
        
    else
        log "ERROR: Failed to cast athan (attempt $i/$MAX_RETRIES)"
        if [ $i -eq $MAX_RETRIES ]; then
            log "CRITICAL: All attempts failed for $PRAYER_NAME athan"
            # Still try to restore volume even if athan failed
            log "Attempting to restore volume to $ORIGINAL_VOLUME%"
            catt_with_fallback volume "$ORIGINAL_VOLUME"
            exit 1
        fi
        log "Waiting $RETRY_DELAY seconds before retry..."
        sleep $RETRY_DELAY
    fi
done
