# Intygstjänster - OpenShift Container Platform (OCP) 

This document specifies how to setup Intygstjänster build-pipelines in an OpenShift Cluster.

## OCP build Pipelines

### Pre-req
Before we can start to setup Intygstjänster build-pipelines, we first need to configure the Openshift project used for these pipelines.

#### Secrets
The following secrets must be added to the project.

**git-webhook-secret**
```
oc create secret generic git-webhook-secret \
--from-literal=WebHookSecretKey=<replace_me> \
--type=Opaque
```

**nexus-registry**
```
oc secrets new-dockercfg nexus-registry \
--docker-server=docker.drift.inera.se \
--docker-username=<replace_me> \
--docker-password=<replace_me> \
--docker-email=support@basefarm.com
```

**jenkins-integration**
```
oc create secret generic jenkins-integration \
--from-literal=GITHUB_PASSWORD=<replace_me> \
--from-literal=GITHUB_USERNAME=<replace_me> \
--from-literal=NEXUS_PASSWORD=<replace_me> \
--from-literal=NEXUS_USERNAME=<replace_me> \
--from-literal=INERA_NEXUS_PASSWORD=<replace_me> \
--from-literal=INERA_NEXUS_USERNAME=<replace_me> \
--type=Opaque
```

#### Persistant Volume Claims (PVC)
Some services and pipelines require PVC's to function. These are normally created by OpenShift when the service is added from the catalog, but the following PVC's needs to be added manually to the project:

| Name | Requested Capacity | Access Modes | Used by
| --- | --- | --- | --- |
| jenkins-reports | 10GiB | RWO | testrunnertemplate-pod.yaml |

#### Infrastructure Services
The following services must exist in order for the build-pipelines to function:

##### AMQ (Persistent)
Add `JBoss A-MQ 6.3 (no SSL)` from the OpenShift catalog with the following settings:

| Name | Value |
| --- | --- |
| A-MQ Mesh Discovery Type | dns |
| Queue Memory Limit | 100 mb |
| Split Data? | true |
| A-MQ Store Usage Limit | 8 gb |
| Application Name | broker |
| ImageStream Namespace | openshift |
| A-MQ Password | admin |
| A-MQ Protocols | openwire |
| Queues | perf.certificate.queue |
| A-MQ Serializable Packages | Topics | A-MQ Username | admin |
| A-MQ Volume Size | 10Gi |
| A-MQ Serializable Packages | |
| Topics | |

Adjust Limit Resources for the deployment:
* broker-amq
    * CPU: 100 millicores to 200 millicores
    * Memory: 100 MiB to 500 MiB
* broker-drainer
    * CPU: 100 millicores to 200 millicores
    * Memory: 100 MiB to 500 MiB

##### Redis (Persistent)
Add `Redis` from the OpenShift catalog with the following settings:

| Name | Value |
| --- | --- |
| Database Service Name | redis |
| Memory Limit | 2Gi |
| Namespace | openshift |
| Redis Connection Password | redis |
| Version of Redis Image | 3.2 |
| Volume Capacity | 25Gi |

Adjust Limit Resources for the deployment:
* redis
    * CPU: 100 millicores to 300 millicores
    * Memory: 1 GiB to 2 GiB


##### MySQL (Persistent)
Add `MySQL` from the OpenShift catalog with the following settings:

| Name | Value |
| --- | --- |
| Database Service Name | mysql |
| Memory Limit | 2Gi |
| MySQL Database Name | sampledb |
| MySQL Connection Password | <replace_me> |
| MySQL root user Password | <replace_me> |
| MySQL Connection Username | <replace_me> |
| Version of MySQL Image | 5.7 |
| Namespace | openshift |
| Volume Capacity | 100Gi |

Adjust Limit Resources for the deployment:
* redis
    * CPU: 100 millicores to 500 millicores
    * Memory: 500 MiB to 2 GiB

