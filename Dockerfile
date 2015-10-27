FROM debian:jessie
MAINTAINER Praekelt Foundation <dev@praekeltfoundation.org>
# Mesos, Marathon & Java stuff
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv E56151BF
RUN echo "deb http://repos.mesosphere.io/debian jessie main" | tee /etc/apt/sources.list.d/mesosphere.list
RUN echo "deb http://http.debian.net/debian jessie-backports main" | tee /etc/apt/sources.list.d/jessie-backports.list

# Docker stuff
RUN apt-key adv --keyserver hkp://pgp.mit.edu:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
RUN echo "deb http://apt.dockerproject.org/repo debian-jessie main" | tee /etc/apt/sources.list.d/docker.list

# Install all the things
RUN apt-get update
RUN apt-cache policy docker-engine
RUN apt-get install -y marathon mesos python2.7 python-virtualenv
RUN apt-get install -y supervisor
RUN apt-get install -y docker-engine

# Etc config files
COPY ./etc/supervisor /etc/supervisor
COPY ./etc/mesos /etc/mesos
COPY ./etc/mesos-master /etc/mesos-master
COPY ./etc/mesos-slave /etc/mesos-slave
COPY ./etc/marathon /etc/marathon

VOLUME /tmp/mesos

COPY ./docker-entrypoint.sh /docker-entrypoint.sh

# Comment this line to instead end up with a bash shell
ENTRYPOINT ["/docker-entrypoint.sh"]
