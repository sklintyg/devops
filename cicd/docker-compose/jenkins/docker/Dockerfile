# When updating the Jenkins version, remember to also update
# plugin versions in plugins.txt
FROM jenkins/jenkins:2.528.2-lts-jdk21

USER root

RUN apt-get update \
    && apt-get install -y ca-certificates curl docker-cli lsb-release \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

USER jenkins

COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli --plugin-file /usr/share/jenkins/ref/plugins.txt
