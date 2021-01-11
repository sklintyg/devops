#!/bin/bash
# Overrides the default startup launcher (with this simplified)

if [ "${SCRIPT_DEBUG}" = "true" ]; then
    set -x
    echo "Script debugging is enabled, allowing bash commands and their arguments to be printed as they are executed"
fi

CREDENTIALS=/opt/$APP_NAME/env/secret-env.sh
if [ -f $CREDENTIALS ]; then
    . $CREDENTIALS
fi

# Use resources.zip if exists
# if no REFDATA_URL exists get latest dev snapshot, otherwise use REFDATA_URL
RESOURCES=/opt/$APP_NAME/env/resources.zip
if [ -f $RESOURCES ]; then
    (mkdir -p /tmp/resources; cd /tmp/resources; unzip $RESOURCES)
else
    if [ -z $REFDATA_URL ]; then
        REFDATA_VERSION="1.0-SNAPSHOT"
        REFDATA_URL="https://nexus.drift.inera.se/service/rest/v1/search/assets/download?sort=version&direction=desc&repository=it-public&maven.groupId=se.inera.intyg.refdata&maven.artifactId=refdata&maven.baseVersion=${REFDATA_VERSION}&maven.extension=jar"
        REFDATA_FILE="refdata-${REFDATA_VERSION}.jar"
    else
        REFDATA_FILE=$(basename $REFDATA_URL)
    fi

    REFDATA_JAR=sklintyg-${REFDATA_FILE%.*}.jar
    curl -Ls -m 20 "${REFDATA_URL}" > $REFDATA_JAR
    if [ $? != 0 ]; then
        echo "Error: unable to fetch refdata artifact: $REFDATA_URL"
        exit 1
    fi

    mv $REFDATA_JAR $JWS_HOME/lib/
    if [ $? != 0 ]; then
        echo "Error: unable to provision refdata: $REFDATA_JAR"
        exit 1
    fi
fi

echo "Running $APP_NAME on $JBOSS_IMAGE_NAME image, version $JBOSS_IMAGE_VERSION and JAVA_HOME $JAVA_HOME"
echo "With refdata from ${REFDATA_URL:-resources.zip}"

export CATALINA_OPTS="$CATALINA_OPTS $CATALINA_OPTS_APPEND"

exec $JWS_HOME/bin/catalina.sh run


