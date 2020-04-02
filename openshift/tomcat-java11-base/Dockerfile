FROM docker-registry.default.svc:5000/openshift/webserver52-openjdk11-tomcat9-openshift-rhel7
LABEL maintainer="inera.se"

RUN rm -rf $JWS_HOME/tomcat/webapps/* \
    $JWS_HOME/tomcat/lib/mysql-connector-java.jar $JWS_HOME/tomcat/lib/mongo.jar \
    $JWS_HOME/tomcat/lib/jolokia.jar $JWS_HOME/tomcat/lib/postgresql-jdbc.jar

ADD http://repo1.maven.org/maven2/javax/servlet/jsp/jstl/javax.servlet.jsp.jstl-api/1.2.1/javax.servlet.jsp.jstl-api-1.2.1.jar $JWS_HOME/tomcat/lib
ADD http://repo1.maven.org/maven2/org/glassfish/web/javax.servlet.jsp.jstl/1.2.1/javax.servlet.jsp.jstl-1.2.1.jar  $JWS_HOME/tomcat/lib

USER root
RUN ln -snf /usr/share/zoneinfo/Europe/Stockholm /etc/localtime
RUN localedef -i en_US -f UTF-8 en_US.UTF-8
RUN chown jboss $JWS_HOME/tomcat/lib/*
RUN chmod 644 $JWS_HOME/tomcat/lib/*
USER jboss

ADD launch.sh $JWS_HOME/tomcat/bin/
ADD conf/server.xml $JWS_HOME/tomcat/conf/
