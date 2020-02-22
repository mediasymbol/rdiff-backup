#!/bin/sh

printf "\n*** RESTORE SCRIPT ***\n\n"

source /scripts/env.sh

env_load

# Check container type
if [ "client" != $CONTAINER_TYPE ]; then
    env_error "Use this script with client container only"
fi

# Check backup mode
if [ "pull" = "$BACKUP_METHOD" ]; then
    BACKUP_PATH="/backup"
    RESTORE_PATH="$SERVER_USER@$SERVER_HOST::/restored"
else
    BACKUP_PATH="$SERVER_USER@$SERVER_HOST::/backup"
    RESTORE_PATH="/restored"
fi

# Get list of increments
if [ -z "$1" ]; then
    printf "\nAvailable increments:\n\n"
    printf "$(/usr/bin/rdiff-backup --list-increment-sizes "$BACKUP_PATH")\n\n"
    exit 0
fi

# Restore data
printf "\n--> Restore data\n"

if [ -z "$2" ]; then
    RESTORE_PATH="$RESTORE_PATH/$1"
else
    BACKUP_PATH="$BACKUP_PATH/$2"
    RESTORE_PATH="$RESTORE_PATH/$2"
fi

RESTORE_ERROR=/tmp/backup-error

/usr/bin/rdiff-backup --force --restore-as-of "$1" "$BACKUP_PATH" "$RESTORE_PATH" 2>"$RESTORE_ERROR"

if [ -s "$RESTORE_ERROR" ]; then
    MSG=$(cat "$RESTORE_ERROR")
    rm "$RESTORE_ERROR"
    env_error "$MSG"
fi

printf "\n--> Done\n\n"
