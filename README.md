# NasUsbBackup

A small backup script for copying a couple of critical files from a TrueNAS/FreeNAS-style data directory onto a USB drive.

## What it does

The script:

- looks up the USB device by its filesystem UUID
- verifies the device is a real USB block device
- mounts the USB drive at `/mnt/usbbackup` if it is not already mounted
- creates a backup directory at `/mnt/usbbackup/truenasp1`
- creates a tar archive named like `hostname-YYYYMMDDHHMMSS.tar`
- backs up these files from `/data`:
  - `freenas-v1.db`
  - `pwenc_secret`
- writes status and failure messages to `/var/log/usb_backup.log`

## Current configuration

The script is configured with the following defaults:

- `USB_DEVICE=$(blkid -t UUID="3C91-F720" -o device)`
- `MOUNT_POINT="/mnt/usbbackup"`
- `BACKUP_DIR="$MOUNT_POINT/truenasp1"`
- `SOURCE_DIR="/data"`
- `FILES_TO_BACKUP=(freenas-v1.db pwenc_secret)`
- `LOG_FILE="/var/log/usb_backup.log"`

If your USB drive uses a different UUID, update the `blkid` lookup near the top of the script before running it.

## Run it

```bash
chmod +x usb_backup.sh
sudo ./usb_backup.sh
```

## Notes

- The script exits immediately if the USB device is missing or is not recognized as a USB drive.
- It uses `set -euo pipefail` so shell errors stop execution.
- The USB is left mounted by default after a successful backup; uncomment the unmount line if you want it automatically unmounted afterward.
- For best operation, run it regularly via cron, ideally daily or at least monthly, to keep backups current.

## Recommended cron usage

On some TrueNAS systems, Bash is not available on the default PATH used by cron, so it is safest to call Bash explicitly.

A simple crontab entry can run the backup once a day:

```cron
0 2 * * * /usr/local/bin/bash /home/root/Projects/NasUsbBackup/usb_backup.sh
```

If your system uses a different Bash location, replace `/usr/local/bin/bash` with the actual path, for example:

```cron
0 2 * * * /bin/bash /home/admin/usb_backup.sh
```

> Replace the path with the actual location of the script on your system, and make sure it has execute permissions.

## Example output path

A backup archive is created in a structure like this:

```text
/mnt/usbbackup/truenasp1/hostname-20261116123045.tar
```