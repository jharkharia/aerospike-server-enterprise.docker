#
# Aerospike Server Enterprise Edition Dockerfile
#
# http://github.com/aerospike/aerospike-server-enterprise.docker
#

FROM debian:stretch-slim

ENV AEROSPIKE_VERSION 5.1.0.33
ENV AEROSPIKE_SHA256 1a25378a505df3f7cb7cd2d7362f174c3af53d60660f412776414f5ae09bbd49

# Install Aerospike Server and Tools

RUN \
  apt-get update -y \
  && apt-get install -y iproute2 procps dumb-init wget python python3 lua5.2 gettext-base libldap-dev libcurl4-openssl-dev \
  && wget "https://www.aerospike.com/enterprise/download/server/${AEROSPIKE_VERSION}/artifact/debian9" -O aerospike-server.tgz \
  && echo "$AEROSPIKE_SHA256 *aerospike-server.tgz" | sha256sum -c - \
  && mkdir aerospike \
  && tar xzf aerospike-server.tgz --strip-components=1 -C aerospike \
  && dpkg -i aerospike/aerospike-server-*.deb \
  && dpkg -i aerospike/aerospike-tools-*.deb \
  && mkdir -p /var/log/aerospike/ \
  && mkdir -p /var/run/aerospike/ \
  && rm -rf aerospike-server.tgz aerospike /var/lib/apt/lists/* \
  && rm -rf /opt/aerospike/lib/java \
  && dpkg -r wget ca-certificates openssl xz-utils\
  && dpkg --purge wget ca-certificates openssl xz-utils\
  && apt-get purge -y \
  && apt autoremove -y \
  # Remove symbolic links of aerospike tool binaries
  # Move aerospike tool binaries to /usr/bin/
  # Remove /opt/aerospike/bin
  && find /usr/bin/ -lname '/opt/aerospike/bin/*' -delete \
  && find /opt/aerospike/bin/ -user aerospike -group aerospike -exec chown root:root {} + \
  && mv /opt/aerospike/bin/* /usr/bin/ \
  && rm -rf /opt/aerospike/bin


# Add the Aerospike configuration specific to this dockerfile
COPY aerospike.template.conf /etc/aerospike/aerospike.template.conf
COPY entrypoint.sh /entrypoint.sh

# Mount the Aerospike data directory
# VOLUME ["/opt/aerospike/data"]
# Mount the Aerospike config directory
# VOLUME ["/etc/aerospike/"]


# Expose Aerospike ports
#
#   3000 – service port, for client connections
#   3001 – fabric port, for cluster communication
#   3002 – mesh port, for cluster heartbeat
#
EXPOSE 3000 3001 3002

# Runs as PID 1 /usr/bin/dumb-init -- /my/script --with --args"
# https://github.com/Yelp/dumb-init

ENTRYPOINT ["/usr/bin/dumb-init", "--", "/entrypoint.sh"]
# Execute the run script in foreground mode
CMD ["asd"]
