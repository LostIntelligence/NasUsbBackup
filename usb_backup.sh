#!/bin/bash
set -euo pipefail
# CONFIGURATION
USB_DEVICE=$(blkid -t UUID="3C91-F720" -o device)                # Adjust UUID if needed
MOUNT_POINT="/mnt/usbbackup"
BACKUP_DIR="$MOUNT_POINT/truenasp1"
TIMESTAMP=$(date +%Y%m%d%H%M%S)
BACKUP_FILE="$BACKUP_DIR/hostname-$TIMESTAMP.tar"
SOURCE_DIR="/data"
FILES_TO_BACKUP=(freenas-v1.db pwenc_secret)
LOG_FILE="/var/log/usb_backup.log"

# Ensure log file exists
touch "$LOG_FILE"
log() {
    printf '[%s] %s\n' "$(date)" "$*" >> "$LOG_FILE"
}

trap 'status=$?; log "Command failed with exit status $status at line $LINENO: $BASH_COMMAND"' ERR

log "Starting USB backup..."
log "Current device is $USB_DEVICE"

# Check if device exists
if [ ! -b "$USB_DEVICE" ]; then
    log "Device $USB_DEVICE not found. Aborting."
    exit 1
fi

# Check if device is a USB stick
if ! udevadm info --query=property --name="$USB_DEVICE" | grep -q "ID_BUS=usb"; then
    log "Device $USB_DEVICE is not a USB device. Aborting."
    exit 1
fi

# Create mount point if needed
mkdir -p "$MOUNT_POINT"

# Mount if not already mounted
if ! mountpoint -q "$MOUNT_POINT"; then
    if mount -t auto "$USB_DEVICE" "$MOUNT_POINT"; then
        log "Mounted $USB_DEVICE at $MOUNT_POINT."
    else
        status=$?
        log "Failed to mount $USB_DEVICE at $MOUNT_POINT (exit status $status)."
        exit "$status"
    fi
else
    log "USB already mounted at $MOUNT_POINT."
fi

# Create backup directory if needed
mkdir -p "$BACKUP_DIR"

# Run the backup
if tar cf "$BACKUP_FILE" -C "$SOURCE_DIR" "${FILES_TO_BACKUP[@]}"; then
    log "Backup successful: $BACKUP_FILE"
else
    status=$?
    log "Backup failed (tar exit status $status)."
    exit "$status"
fi

# Optional: Unmount USB after backup
# umount "$MOUNT_POINT"

log "Backup script completed."
exit 0
