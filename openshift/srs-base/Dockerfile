FROM docker-registry.default.svc:5000/dintyg/springboot-base:latest

USER root
ENV R_HOME=/usr/lib64/R
ENV JVM_OPTS="-Djava.library.path=$R_HOME/library/rJava/jri"

RUN yum -y install epel-release
RUN yum -y install R
RUN R -e 'install.packages("rJava",,"http://www.rforge.net/")'
RUN R -e 'install.packages("pch",,"https://cloud.r-project.org/")'
RUN rm /opt/app/bin/launch.sh
ADD launch.sh /opt/app/bin/
RUN chmod 755 /opt/app/bin/launch.sh
USER nobody
