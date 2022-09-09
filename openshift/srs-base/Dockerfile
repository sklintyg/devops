FROM docker-registry.default.svc:5000/dintyg/springboot-base:latest

USER root
ENV R_HOME=/opt/R/4.1.3/bin/R
ENV JVM_OPTS="-Djava.library.path=$R_HOME/library/rJava/jri"

RUN yum -y install epel-release

RUN curl -O https://cdn.rstudio.com/r/centos-7/pkgs/R-4.1.3-1-1.x86_64.rpm
RUN yum -y install R-4.1.3-1-1.x86_64.rpm

RUN ln -s /opt/R/4.1.3/bin/R /usr/local/bin/R
RUN ln -s /opt/R/4.1.3/bin/Rscript /usr/local/bin/Rscript

RUN yum -y install libjpeg-turbo-devel
RUN yum -y install libpng-devel

RUN R -e 'install.packages("rJava",,"http://www.rforge.net/")'
RUN R -e 'install.packages("jpeg",,"https://cran.r-project.org")'
RUN R -e 'install.packages("png",,"https://cran.r-project.org")'
RUN R -e 'install.packages("Rcpp",,"https://cran.r-project.org")'
RUN R -e 'install.packages("https://cran.r-project.org/src/contrib/Archive/RcppEigen/RcppEigen_0.3.3.9.1.tar.gz", repos=NULL, type="source")'
RUN R -e 'install.packages("pch",,"https://cran.r-project.org")'

RUN rm /opt/app/bin/launch.sh
ADD launch.sh /opt/app/bin/
RUN chmod 755 /opt/app/bin/launch.sh

USER nobody
