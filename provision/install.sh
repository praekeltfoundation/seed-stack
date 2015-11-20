#!/bin/bash -e
set -x

# Upgrade the system
apt-get update
# FIXME: see issue #21
#apt-get upgrade -y

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
