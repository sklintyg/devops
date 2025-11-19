FROM eclipse-temurin:21-alpine

ARG version
ARG checksum
ARG activemqPackage="apache-activemq-${version}-bin.tar.gz"

ENV ACTIVEMQ_HOME="/opt/apache-activemq-${version}"

ADD "https://archive.apache.org/dist/activemq/${version}/${activemqPackage}" /opt

WORKDIR /opt

RUN if [ "$(sha512sum "${activemqPackage}" | awk '{print $1}')" != "${checksum}" ]; then \
        echo "Checksum validation failure"; \
        exit 1; \
    fi \
    \
    && tar -xzf "${activemqPackage}" \
    && rm "${activemqPackage}" \
    && addgroup -S activemq \
    && adduser -S activemq -G activemq \
    && chown -R activemq:activemq /opt/apache-activemq-${version}

USER activemq

# Run ActiveMQ with jetty.host 0.0.0.0 to make web UI accessible from host system
ENTRYPOINT ["sh", "-c", "${ACTIVEMQ_HOME}/bin/activemq -Djetty.host=0.0.0.0 start"]