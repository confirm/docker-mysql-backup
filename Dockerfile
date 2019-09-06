FROM debian:buster

MAINTAINER confirm IT solutions, dbarton

#
# Ensure the correct variables are set for APT
#

ENV DEBIAN_FRONTEND=noninteractive TERM=linux

#
# Install start script.
#

COPY init.sh /init.sh

#
# Add user and install required packages.
#

RUN \
    groupadd -g 666 mybackup && \
    useradd -u 666 -g 666 -d /backup -c "MySQL Backup User" mybackup && \
    apt-get -y update && \
    apt-get -y install mydumper && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    find /var/log -type f | while read f; do echo -ne '' > $f; done && \
    chmod 750 /init.sh

#
# Set container settings.
#

VOLUME ["/backup"]
WORKDIR /backup

#
# Start process.
#

CMD ["/init.sh"]
