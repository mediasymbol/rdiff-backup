#!/bin/sh

# Variables
CONFIG_ENV_FILE=/config/env
CONFIG_BACKUP_LIST=/config/backup.list
CONFIG_SSH_DIR=/config/.ssh
CLIENT_RSA_KEY_NAME=ssh_client_rsa_key
SERVER_RSA_KEY_NAME=ssh_host_rsa_key
SERVER_DSA_KEY_NAME=ssh_host_dsa_key
SERVER_USER=rdiff

# Exit with error code when something is wrong
env_error() {
    if [ ! -z "$1" ]; then
        printf "\nExit with error:\n- $1\n\n"
    else
        printf "\nExit with error:\n- internal\n\n"
    fi

    exit 1
}

env_var_error() {
    if [ "$#" -eq 1 ]; then
        env_error "\"$1\" environment variable is undefined"
    elif [ "$#" -eq 2 ]; then
        env_error "The value \"$2\" for the environment variable \"$1\" is not allowed"
    else
        env_error
    fi
}

# Check environment variables
env_check_mode() {
    # Container type
    if [ -z "$CONTAINER_TYPE" ]; then env_var_error "CONTAINER_TYPE"; fi
    if [ "server" = "$CONTAINER_TYPE" ]; then return; fi
    if [ "client" != "$CONTAINER_TYPE" ]; then env_var_error "CONTAINER_TYPE" "$CONTAINER_TYPE"; fi

    # Client mode
    if [ -z "$BACKUP_METHOD" ]; then env_var_error "BACKUP_METHOD"; fi
    if ! echo "$BACKUP_METHOD" | egrep -Eq "^(pull|push)$"; then
        env_var_error "BACKUP_METHOD" "$BACKUP_METHOD";
    fi
}

env_check_client() {
    # Server settings
    if [ -z "$SERVER_HOST" ]; then env_var_error "SERVER_HOST"; fi
    if [ -z "$SERVER_PORT" ]; then env_var_error "SERVER_PORT"; fi

    # Cron settings
    if [ -z "$BACKUP_FREQUENCY" ]; then env_var_error "BACKUP_FREQUENCY"; fi
    if ! echo "$BACKUP_FREQUENCY" | egrep -Eq "^(15min|daily|hourly|monthly|weekly)$"; then
        env_var_error "BACKUP_FREQUENCY" "$BACKUP_FREQUENCY";
    fi

    # Mail settings
    if [ "$MAIL_ENABLED" != 1 ]; then
        MAIL_ENABLED=0
        return;
    fi

    if [ -z "$MAIL_SENDER_ADDRESS" ]; then env_var_error "MAIL_SENDER_ADDRESS"; fi
    if [ -z "$MAIL_SERVER_HOST" ]; then env_var_error "MAIL_SERVER_HOST"; fi
    if [ -z "$MAIL_SERVER_PORT" ]; then env_var_error "MAIL_SERVER_PORT"; fi
    if [ -z "$MAIL_AUTH_USER" ]; then env_var_error "MAIL_AUTH_USER"; fi
    if [ -z "$MAIL_AUTH_PASS" ]; then env_var_error "MAIL_AUTH_PASS"; fi
    if [ -z "$MAIL_RECEIVER_ADDRESS" ]; then env_var_error "MAIL_RECEIVER_ADDRESS"; fi
    if [ -z "$MAIL_TLS" ]; then env_var_error "MAIL_TLS"; fi
    if [ -z "$MAIL_STARTTLS" ]; then env_var_error "MAIL_STARTTLS"; fi
}

# Print configuration
env_print() {
    printf "Container type - $CONTAINER_TYPE\n"

    if [ "client" = "$CONTAINER_TYPE" ]; then
        printf "Backup method - $BACKUP_METHOD\n"
    fi
}

# Save environment variables to finalize initialization and to avoid further overriding
env_save() {
    printf "--> Save configuration\n"
    env_print

    CONFIG_ENV="export CONTAINER_TYPE=$CONTAINER_TYPE";
    if [ "client" = "$CONTAINER_TYPE" ]; then
        CONFIG_ENV="$CONFIG_ENV\nexport BACKUP_METHOD=$BACKUP_METHOD"
    fi

    echo -e "$CONFIG_ENV" > "$CONFIG_ENV_FILE"

    printf "\n"
}

# Load environment
env_load() {
    printf "--> Load configuration\n"

    if [ ! -f "$CONFIG_ENV_FILE" ]; then
        env_error "The container is not initialized. Please initialize container"
    fi

    source "$CONFIG_ENV_FILE"

    env_check_mode
}
