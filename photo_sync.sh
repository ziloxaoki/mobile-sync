#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

# ---------------- CONFIG ----------------
WIFI_SUBSTRING="${1:-KAC}"
SOURCE_DIR="$HOME/storage/dcim/Camera"
SYNCED_DIR="$HOME/storage/dcim/Synced"
RCLONE_REMOTE="truenas:uploads"
LOG_FILE="$HOME/photo_sync.log"
DEVICE_ID=$(getprop ro.product.model | tr ' ' '_')

# -------------- LOGGING -----------------
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# --------- GET CURRENT WIFI SSID --------
get_ssid() {
    if command -v termux-wifi-connectioninfo >/dev/null 2>&1; then
        termux-wifi-connectioninfo | grep -o '"ssid":[^,]*' | cut -d':' -f2 | tr -d '" '
    else
        dumpsys wifi 2>/dev/null | grep -m1 "SSID" | awk -F= '{print $2}' | tr -d '" '
    fi
}

SSID=$(get_ssid || echo "")
log "Detected SSID: $SSID"

SSID_LOWER=$(echo "$SSID" | tr '[:upper:]' '[:lower:]')
MATCH_LOWER=$(echo "$WIFI_SUBSTRING" | tr '[:upper:]' '[:lower:]')

if [[ -z "$SSID" || "$SSID_LOWER" != *"$MATCH_LOWER"* ]]; then
    log "Wi-Fi does not match '$WIFI_SUBSTRING'. Skipping sync."
    exit 0
fi

log "Wi-Fi matches. Starting sync..."

# ----------- PREPARE DIRECTORIES --------
mkdir -p "$SYNCED_DIR"

if [ ! -d "$SOURCE_DIR" ]; then
    log "Source directory not found: $SOURCE_DIR"
    exit 1
fi

# ----------- DEBUG COUNT ----------------
FILE_COUNT=$(find "$SOURCE_DIR" -type f \( \
-iname "*.jpg" -o \
-iname "*.jpeg" -o \
-iname "*.png" -o \
-iname "*.heic" -o \
-iname "*.mp4" -o \
-iname "*.mov" -o \
-iname "*.avi" -o \
-iname "*.mkv" \
\) | wc -l)

log "Files found: $FILE_COUNT"

# ----------- PROCESS FILES --------------
while IFS= read -r file; do
    BASENAME=$(basename "$file")

    # Extract date from file (fallback to today)
    FILE_DATE=$(date -r "$file" +"%Y/%m" 2>/dev/null || date +"%Y/%m")
    DEST_PATH="$RCLONE_REMOTE/$DEVICE_ID/$FILE_DATE"

    log "Processing: $BASENAME"
    log "Uploading to: $DEST_PATH"

    # -------- UPLOAD (with timeout protection) --------
    if ! timeout 600 rclone copy "$file" "$DEST_PATH" --create-empty-src-dirs; then
        log "Upload failed or timed out: $BASENAME"
        continue
    fi

    # -------- VALIDATION --------
    if ! rclone check "$file" "$DEST_PATH" --size-only --one-way; then
        log "Verification failed: $BASENAME"
        continue
    fi

    log "Verification successful: $BASENAME"

    # -------- MOVE FILE (safe rename) --------
    mv "$file" "$SYNCED_DIR/$(date +%s)_$BASENAME"
    log "Moved to Synced: $BASENAME"

done < <(find "$SOURCE_DIR" -type f \( \
-iname "*.jpg" -o \
-iname "*.jpeg" -o \
-iname "*.png" -o \
-iname "*.heic" -o \
-iname "*.mp4" -o \
-iname "*.mov" -o \
-iname "*.avi" -o \
-iname "*.mkv" \
\))

log "Sync cycle completed."