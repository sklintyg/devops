#!/bin/bash
#
# Spring Boot Launch Script

if [ "${SCRIPT_DEBUG}" = "true" ]; then
    set -x
    echo "Script debugging is enabled, allowing bash commands and their arguments to be printed as they are executed"
fi

CREDENTIALS=/opt/$APP_NAME/env/secret-env.sh
if [ -f $CREDENTIALS ]; then
    . $CREDENTIALS
fi

# if no REFDATA_URL exists get latest dev snapshot, otherwise use REFDATA_URL
if [ -z $REFDATA_URL ]; then
    REFDATA_VERSION="1.0-SNAPSHOT"
    REFDATA_URL="https://nexus.drift.inera.se/service/rest/v1/search/assets/download?sort=version&direction=desc&repository=it-public&maven.groupId=se.inera.intyg.refdata&maven.artifactId=refdata&maven.baseVersion=${REFDATA_VERSION}&maven.extension=jar"
    REFDATA_FILE="refdata-${REFDATA_VERSION}.jar"
else
    REFDATA_FILE=$(basename $REFDATA_URL)
fi

REFDATA_JAR=sklintyg-${REFDATA_FILE%.*}.jar
curl -Ls -m 20 "${REFDATA_URL}" > /tmp/$REFDATA_JAR
if [ $? != 0 ]; then
    echo "Error: unable to fetch refdata artifact: $REFDATA_URL"
    exit 1
fi

echo "With refdata from ${REFDATA_URL}"
JVM_OPTS="$JVM_OPTS -Dloader.path=/tmp/$REFDATA_JAR,WEB-INF/lib-provided,WEB-INF/lib,WEB-INF/classes"

# use legacy name for appending options
JVM_OPTS="$JVM_OPTS $CATALINA_OPTS_APPEND"

APP=$(ls /deployments/ | egrep '\.jar$|\.war$')
exec /usr/lib/jvm/jre-11-openjdk/bin/java $JVM_OPTS $JAVA_OPTS -jar /deployments/$APP


