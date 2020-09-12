FROM alpine:latest

COPY . /

RUN apk update \
    && apk add doas openssh-client openssh-server python3 rdiff-backup ssmtp \
    && rm -rf /var/cache/apk/* /etc/ssh/ssh_host_* \
    && chmod +x /scripts/* \
    && mkdir /config

ENTRYPOINT ["/scripts/docker-entry.sh"]
