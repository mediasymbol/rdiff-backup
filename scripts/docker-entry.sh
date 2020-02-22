#!/bin/sh

printf "\n#### RDIFF-BACKUP CONTAINER ####\n"

### Start service if no parameters were supplied ###
if [ "$#" -eq 0 ]; then
    source /scripts/start.sh
    exit "$?"
fi

### Execute arguments ###
exec "$@"
