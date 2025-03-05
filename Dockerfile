FROM alpine:latest

LABEL maintainer="Patrick Oberdorf <patrick@oberdorf.net>"
LABEL description="Secure SFTP server with customizable user based on Alpine Linux"
LABEL version="2.0"

RUN apk add --no-cache \
  openssh-server \
  openssh-server-pam \
  openssh-sftp-server \
  shadow \
  perl \
  && mkdir -p /var/run/sshd \
  && chmod 0755 /var/run/sshd \
  && mkdir -p /data/incoming \
  && mkdir -p /ssh/ \
  && rm -rf /tmp/* /var/cache/apk/*

COPY sshd_config /etc/ssh/sshd_config
COPY start.sh /usr/local/bin/
RUN chmod 755 /usr/local/bin/start.sh

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD ps | grep sshd | grep -v grep > /dev/null || exit 1

VOLUME ["/data/incoming", "/ssh"]

EXPOSE 22

CMD ["/bin/sh", "/usr/local/bin/start.sh"]
