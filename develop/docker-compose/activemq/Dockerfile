# JDK 11 - alpine
FROM eclipse-temurin:11-alpine

# Use version arg from docker-compose
ARG version

# Download activemq 'version' to directory /opt
ADD "https://archive.apache.org/dist/activemq/$version/apache-activemq-$version-bin.tar.gz" /opt

WORKDIR /opt

# Decompress downloaded apachemq and remove compressed file
RUN tar -xzf "apache-activemq-$version-bin.tar.gz" && rm "apache-activemq-$version-bin.tar.gz"

ENV ACTIVEMQ_HOME="/opt/apache-activemq-$version"

# Run activemq with jetty.host set to 0.0.0.0 to make web UI accessible from host system
ENTRYPOINT $ACTIVEMQ_HOME/bin/activemq -Djetty.host=0.0.0.0 start
