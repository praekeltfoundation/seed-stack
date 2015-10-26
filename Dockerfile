FROM debian:jessie
MAINTAINER Praekelt Foundation <dev@praekeltfoundation.org>
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv E56151BF
RUN echo "deb http://repos.mesosphere.io/debian jessie main" | tee /etc/apt/sources.list.d/mesosphere.list
RUN echo "deb http://http.debian.net/debian jessie-backports main" | tee /etc/apt/sources.list.d/jessie-backports.list
RUN apt-get update
RUN apt-get install -y marathon mesos python2.7 python-virtualenv
