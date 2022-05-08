# JDK 11 - alpine
FROM eclipse-temurin:11-alpine

ARG version
ARG checksum
ARG activemqPackage="apache-activemq-$version-bin.tar.gz"

# Download activemq 'version' to directory /opt
ADD "https://archive.apache.org/dist/activemq/$version/$activemqPackage" /opt

WORKDIR /opt

# Check integrity of downloaded activemq package.
RUN if [ $(sha512sum $activemqPackage | awk '{print $1}') != $checksum ]; then echo Checksum validation failure; exit -1; fi;

# Decompress downloaded apachemq and remove compressed file
RUN tar -xzf $activemqPackage && rm $activemqPackage

ENV ACTIVEMQ_HOME="/opt/apache-activemq-$version"

# Run activemq with jetty.host set to 0.0.0.0 to make web UI accessible from host system
ENTRYPOINT $ACTIVEMQ_HOME/bin/activemq -Djetty.host=0.0.0.0 start
