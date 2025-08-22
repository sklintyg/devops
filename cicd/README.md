
## Downloading and running Jenkins in Docker
The setup of Jenkins and Docker in a local container envionment is largely based on
https://www.jenkins.io/doc/book/installing/docker/ \
https://yetkintimocin.medium.com/creating-a-local-jenkins-server-using-docker-2e4dfe7b5880

## Clone the devops repo from Intygstjanster
Clone the Intygstjanster devops repo into a suitable location (for example /repos/intyg) in WSL
Ubuntu distro. For easy editing of code, set up a project in Intellij in Windows and point to the
repo in WSL (example path: \\wsl$\Ubuntu-22.04\repos\intyg).

cd into the nexus directory and run\
chmod 777 -R data\
chmod 777 -R work

## Project structure
There are number of mounted folders for the different applications. Reason for this is in part to
be able to access data easily in the Intellij project but also to keep the size of the containers
at reasonable levels. Especially the docker registry is likely to consume a lot of memory
since it holds all images pushed from Jenkins piplines.

```
docker-compose
├── docker-compose.yaml
├── jenkins
│   ├── data
│   └── docker
│       └── Dockerfile
├── nexus
│   ├── data
│   └── work
├── registry
│   ├── auth
│   │   ├── host-docker-internal.crt
│   │   └── host-docker-internal.key
│   └── data
└── sonarqube
    ├── data
    ├── extensions
    └── logs
```


## Clone the Jenkins library used in Nationella Jenkins
To simulate work in Nationella Jenkins the code library there used should also be avialable in
the local Jenkins environment. To achieve this clone the Jenkins library to a suitable
location and add the whole repo as mounted volume in the local Jenkins.

Example in Ubuntu WSL\
```cd /repos/jenkins-library```\
```git clone https://bitbucket.drift.inera.se/scm/jenkins/jenkins-library.git```

In docker-compose.yaml, add the following row in the volumes section of the Jenkins service to
be able to access it at location /jenkins-library in the Jenkins container. (The :ro at the end
means read-only).

```- /repos/jenkins-library:/jenkins-library:ro```


## Setup Jenkins application
In a Windows browser, go to localhost:49000 to find the Jenkins GUI and follow on-screen
instructions. To unlock Jenkins, find administrator password in folder /var/jenkins_home/secrets/initialAdminPassword
either by ```docker exec it <container-id> bash``` into the container or in the Intellij project
under cicd/docker-compose/jenkins/data/secrets/initialAdminPassword.

Add the jenkins-library intrduced into the container via the mount from WSL. In Jenkins,
go to \
```Manage Jenkins -> Configure System -> Global Pipeline Libraries``` and choose to add a library.

    Name: essLib
    Default version: master
    Keep checkboxes default
    Retrieval method: Modern SCM
    Source code management: Git
    Project-repository: /jenkins-library (if using the mount from previous section)

Add plugin ```config-file-provider``` to be able to use the JenkinsProperties file used by
the jenkins-library for holding various config.

Add plugin ```pipeline-utility-steps``` which contributes further functionality used by the
jenkins-library.


## Freeing up memory in docker, the docker registry and the WSL distro

### Cleaning up in docker
To remove all unused containers, networks, images (both dangling and unreferenced), and optionally,
volumes, system prune can be run.

```docker system prune (use option --volumes to also prune volumes)```

There are also specific prune commands for cleaning images, containers etc separately.
docker prune container/image/network/volumes

https://docs.docker.com/engine/reference/commandline/system_prune/


### Cleaning in WSL
Apparently Windows does not automatically reclaim memory even when a large amount of data
has been deleted in WSL. To reclaim freed memory for Windows, perform manual compaction
of the virtual hard drive.

In PowerShell with admin rights:
1. cd into ~\AppData\Local\Packages\CanonicalGroupLimited.Ubuntu22.04LTS_79rhkp1fndgsc\LocalState
   (or something with a similar name containing the wsl distro).

2. Run ```wsl --shutdown```

3. Run ```optimize-vhd -Path .\ext4.vhdx -Mode full```

https://ryanharrison.co.uk/2021/05/13/wsl2-better-managing-system-resources.html


### Cleaning the registry


With time the docker registry might consume quite a lot of memory.

Run ```docker ps``` to find the id of the registry container\
Run ```docker exec -it <container-id> sh``` (prefer bash instead of shell if it exists)\
Run ```registry garbage-collect -m /etc/docker/registry/config.yml```

Note: the -m option is probably same as ----delete-untagged

https://docs.docker.com/registry/garbage-collection/



## Setting the size memory size in WSL
In Windows in the User folder, create a file name .wslconfig add the below content:\

    [wsl2]\
    memory=16GB\
    processors=8\




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
