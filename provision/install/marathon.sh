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

# Copy over the config
CONF_DIRS=(/etc/mesos /etc/mesos-master /etc/mesos-slave /etc/marathon/conf)
for dir in $CONF_DIRS; do
    mkdir -p "$dir"
    for src in $(find "/vagrant${dir}" -type f -maxdepth 1); do
        cp "$src" "$dir/$(basename $src)"
    done
done
