FROM docker-registry.default.svc:5000/dintyg/springboot-base:latest

USER root

# Set which R version to use
ENV R_VERSION="4.1.3"

ENV JAVA_HOME="/usr/lib/jvm/java-11-openjdk/"
ENV R_HOME="/opt/R/${R_VERSION}/lib/R"
ENV JVM_OPTS="-Djava.library.path=$R_HOME/library/rJava/jri"
ENV LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$R_HOME/lib:/usr/lib/jvm/java-11-openjdk-11.0.16.0.8-1.el7_9.x86_64/lib/server"

# Enable the Extra Packages for Enterprise Linux (EPEL) repository
RUN yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm

# Enable the optional repository from Red Hat Update Infrastructure (RHUI)
RUN yum -y install yum-utils
RUN yum-config-manager --enable "rhel-*-optional-rpms"

# Install R
RUN curl -O https://cdn.rstudio.com/r/centos-7/pkgs/R-${R_VERSION}-1-1.x86_64.rpm
RUN yum -y install R-${R_VERSION}-1-1.x86_64.rpm

# To ensure that R is available on the default system PATH variable, create symbolic links to the version of R
RUN ln -s /opt/R/${R_VERSION}/bin/R /usr/local/bin/R
RUN ln -s /opt/R/${R_VERSION}/bin/Rscript /usr/local/bin/Rscript

# Update java configuration for R
RUN R CMD javareconf

# Install tools required to compile R packages below
RUN yum -y install libjpeg-turbo-devel
RUN yum -y install libpng-devel

# Install required packages
RUN R -e 'install.packages("rJava",,"http://www.rforge.net/")'
RUN R -e 'install.packages("pch",,"https://cran.r-project.org")'

# Replace launch.sh to make sure that the correct java version is used
RUN rm /opt/app/bin/launch.sh
ADD launch.sh /opt/app/bin/

# Update permissions for launch.sh
RUN chmod 755 /opt/app/bin/launch.sh

USER nobody
