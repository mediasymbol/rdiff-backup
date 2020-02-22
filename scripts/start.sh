#!/bin/sh

printf "\n*** START SCRIPT ***\n\n"

source /scripts/env.sh

env_load
env_print

# Client startup script
if [ "client" = "$CONTAINER_TYPE" ]; then
    env_check_client

    printf "\n--> Download server SSH public keys\n"
    cp -r "$CONFIG_SSH_DIR" ~/
    ssh-keyscan -p "$SERVER_PORT" "$SERVER_HOST" > ~/.ssh/known_hosts
    if [ "$?" != 0 ]; then
        env_error "Can't get server SSH keys at $SERVER_HOST:$SERVER_PORT"
    fi

    source /templates/client.tpl.sh

    printf "\n--> Create client SSH configuration\n"
    echo -e "$TPL_SSH_CONFIG" > ~/.ssh/config

    if [ "$MAIL_ENABLED" -eq 1 ]; then
        printf  "\n--> Create SSMTP configuration\n"
        echo -e "$TPL_MAIL_CONFIG" > /etc/ssmtp/ssmtp.conf
    fi

    unset TPL_SSH_CONFIG TPL_MAIL_CONFIG

    printf  "\n--> Run crond service <--\n\n"
    ln -s /scripts/backup.sh /etc/periodic/"$BACKUP_FREQUENCY"/backup
    /usr/sbin/crond -f -l 4

# Server startup script
else
    printf "\n--> Prepare SSH user\n"
    if [ ! -f "$CONFIG_SSH_DIR/$CLIENT_RSA_KEY_NAME.pub" ]; then
        env_error "Client public RSA key doesn't exist"
    fi

    source /templates/server.tpl.sh

    SERVER_USER_GROUP="$SERVER_USER"
    SERVER_USER_HOME=/home/"$SERVER_USER"

    adduser -D -h "$SERVER_USER_HOME" "$SERVER_USER" "$SERVER_USER_GROUP"
    echo "$SERVER_USER":$(date +%s | sha256sum | base64 | head -c 32) | chpasswd 2>/dev/null
    echo -e "$TPL_DOAS_CONFIG" > /etc/doas.conf

    mkdir "$SERVER_USER_HOME"/.ssh
    echo -e "$TPL_AUTHORIZED_KEYS_CONFIG" > "$SERVER_USER_HOME/.ssh/authorized_keys"

    printf "\n--> Create SSHD configuration\n"
    ln -s "$CONFIG_SSH_DIR"/"$SERVER_RSA_KEY_NAME"* /etc/ssh/
    ln -s "$CONFIG_SSH_DIR"/"$SERVER_DSA_KEY_NAME"* /etc/ssh/

    echo -e "$TPL_SSHD_CONFIG" > /etc/ssh/sshd_config

    unset TPL_DOAS_CONFIG TPL_AUTHORIZED_KEYS_CONFIG TPL_SSHD_CONFIG

    printf "\n--> Run sshd service <--\n\n"
    /usr/sbin/sshd -D
fi
