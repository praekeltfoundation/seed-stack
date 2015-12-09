#!/bin/bash -e
set -x

# DEPENDENCIES: python, java8

# We do this in install.sh to avoid unnecessary `apt-get update` runs.

# # Mesosphere repo for Mesos and Marathon
# apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E56151BF
# echo "deb http://repos.mesosphere.io/ubuntu trusty main" > /etc/apt/sources.list.d/mesosphere.list
# apt-get update

# Install mesos/marathon
apt-get install -y \
    marathon \
    mesos

# Copy over the config
source /vagrant/provision/install/copy-config.sh
copy_config /etc/mesos /etc/mesos-master /etc/mesos-slave /etc/marathon/conf

# Restart the services to reload the config
service mesos-master restart
service mesos-slave restart
service marathon restart
