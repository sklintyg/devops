# Intygstjanster application docker environment

## Intro
Intygstjanster is a collection of some 10-12 applications displaying varying degrees of interdependence.
Under some circumstances it might be of value to the development process to be able to pull the latest 
or some specific version of one (or several) application images and launch them in docker containers 
running in a local developer environment.

With very little configuration this docker environment makes it easy to spin up one or a few 
Intygstjanster-applications in docker containers running on a local computer. By simply
entering the script file (```startapps.sh```) and typing the (short) names of the applications
to be run in docker containers into the array named ```APPS``` at the top of the file, and then running
the script, the applications will be up and running in no time.

Once started the apps running in containers can interact with each other as well as with apps not
running in containers, but that has insread been started in the local environment.

## The launch script (startapps.sh)
Based on the contents of the array ```APPS``` at the top of the file, the ```startapps.sh```-script 
determines which apps to run in containers. Preparations are made for interaction with other applications
(if they are started) running in the Windows environment.

In the ```startapps.sh```-file, enter the names of the apps to be run in containers in the ```APPS```-array,
(nomenclature to use for app names can be found in the comments below the array definition). Start
the script by running command ```./startapps.sh``` from the folder where the script is located
(apps/docker-compose/startapps.sh)

## Running specific versions of applications
The registry to pull imaages from as well as the image version are specified in the respective
application container definitions in files frontend-apps.yaml, spring-apps.yam and
springboot-apps.yaml. Default docker registry is ```docker.drift.inera.se``` and default version to
pull is ```latest```. To pull from another registry or a different version just update the files
accordingly, e.g. ```localhost:5000/intyg/webcert:0.1.0.2```.

## Directory structure
In an attempt to reduce size and complexity of the environment configuration, the application
container definitions have been split into three different categories, being either frontend-applications,
Spring-applications or Springboot-applications. Files and folders associated with each category
are located in directories named frontend-apps, spring-apps and springboot-apps respectively,
all according to the directory tree shown below.

    apps
    └── docker-compose
        ├── frontend-apps
        │   └── frontend-apps.yaml
        ├── spring-apps
        │   ├── ...app dirs...
        │   ├── .spring-app-env
        │   └── spring-apps.yaml
        ├── springboot-apps
        │   ├── ...app dirs...
        │   └── springboot-apps.yaml
        ├── .env    
        ├── docker-compose.yaml
        └── startapps.sh

In addition to the docker container definition files ```(.yaml)``` seen in each of the directories,
the spring-apps and springboot-apps directories both have subfolders (represented by ```...app dirs...```
in the directory tree) for each of their respective applications, containaing exact copies of their
devops folders. Contents thus includes materials such as certificates, sp- and idp-metadata and config
files which are mounted as volumes into the containers.

Additionally, each application specific folder have a file named ```.<app>-env``` which holds
app specific configuration in the form of environment variables.
**The configuration in the ```.<app>-env```-files may be adjusted for fine-tuning the behaviour of
the application.**

At the root level of the base-directory there is a further ```.env```-type file, docker-compose.yaml
file which simply includes the yaml-configs from subdirectories and a script file ```startapps.sh```
which is used to launch the application docker environment.

## Disclaimer
This docker environment for Intygstjanster applications has been developed and tested on a Windows 10
machine running Docker in a WSL distribution using Ubuntu 22.04. Other setups might require measures not
described here to be performed for the environment to work properly.
