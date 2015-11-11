#!/bin/bash -e
set -x

# DEPENDENCIES: python, java8

# Mesosphere repo for Mesos and Marathon
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E56151BF
echo "deb http://repos.mesosphere.io/ubuntu trusty main" > /etc/apt/sources.list.d/mesosphere.list
apt-get update

# Tell dpkg not to overwrite our config files when installing mesos and marathon
apt-get install -y -o Dpkg::Options::="--force-confold" \
    marathon \
    mesos
rm /etc/mesos-master/*.dpkg-dist