#!/bin/bash -e
set -x

# Add all the extra repos we'll need to avoid unnecessary `apt-get update` runs.

# Web Upd8 PPA for Oracle Java 8 for Marathon 0.11+
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 7B2C3B0889BF5709A105D03AC2518248EEA14886
echo "deb http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main" > /etc/apt/sources.list.d/webupd8team-java-trusty.list

# Docker repo
apt-key adv --keyserver hkp://pgp.mit.edu:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
echo "deb http://apt.dockerproject.org/repo ubuntu-trusty main" > /etc/apt/sources.list.d/docker.list

# Mesosphere repo for Mesos and Marathon
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E56151BF
echo "deb http://repos.mesosphere.io/ubuntu trusty main" > /etc/apt/sources.list.d/mesosphere.list

apt-get update
# No need to upgrade. We assume we're using a recent base image and this is a
# local test stack where being a little behind on security updates isn't the
# end of the world.

# Install the things we want/need.

/vagrant/provision/install/python.sh
/vagrant/provision/install/java8.sh
/vagrant/provision/install/marathon.sh
/vagrant/provision/install/docker.sh

# Install nginx
apt-get install -y nginx-light

# Curl and jq are useful to have
apt-get install -y \
    curl \
    jq

/vagrant/provision/install/supervisor.sh
/vagrant/provision/install/consular.sh
/vagrant/provision/install/consul.sh
/vagrant/provision/install/consul-dns.sh
