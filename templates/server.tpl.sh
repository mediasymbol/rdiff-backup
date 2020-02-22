TPL_DOAS_CONFIG="permit nopass $SERVER_USER as root cmd /usr/bin/rdiff-backup args --server"

TPL_AUTHORIZED_KEYS_CONFIG="command=\"doas /usr/bin/rdiff-backup --server\" $(cat "$CONFIG_SSH_DIR/$CLIENT_RSA_KEY_NAME.pub")"

TPL_SSHD_CONFIG="PasswordAuthentication no
AllowUsers $SERVER_USER
AuthenticationMethods publickey
AuthorizedKeysFile .ssh/authorized_keys
DisableForwarding yes
PermitTTY no
PermitUserRC no"
