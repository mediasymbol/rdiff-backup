#!/bin/sh

source /scripts/env.sh

# Remove expired backups
printf "\n+++ BEGIN BACKUP $(date '+%H:%M %D') +++\n\n"

env_load

# Check container type
if [ "client" != $CONTAINER_TYPE ]; then
    env_error "Use this script with client container only."
fi

if [ "pull" = "$BACKUP_METHOD" ]; then
    SOURCE_PATH="$SERVER_USER@$SERVER_HOST::/backup"
    DESTINATION_PATH="/backup"
else
    SOURCE_PATH="/backup"
    DESTINATION_PATH="$SERVER_USER@$SERVER_HOST::/backup"
fi

# Backup data
BACKUP_ERROR=/tmp/backup-error
CLEANUP_ERROR=/tmp/cleanup-error

printf "\n--> Backup data\n\n"
REPORT=$(ionice -c 3 /usr/bin/rdiff-backup --print-statistics --preserve-numerical-ids --exclude-sockets --include-globbing-filelist "$CONFIG_BACKUP_LIST" "$SOURCE_PATH" "$DESTINATION_PATH" 2>"$BACKUP_ERROR")

if [ 0 -eq "$?" ]; then
    RESULT="succeded"
else
    RESULT="failed"
fi

if [ ! -z "$BACKUP_EXPIRE" ] && [ ! -s "$BACKUP_ERROR" ]; then
    printf "--> Remove expired increments\n\n"
    ionice -c 3 /usr/bin/rdiff-backup -v2 --force --remove-older-than "$BACKUP_EXPIRE" "$DESTINATION_PATH" 2>"$CLEANUP_ERROR"
fi

if [ -s "$BACKUP_ERROR" ]; then
    REPORT="$REPORT\n\n*** BACKUP ERROR\n$(cat $BACKUP_ERROR)"
    rm "$BACKUP_ERROR"
fi

if [ -s "$CLEANUP_ERROR" ]; then
    REPORT="$REPORT\n\n*** CLEANUP ERROR\n$(cat "$CLEANUP_ERROR")"
    rm "$CLEANUP_ERROR"
fi

printf "$REPORT\n"

printf "\n+++ END BACKUP $(date '+%H:%M %D') +++\n\n"

# Send message
if [ 1 -eq "$MAIL_ENABLED" ]; then
    /scripts/mail.sh "$RESULT" "$REPORT"
fi
