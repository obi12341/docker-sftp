FROM ubuntu:24.04

LABEL maintainer="Patrick Oberdorf <patrick@oberdorf.net>"
LABEL description="Secure SFTP server with customizable user"
LABEL version="1.0"

RUN apt-get update && apt-get install -y --no-install-recommends \
  openssh-server \
  whois \
  && mkdir /var/run/sshd \
  && chmod 0755 /var/run/sshd \
  && mkdir -p /data/incoming \
  && mkdir /ssh/ \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY sshd_config /etc/ssh/sshd_config
COPY start.sh /usr/local/bin/
RUN chmod 755 /usr/local/bin/start.sh

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD pgrep sshd >/dev/null || exit 1

VOLUME ["/data/incoming", "/ssh"]

EXPOSE 22

CMD ["/bin/bash", "/usr/local/bin/start.sh"]
