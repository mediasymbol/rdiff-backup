#!/bin/sh

printf "\n*** INITIALIZATION SCRIPT ***\n\n"

# Check current configuration
source /scripts/env.sh

if [ -f "$CONFIG_ENV_FILE" ]; then
    CURRENT_ENV=$(cat "$CONFIG_ENV_FILE")
    CURRENT_CONFIG=$(echo "$CURRENT_ENV" | egrep -Eo "(client|server)$")
    if [ 'client' = $CURRENT_CONFIG ]; then
        CURRENT_CONFIG="$CURRENT_CONFIG in $(echo "$CURRENT_ENV" | egrep -Eo "(push|pull)$") mode"
    fi

    printf "The container is already initialized as a rdiff-backup $CURRENT_CONFIG.\n"
    read -p "Do you want to create new configuration [y/n]? " choice

    printf "\n"

    if [ "$choice" != "y" ]; then
        exit 0
    fi
fi

# Read new configuration settings
printf "Choose container type:\n  [1] client\n  [2] server\n> "
while read option; do
    case "$option" in
        1) CONTAINER_TYPE="client"; break;;
        2) CONTAINER_TYPE="server"; break;;
        *) printf "Incorrect type\nPlease enter the correct type: "
    esac
done

if [ "client" = "$CONTAINER_TYPE" ]; then
    printf "\nChoose backup method:\n  [1] push\n  [2] pull\n> "
    while read option; do
        case "$option" in
            1) BACKUP_METHOD="push"; break;;
            2) BACKUP_METHOD="pull"; break;;
            *) printf "Incorrect method\nPlease enter the correct method: "
        esac
    done
fi

# Cleanup and save configuration
find /config -mindepth 1 -delete
mkdir "$CONFIG_SSH_DIR"

printf "\n"
env_save

# Client initialization
if [ "client" = "$CONTAINER_TYPE" ]; then
    printf "--> Generate RSA key\n"
    ssh-keygen -b 2048 -t rsa -f "$CONFIG_SSH_DIR/$CLIENT_RSA_KEY_NAME" -q -N ""
    cat "$CONFIG_SSH_DIR/$CLIENT_RSA_KEY_NAME.pub"

    printf "\n--> Create backup list file\n"
    touch "$CONFIG_BACKUP_LIST"

# Server initialization
else
    printf "--> Generate host SSH keys\n"
    ssh-keygen -f "$CONFIG_SSH_DIR/$SERVER_RSA_KEY_NAME" -N '' -t rsa
    printf "\n"
    ssh-keygen -f "$CONFIG_SSH_DIR/$SERVER_DSA_KEY_NAME" -N '' -t dsa
fi

printf "\n--> Done <--\n\n"