Some of the services in Intygstjänster uses the default user and password provided as ENV-variables by OpenShift, but others use their own dedicated user/pass. These must be added to MySQL:
```
CREATE USER 'intyg'@'%' IDENTIFIED BY 'intyg';
GRANT ALL PRIVILEGES ON * . * TO 'intyg'@'%' WITH GRANT OPTION;
CREATE USER 'intygsadmin'@'%' IDENTIFIED BY 'intygsadmin';
GRANT ALL PRIVILEGES ON * . * TO 'intygsadmin'@'%' WITH GRANT OPTION;
CREATE USER 'statistik'@'%' IDENTIFIED BY 'statistik';
GRANT ALL PRIVILEGES ON * . * TO 'statistik'@'%' WITH GRANT OPTION;
CREATE USER 'intygsbestallning'@'%' IDENTIFIED BY 'intygsbestallning';
GRANT ALL PRIVILEGES ON * . * TO 'intygsbestallning'@'%' WITH GRANT OPTION;
CREATE USER 'privatlakarportal'@'%' IDENTIFIED BY 'privatlakarportal';
GRANT ALL PRIVILEGES ON * . * TO 'privatlakarportal'@'%' WITH GRANT OPTION;
CREATE USER 'webcert'@'%' IDENTIFIED BY 'webcert';
GRANT ALL PRIVILEGES ON * . * TO 'webcert'@'%' WITH GRANT OPTION;
CREATE USER 'srs'@'%' IDENTIFIED BY 'srs';
GRANT ALL PRIVILEGES ON * . * TO 'srs'@'%' WITH GRANT OPTION;
```

#### Jenkins (Persistent)
Add `Jenkins` from the OpenShift catalog with the following settings:

| Name | Value |
| --- | --- |
| Disable memory intensive administrative monitors | false |
| Fatal Error Log File | false |
| Enable OAuth in Jenkins | true |
| Jenkins ImageStreamTag | jenkins:2 |
| Jenkins Service Name | jenkins |
| Jenkins JNLP Service Name | jenkins-jnlp |
| Memory Limit | 10Gi |
| Jenkins ImageStream Namespace | openshift |
| Volume Capacity | 10Gi |

Adjust Limit Resources for the deployment:
* redis
    * CPU: 100 millicores to 2 cores
    * Memory: 10 GiB limit

Add Environment variables to the newly created DC.

| Name | Value | Note |
| --- | --- | --- |
| JENKINS_JAVA_OPTIONS | -Dhudson.model.DirectoryBrowserSupport.CSP= -Xmx1536m -XX:MaxPermSize=512m | |
| INSTALL_PLUGINS | openshift-sync:1.0.42 | A bug in version .43 & .44 requires this downgrade |
| Environment From | jenkins-integration | Add variables from this secret |

**Jenkins configuraration**

Some additional plugins are needed so start by installing this from the Jenkins UI:
* Global Slack Notifier Plugin
* Slack Notification
* Email Extension Plugin
* Webhook Step Plugin
* Next Build version Plugin

JDKs (Tools) for Java8 and Java11 must be installed. Use the Jenkins UI and Global Tool Configuration. Add two `JKD installations` name `JDK8` and `JDK11` with their corresponding jdk packages.

We must add the following `Global Pipeline Libraries`:

|||
|---|---|
|name|intyglib|
|Default version|master|
|Repository URL|https://github.com/sklintyg/jenkins.git|

#### Github Webhookproxy
To be able to accept webhooks from GitHub and trigger builds a proxy is needed.
 
