#!/bin/bash

# Retrieve parameters from Docker environment variables
S3_BUCKET=${S3_BUCKET}
LOCAL_DIR=${LOCAL_DIR}
STORAGE_CLASS=${STORAGE_CLASS:-DEEP_ARCHIVE}
EMAIL_FROM=${EMAIL_FROM}
EMAIL_TO=${EMAIL_TO}
EMAIL_SUBJECT="S3 Backup Status - $(date '+%Y-%m-%d %H:%M:%S')"

LOG_FILE="/backup/backup_log.txt"

# Ensure log file exists
touch "$LOG_FILE"

# Start backup
echo "Backup started at $(date '+%Y-%m-%d %H:%M:%S')" >> "$LOG_FILE"
if aws s3 sync "$LOCAL_DIR" "$S3_BUCKET" --storage-class "$STORAGE_CLASS" --delete --exact-timestamps >> "$LOG_FILE" 2>&1; then
    STATUS="Backup completed successfully at $(date '+%Y-%m-%d %H:%M:%S')"
else
    STATUS="Backup FAILED at $(date '+%Y-%m-%d %H:%M:%S')"
fi
echo "$STATUS" >> "$LOG_FILE"
echo "--------------------------------------" >> "$LOG_FILE"

# Send email notification via AWS SES
EMAIL_BODY="Subject: $EMAIL_SUBJECT

$STATUS

$(tail -20 $LOG_FILE)"
aws ses send-email --from "$EMAIL_FROM" --destination "ToAddresses=$EMAIL_TO" --message "Subject={Data='$EMAIL_SUBJECT'},Body={Text={Data='$EMAIL_BODY'}}"
