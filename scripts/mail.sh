#!/bin/sh

MAIL=/var/mail/mail.txt

cat <<EOT > $MAIL
To: $MAIL_RECEIVER_ADDRESS
From: $MAIL_SENDER_ADDRESS
Subject: Backup $1 $(date '+%H:%M %D')
Content-Type: text/plain; charset="utf8"
EOT

echo -e "$2" >> $MAIL

ssmtp -ap "$MAIL_AUTH_PASS" "$MAIL_RECEIVER_ADDRESS" < $MAIL
rm $MAIL
