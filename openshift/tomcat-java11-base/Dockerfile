FROM docker-registry.default.svc:5000/openshift/webserver52-openjdk11-tomcat9-openshift-rhel7
LABEL maintainer="inera.se"

RUN rm -rf $JWS_HOME/webapps/* \
    $JWS_HOME/lib/mysql-connector-java.jar $JWS_HOME/lib/mongo.jar \
    $JWS_HOME/lib/jolokia.jar $JWS_HOME/lib/postgresql-jdbc.jar

ADD https://repo1.maven.org/maven2/javax/servlet/jsp/jstl/javax.servlet.jsp.jstl-api/1.2.2/javax.servlet.jsp.jstl-api-1.2.2.jar $JWS_HOME/lib
ADD https://repo1.maven.org/maven2/org/glassfish/web/javax.servlet.jsp.jstl/1.2.5/javax.servlet.jsp.jstl-1.2.5.jar  $JWS_HOME/lib

USER root
RUN ln -snf /usr/share/zoneinfo/Europe/Stockholm /etc/localtime && \
 localedef -i en_US -f UTF-8 en_US.UTF-8 && \
 chown 185 $JWS_HOME/lib/* && \
 chmod 644 $JWS_HOME/lib/*
USER 185

ADD launch.sh $JWS_HOME/bin/
ADD conf/server.xml $JWS_HOME/conf/