The proxy is [gitwebhookproxy](https://github.com/stakater/GitWebhookProxy) with the image from docker hub [https://hub.docker.com/r/stakater/gitwebhookproxy/](https://hub.docker.com/r/stakater/gitwebhookproxy/).

A deployment config, service and route has to be configured, and the following environment variables are set in the deployment config:

| Name | Value |
| ---- | ----- |
| LISTEN | :8080 |
| UPSTREAMURL | https://ind-ocpt1a-api.ocp.sth.basefarm.net |
| ALLOWEDPATHS | |
| PROVIDER | github |
| SECRET | _from git-webhook-secret with key WebhookSecretKey_ |

_Note: ALLOWEDPATHS shall be empty, and the SECRET value is from a secret with name git-webhook-secret and the key WebhookSecretKey_

#### ACME-controller (Not currently in use)
This one is used to provide LetsEncrypt Certificates to our routes.

Follow the instructions at: https://github.com/tnozicka/openshift-acme/tree/master/deploy/letsencrypt-live/single-namespace

### Housekeeping

Build and test processes generates a lot of artifacts such as images, pods/containers, reports and logs. Therefore it's necessary to have some fundamental house keeping functions.

* Builds have properties to control history limits, also see `successfulBuildsHistoryLimit` and `failedBuildsHistoryLimit`. Normally are these set to a value in the range `2..4`.
* A dedicated housekeeping pipeline cleans:
  * Completed pods/containers (> 1 day)
  * Latest images from image streams (only keep a history of 10 develop builds per stream)
  * Jenkins reports and build logs (only keep a history of 20 days) 

Housekeeping functions are executed as a pipeline, see `pipelinetemplate-housekeeping.yaml`, nightly. (See Jenkins configuration further down).

**Note:** _For the time being all images and main versions of develop builds are defined within the pipeline definition, see `def images = [ 'image': "'X.Y.Z', ...]` list in `pipelinetemplate-housekeeping.yaml`. This means that when a new release branch is created the version numbers have to be bumped and the housekeeping pipeline needs to be updated, accordingly._

Also see scripts `clean-istags.sh` and `clean-pods.sh`.

The template (housekeeping) must be applied in the OCP project of question:

**Parameters:**

| Name | Value | Description |
| ---- | ----- | ----- | 
| RELEASE_VERSION | 2020-2 | Name of the release for this pipeline. Used to maintain separate pipelines between releases.

```
$ oc process -f pipelinetemplate-housekeeping.yaml -p RELEASE_VERSION=2020-2 | oc apply  -f -
```

**Jenkins configuration**

To make this pipeline execute on a nightly basis, we need to make extra configuration to the created pipeline in Jenkins. Open Jenkins via its URL and configure the housekeeping pipeline. Add a _Build Periodically Build Trigger_ and set it to a cron value. i.e. `H 7 * * *`

### Base images

Base images for artifact builds, tomcat apps, spring boot and a special for srs exists. These are uploaded to BaseFarm nexus server `docker.drift.inera.se/intyg`.

They are created with `make` and, which in turn uses `buildtemplate-image.yaml`. They are then uploaded to BaseFarm nexus with `buildtemplate-nexus.yaml`. The base images are:

* springboot-base
* tomcat-base
* tomcat-java11-base
* srs-base
* s2i-war-builder
* job-runner

The tags indicates main version and currently are 8 and 11 used to indicate java versions and 9 for tomcat version. Tagging is done manually in OpenShift `oc tag <is>:latest <is>:8` before pushing to BaseFarm nexus. 
```
oc tag s2i-war-builder:latest s2i-war-builder:8
oc tag s2i-war-builder-java11:latest s2i-war-builder-java11:11
oc tag springboot-base:latest springboot-base:11
oc tag srs-base:latest srs-base:8
oc tag tomcat-base:latest tomcat-base:9
oc tag tomcat-java11-base:latest tomcat-java11-base:9
```

The upload to Nexus is done with:
```
oc process -f buildtemplate-nexus.yaml -p APP_NAME=job-runner -p NEXUS_NAME=job-runner -p IMAGE=dintyg/jobrunner -p TAG=latest | oc apply -f -
oc start-build job-runner-nexus
oc process -f buildtemplate-nexus.yaml -p APP_NAME=job-runner -p NEXUS_NAME=job-runner -p IMAGE=dintyg/jobrunner -p TAG=latest | oc delete -f -

oc process -f buildtemplate-nexus.yaml -p APP_NAME=s2i-war-builder -p NEXUS_NAME=s2i-war-builder -p IMAGE=dintyg/s2i-war-builder -p TAG=8 | oc apply -f -
oc start-build s2i-war-builder-nexus
oc process -f buildtemplate-nexus.yaml -p APP_NAME=s2i-war-builder -p NEXUS_NAME=s2i-war-builder -p IMAGE=dintyg/s2i-war-builder -p TAG=8 | oc delete -f -

oc process -f buildtemplate-nexus.yaml -p APP_NAME=s2i-war-builder-java11 -p NEXUS_NAME=s2i-war-builder -p IMAGE=dintyg/s2i-war-builder-java11 -p TAG=11 | oc apply -f -
oc start-build s2i-war-builder-java11-nexus
oc process -f buildtemplate-nexus.yaml -p APP_NAME=s2i-war-builder-java11 -p NEXUS_NAME=s2i-war-builder -p IMAGE=dintyg/s2i-war-builder-java11 -p TAG=11 | oc delete -f -

oc process -f buildtemplate-nexus.yaml -p APP_NAME=springboot-base -p NEXUS_NAME=springboot-base -p IMAGE=dintyg/springboot-base -p TAG=11 | oc apply -f -
oc start-build springboot-base-nexus
oc process -f buildtemplate-nexus.yaml -p APP_NAME=springboot-base -p NEXUS_NAME=springboot-base -p IMAGE=dintyg/springboot-base -p TAG=11 | oc delete -f -

oc process -f buildtemplate-nexus.yaml -p APP_NAME=srs-base -p NEXUS_NAME=srs-base -p IMAGE=dintyg/srs-base -p TAG=8 | oc apply -f -
oc start-build srs-base-nexus
oc process -f buildtemplate-nexus.yaml -p APP_NAME=srs-base -p NEXUS_NAME=srs-base -p IMAGE=dintyg/srs-base -p TAG=8 | oc delete -f -

oc process -f buildtemplate-nexus.yaml -p APP_NAME=tomcat-base -p NEXUS_NAME=tomcat-base -p IMAGE=dintyg/tomcat-base -p TAG=9 | oc apply -f -
oc start-build tomcat-base-nexus
oc process -f buildtemplate-nexus.yaml -p APP_NAME=tomcat-base -p NEXUS_NAME=tomcat-base -p IMAGE=dintyg/tomcat-base -p TAG=9 | oc delete -f -

oc process -f buildtemplate-nexus.yaml -p APP_NAME=tomcat-java11-base -p NEXUS_NAME=tomcat-java11-base -p IMAGE=dintyg/tomcat-java11-base -p TAG=9 | oc apply -f -
oc start-build tomcat-java11-base-nexus
oc process -f buildtemplate-nexus.yaml -p APP_NAME=tomcat-java11-base -p NEXUS_NAME=tomcat-java11-base -p IMAGE=dintyg/tomcat-java11-base -p TAG=9 | oc delete -f -
```
 
### Intygstjänster OCP Templates
Dev pipelines for Web Apps are realized with OCP Templates and the following templates exists:

* buildtemplate-image.yaml - Docker Image Builder
* buildtemplate-webapp-binary.yaml - Web App Builder (gradle, java, tomcat)
* buildtemplate-bootapp-binary.yaml - SpringBoot App Builder (gradle, java 8 and 11)
* buildtemplate-srsapp-binary.yaml - Special Web App Builder for SRS
* buildtemplate-nexus.yaml - Upload image from image stream to Nexus
* deploytemplate-webapp.yaml - Web App Deployer
* jobtemplate.yaml - Runs scheduled scripts. 
* pipelinetemplate-build-library.yaml - Library builder. Infra, Common, Refdata
* pipelinetemplate-build-webapp.yaml - Web App Build Pipeline. Depends the templates above
* pipelinetemplate-housekeeping.yaml - OpenShift resource cleanup
* pipelinetemplate-promote-images.yaml - Pipeline that uses the buildtemplate-nexus.yaml to promote images to nexus
* testrunnertemplate-pod.yaml - Pod Test Runner (gradle, java)

#### Intygstjänster Library pipelines
The librarys in Intygstjänster are built by pipelines created with `pipelinetemplate-build-library.yaml`. A release branch for each repository must first be created and updated to reflect the new release-version. (i.e. EnvConfig.js might be updated or properties used in secrets or configmaps).

When this is done the new pipeline can be created.

**Parameters:** 

| Parameter     | Required | Description |
| ------------- | ---------| ----------- |
| LIBRARY_NAME  | Yes      | i.e. `infra-2020-2` |
| STAGE         |          | The stage label, default is `build` |        
| GIT_URL       | Yes      | The GitURL for this repository |
| GIT_CI_BRANCH | Yes      | Branch from repo i.e. `release/2020-2`   |
| CONTEXT_DIR   |          | defaults to `.`|

**infra**
```
oc process -f pipelinetemplate-build-library.yaml -p LIBRARY_NAME=infra-2020-2 -p GIT_URL=https://github.com/sklintyg/infra.git -p GIT_CI_BRANCH=release/2020-2 | oc apply -f -
```
**common**
```
oc process -f pipelinetemplate-build-library.yaml -p LIBRARY_NAME=common-2020-2 -p GIT_URL=https://github.com/sklintyg/common.git -p GIT_CI_BRANCH=release/2020-2 | oc apply -f -
```

#### Intygstjänster Web App Pipelines
The Web-apps in Intygstjänster are built by pipelines created with `pipelinetemplate-build-webapp.yaml`. A release branch for each repository must first be created and updated to reflect the new release-version. (i.e. EnvConfig.js might be updated or properties used in secrets or configmaps).

When this is done the new pipeline can be created.

**Parameters:** 

| Parameter | Required | Description |
| --------- | -------- | ----------- |
| APP_NAME                | Yes         | The Web App name, ex: `webcert` |
| RELEASE_VERSION         | Yes         | The name of this release, ex: `2020-2` |
| STAGE                   |             | The stage label, default is `test` |        
| BUILD_TEMPLATE          |             | Name of the build template, default is: `buildtemplate-webapp.yaml` |
| DEPLOY_TEMPLATE         |             | Name of the deploy template, default is: `deploytemplate-webapp.yaml` |
| TESTRUNNER_TEMPLATE     |             | Name of the testrunner template, default is: `testrunnertemplate-pod.yaml` |
| ARTIFACT\_IMAGE\_SUFFIX |             | The suffix of the artifact ImageStream, default is `artifact` |
| GIT_URL                 | Yes         | URL to git repository | 
| GIT_CI_BRANCH           | Yes         | Branch in git repository | 
| TEST_PORT               |             | Test TCP port to use. Default is `8081` | 
| BUILD_TOOL              |             | The tool to build binaries with default is `shgradle` |
| CONTEXT_PATH            |             | The Web App context path, default is `ROOT`. _Please note: this setting is translated to the base-name of the Web App WAR file and not a path as such._ |
| HEALTH_URI              |             | The path (URI) to the health check service, default is `/`| 

**Conventions:**

* Required backing services such as mysql, activemq and redis are up and running, and mysql is expected to run in the same OCP project.
* Application database users must exists and have admin privileges in the actual database.
* A randomly named database is created for each test run, i.e. the application must honor the `DATABASE_NAME` environment variable. 
* The file `build-info.json` with versions, build arguments, tests etc is required in the source root folder 

**Outputs:**

* Upon a successful run an image reference is created in the ImageStream `${APP_NAME}-verified` and tagged with the `${buildVersion}` from trigger as well as with the `${RELESE_VERSION}.latest` tag.
* Test Reports are registered to Jenkins, requires plugin, see publishHTML.
* The source is tagged with version and build-number.

```
Intygstjanst:
oc process -f pipelinetemplate-build-webapp.yaml -p APP_NAME=intygstjanst -p RELEASE_VERSION=2020-2 -p GIT_URL=https://github.com/sklintyg/intygstjanst.git -p GIT_CI_BRANCH=release/2020-2 -p BUILD_TEMPLATE=buildtemplate-webapp-java11-binary.yaml -p BUILD_TOOL=shgradle11 -p CONTEXT_PATH="inera-certificate" -p HEALTH_URI="'/inera-certificate/services'" | oc apply  -f -
Intygsadmin:
oc process -f pipelinetemplate-build-webapp.yaml -p APP_NAME=intygsadmin -p RELEASE_VERSION=2020-2 -p GIT_URL=https://github.com/sklintyg/intygsadmin.git -p GIT_CI_BRANCH=release/2020-2 -p BUILD_TEMPLATE=buildtemplate-bootapp-binary.yaml -p BUILD_TOOL=shgradle11 -p HEALTH_URI="'/version.html'" -p TEST_PORT=8080 | oc apply  -f -
Logsender:
oc process -f pipelinetemplate-build-webapp.yaml -p APP_NAME=logsender -p RELEASE_VERSION=2020-2 -p GIT_URL=https://github.com/sklintyg/logsender.git -p GIT_CI_BRANCH=release/2020-2 -p BUILD_TEMPLATE=buildtemplate-webapp-java11-binary.yaml -p BUILD_TOOL=shgradle11 | oc apply  -f -
Mina Intyg:
oc process -f pipelinetemplate-build-webapp.yaml -p APP_NAME=minaintyg -p RELEASE_VERSION=2020-2 -p GIT_URL=https://github.com/sklintyg/minaintyg.git -p GIT_CI_BRANCH=release/2020-2 -p BUILD_TEMPLATE=buildtemplate-webapp-java11-binary.yaml -p BUILD_TOOL=shgradle11 | oc apply  -f -
Webcert:
oc process -f pipelinetemplate-build-webapp.yaml -p APP_NAME=webcert -p RELEASE_VERSION=2020-2 -p GIT_URL=https://github.com/sklintyg/webcert.git -p GIT_CI_BRANCH=release/2020-2 -p BUILD_TEMPLATE=buildtemplate-webapp-java11-binary.yaml -p BUILD_TOOL=shgradle11 | oc apply  -f -
Rehabstöd:
oc process -f pipelinetemplate-build-webapp.yaml -p APP_NAME=rehabstod -p RELEASE_VERSION=2020-2 -p GIT_URL=https://github.com/sklintyg/rehabstod.git -p GIT_CI_BRANCH=release/2020-2 -p BUILD_TEMPLATE=buildtemplate-webapp-java11-binary.yaml -p BUILD_TOOL=shgradle11 | oc apply  -f -
Privatläkarportal:
oc process -f pipelinetemplate-build-webapp.yaml -p APP_NAME=privatlakarportal -p RELEASE_VERSION=2020-2 -p GIT_URL=https://github.com/sklintyg/privatlakarportal.git -p GIT_CI_BRANCH=release/2020-2 -p BUILD_TEMPLATE=buildtemplate-webapp-java11-binary.yaml -p BUILD_TOOL=shgradle11 | oc apply  -f -
Statistik:
oc process -f pipelinetemplate-build-webapp.yaml -p APP_NAME=statistik -p RELEASE_VERSION=2020-2 -p GIT_URL=https://github.com/sklintyg/statistik.git -p GIT_CI_BRANCH=release/2020-2 -p BUILD_TEMPLATE=buildtemplate-webapp-java11-binary.yaml -p BUILD_TOOL=shgradle11 | oc apply  -f -
```
```
SRS:
oc process -f pipelinetemplate-build-webapp.yaml -p APP_NAME=srs -p RELEASE_VERSION=2020-2 -p GIT_URL=https://github.com/sklintyg/srs.git -p GIT_CI_BRANCH=release/2020-2 -p BUILD_TEMPLATE=buildtemplate-srsapp-binary.yaml -p HEALTH_URI="'/services'" -p TEST_PORT=8080 | oc apply  -f -
```

#### GitHub Webhooks
Each of these pipelines will have its own URL for webhook triggers. These can be copied from within the OpenShift console (in each respective DC configuration). But due to network issues, the previously mentioned webhookproxy must be used from outside of the cluster.

Replace the hostname of the copied webhooktrigger with the route-name of the webhookproxy.
```
Before:
https://ind-ocpt1a-api.ocp.sth.basefarm.net/apis/build.openshift.io/v1/namespaces/dintyg/buildconfigs/common-2020-2-pipeline/webhooks/********/github

After:
https://gitwebhookproxy-dintyg.ind-ocpt1a-app.ocp.sth.basefarm.net/apis/build.openshift.io/v1/namespaces/dintyg/buildconfigs/common-2020-2-pipeline/webhooks/********/github
```
Use the new URL in GitHub repo, or where needed.

_NOTE: This must be done for each repository/pipeline._

#### Template Scheduled Jobs 

Can be used to trigger a pipeline if Jenkins trigger isn't a viable option.

**Name:** jobtemplate

**Parameters:** 

| Parameter | Required | Description |
| --------- | -------- | ----------- |
| JOB_NAME      | Yes         | The name, ex: `housekeeping-trigger` |
| SCRIPT        | Yes         | The script to execute, currently are `bash` and `curl` available.  |        
| SCHEDULE      |             | Cron expression default is `0 3 * * *`, i.e. 3AM each night|

**Conventions:**

* Runs the script as is. 

**Outputs:**

* Depends on the script (script content is logged).

### Promote images to Nexus
Images created in previous builds are stored in imagestreams in the OpenShift project. These are only accessible from within the cluster. This poses a problem when builds are to be deployed in STAGE or PROD environment since they reside in a different OpenShift cluster. Because of this, images needs to be promoted/pushed to an "external" docker repo. This is achieved via `pipelinetemplate-promote-images.yaml`.

This pipeline is triggered manually when images are to be pushed to Nexus.

**Parameters:** 

| Parameter       | Required | Description |
| --------------- | -------- | ----------- |
| RELEASE_VERSION | Yes      | The release name, i.e. `2020-2` |
| IMAGES          |          | The images (with or without version) to be deployed. Defaults to `webcert,rehabstod,minaintyg,intygsadmin,intygstjanst,logsender,privatlakarportal,statistik`  |        
| GIT_URL         |          | DevopsRepo containing build-data. Defaults to `https://github.com/sklintyg/devops.git`|
| GIT_CI_BRANCH   | Yes      | The branch from devopsrepo to build from, i.e. `release/2020-2`|

```
oc process -f pipelinetemplate-promote-images.yaml -p RELEASE_VERSION=2020-2 -p GIT_CI_BRANCH=release/2020-2 | oc apply  -f -
```

### Nightly Demo Deploy Pipeline

TODO Will be handled by pipeline that triggers the predefined pipelines

# Access BF OpenShift Cluster

BF maintains two different OCP clusters, one for testing and one for production. Access to these require VPN-access and a personal BF account.

* OCP 3.9
    * TEST: https://portal-test1.ind-ocp.sth.basefarm.net
    * PROD: https://portal-prod1.ind-ocp.sth.basefarm.net
* OCP 3.11
    * TEST: https://ind-ocpt1a-api.ocp.sth.basefarm.net

##### OC client
For interacting with BF OpenShift make sure you use the `oc` client application provided by Red Hat, and not the Origin one. These can be obtained by asking BF. Make sure you use the correct version depending on which OCP version you're interacting with i.e. 3.9, 3.11 or any future version.

