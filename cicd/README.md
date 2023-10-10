

## Clone the devops repo from Intygstjanster
Clone repo to a suitable location (for example /repos/intyg) in WSL Ubuntu distro.
For easy editing of code, setup a project in Intellij in Windows and point to the repo in Linux
\\wsl$\Ubuntu-22.04\repos\intyg

The devops repo was cloned into a suitable location wsl ubuntu environment but setup as an Intellij project in Windows.


## Downloading and running Jenkins in Docker
https://www.jenkins.io/doc/book/installing/docker/
https://yetkintimocin.medium.com/creating-a-local-jenkins-server-using-docker-2e4dfe7b5880


## Create a self-signed certificate for use in docker test-environment

Use openssl to create a self-signed certificate for use with local docker registry for testing
purposes only.

    openssl req -newkey rsa:4096 -nodes -sha256 -keyout certs/host-docker-internal.key -addext \
    "subjectAltName = DNS:host.docker.internal" -x509 -days 3650 -out certs/host-docker-internal.crt

https://docs.docker.com/registry/deploying/ \
https://docs.docker.com/registry/insecure/



## Accessing Sonarqube and Nexus api's from local docker environment
For using sonarqube or nexus from repo code, use ip 172.21.0.1 which is the ip od the jenkins network
setup in the docker-compose file

examples of replaced code\
maven { url "http://172.21.0.1:37373/repository/it-public/" }\
//maven { url "https://nexus.drift.inera.se/repository/it-public/" }

it.property("sonar.host.url", System.getProperty("sonarUrl") ?: "http://172.21.0.1:9000")\
//it.property("sonar.host.url", System.getProperty("sonarUrl") ?: "https://sonarqube.drift.inera.se")


## Accessing application gui's
jenkins: localhost:49000\
nexus: localhost:37373\
sonarqbe: localhost:9000
