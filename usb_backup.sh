#!/bin/bash
set -euo pipefail
# CONFIGURATION
USB_DEVICE=$(blkid -t UUID="3C91-F720" -o device)                # Adjust UUID if needed
MOUNT_POINT="/mnt/usbbackup"
BACKUP_DIR="$MOUNT_POINT/truenasp1"
TIMESTAMP=$(date +%Y%m%d%H%M%S)
BACKUP_FILE="$BACKUP_DIR/hostname-$TIMESTAMP.tar"
SOURCE_DIR="/data"
FILES_TO_BACKUP="freenas-v1.db pwenc_secret"
LOG_FILE="/var/log/usb_backup.log"

# Ensure log file exists
touch "$LOG_FILE"
echo "[$(date)] Starting USB backup..." >> "$LOG_FILE"
echo "[$(date)] Current device is $USB_DEVICE" >> "$LOG_FILE"

# Check if device exists
if [ ! -b "$USB_DEVICE" ]; then
    echo "[$(date)] Device $USB_DEVICE not found. Aborting." >> "$LOG_FILE"
    exit 1
fi

# Check if device is a USB stick
USB_PARENT=$(basename "$(dirname "$(readlink -f /sys/class/block/$(basename $USB_DEVICE))")")
if ! udevadm info --query=property --name="$USB_DEVICE" | grep -q "ID_BUS=usb"; then
    echo "[$(date)] Device $USB_DEVICE is not a USB device. Aborting." >> "$LOG_FILE"
    exit 1
fi

# Create mount point if needed
mkdir -p "$MOUNT_POINT"

# Mount if not already mounted
if ! mount | grep -q "$MOUNT_POINT"; then
    mount -t auto "$USB_DEVICE" "$MOUNT_POINT"
    if [ $? -ne 0 ]; then
        echo "[$(date)] Failed to mount $USB_DEVICE at $MOUNT_POINT." >> "$LOG_FILE"
        exit 1
    fi
    echo "[$(date)] Mounted $USB_DEVICE at $MOUNT_POINT." >> "$LOG_FILE"
else
    echo "[$(date)] USB already mounted at $MOUNT_POINT." >> "$LOG_FILE"
fi

# Create backup directory if needed
mkdir -p "$BACKUP_DIR"

# Run the backup
tar cf "$BACKUP_FILE" -C "$SOURCE_DIR" $FILES_TO_BACKUP
if [ $? -eq 0 ]; then
    echo "[$(date)] Backup successful: $BACKUP_FILE" >> "$LOG_FILE"
else
    echo "[$(date)] Backup failed." >> "$LOG_FILE"
    exit 1
fi

# Optional: Unmount USB after backup
# umount "$MOUNT_POINT"

echo "[$(date)] Backup script completed." >> "$LOG_FILE"
exit 0
