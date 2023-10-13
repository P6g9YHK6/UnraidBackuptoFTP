#!/bin/bash
echo "START OF SCRIPT"

# Variables
USB_MOUNT_POINT="/boot" # USB mount point
FTP_SERVER="192.168.1.1" # FTP server
FTP_USER="ftpuser" # FTP username
FTP_PASSWORD="password" # FTP password
FTP_DIR="/Datastore/asdfasdf" # FTP directory
STATUS_API="https://exemple.com/api/push/TOEKN" # Gotify Push notification link
STATUS_FILE="/tmp/backup_status.txt" # File to store the status of the last backup

# Get the current date and time
DATE=$(date +%Y%m%d_%H%M%S)

echo "Creating a tarball of the USB stick..."

# Start timer
START_TIME=$(date +%s)

# Check if the status file exists and send a signal to the status API
if [ -f "${STATUS_FILE}" ]; then
    LAST_STATUS=$(cat ${STATUS_FILE})
    curl "${STATUS_API}?status=${LAST_STATUS}&msg=Start%20backup"
else
    curl "${STATUS_API}?status=down&msg=Start%20backup%20MissingLastStatus"
fi

# Create a tarball of the USB stick
tar -czf /tmp/${DATE}.tar.gz -C ${USB_MOUNT_POINT} .

echo "Uploading the tarball to the FTP server..."

# Upload the tarball to the FTP server
curl -T "/tmp/${DATE}.tar.gz" "ftp://${FTP_USER}:${FTP_PASSWORD}@${FTP_SERVER}${FTP_DIR}/"

echo "Removing the local tarball..."

# Remove the local tarball
rm /tmp/${DATE}.tar.gz

echo "Checking the number of backups..."

# Delete old backups if there are more than 8
BACKUPS=$(curl -u ${FTP_USER}:${FTP_PASSWORD} ftp://${FTP_SERVER}${FTP_DIR}/ | wc -l)
OLDEST=""
while [ ${BACKUPS} -gt 8 ]
do
    echo "Deleting the oldest backup..."
    OLDEST=$(curl -u ${FTP_USER}:${FTP_PASSWORD} ftp://${FTP_SERVER}${FTP_DIR}/ | awk '{print $9}' | head -n 1)
    curl -u ${FTP_USER}:${FTP_PASSWORD} ftp://${FTP_SERVER}${FTP_DIR}/ -Q "-DELE ${OLDEST}"
    BACKUPS=$(curl -u ${FTP_USER}:${FTP_PASSWORD} ftp://${FTP_SERVER}${FTP_DIR}/ | wc -l)
done

# End timer
END_TIME=$(date +%s)

# Calculate duration
DURATION=$((END_TIME - START_TIME))

# Check if curl was successful
if [ $? -eq 0 ]; then
   echo "Backup completed successfully."
   echo "up" > ${STATUS_FILE}
   curl "${STATUS_API}?status=up&msg=Backup%20completed%20successfully&ping=${DURATION}"
else
   echo "Backup failed. Check the output above for details."
   echo "down" > ${STATUS_FILE}
   curl "${STATUS_API}?status=down&msg=Backup%20failed.%20Check%20the%20output%20above%20for%20details.&ping=${DURATION}"
   exit 1
fi

# Verify the backup
echo "Verifying the backup..."

# Download the backup
curl -o "/tmp/${DATE}.tar.gz" "ftp://${FTP_USER}:${FTP_PASSWORD}@${FTP_SERVER}${FTP_DIR}/${DATE}.tar.gz"

# Extract the backup
mkdir -p /tmp/boot && tar -xzf "/tmp/${DATE}.tar.gz" -C /tmp/boot/

# Compare the files
diff -r ${USB_MOUNT_POINT} /tmp${USB_MOUNT_POINT} > /dev/null

if [ $? -eq 0 ]; then
   echo "Verification successful. All files are backed up."
else
   echo "Verification failed. Not all files are backed up."
   echo "down" > ${STATUS_FILE}
   curl "${STATUS_API}?status=down&msg=Verification%20failed.%20Not%20all%20files%20are%20backed%20up.&ping=${DURATION}"
fi

# Clean up
rm "/tmp/${DATE}.tar.gz"
rm -r /tmp/boot
echo "END OF SCRIPT"
