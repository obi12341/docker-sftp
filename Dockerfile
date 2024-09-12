FROM ubuntu:24.04

RUN apt-get update && apt-get install -y \
  openssh-server \
  mcrypt \
  && mkdir /var/run/sshd \
  && chmod 0755 /var/run/sshd \
  && mkdir -p /data/incoming \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
  && mkdir /ssh/

ADD start.sh /usr/local/bin/start.sh
ADD sshd_config /etc/ssh/sshd_config

VOLUME ["/data/incoming"]
EXPOSE 22

CMD ["/bin/bash", "/usr/local/bin/start.sh"]
