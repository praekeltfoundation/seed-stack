#!/bin/bash -e
set -x

# Mesosphere repo for Mesos and Marathon
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E56151BF
echo "deb http://repos.mesosphere.io/ubuntu trusty main" > /etc/apt/sources.list.d/mesosphere.list

# Docker repo
apt-key adv --keyserver hkp://pgp.mit.edu:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
echo "deb http://apt.dockerproject.org/repo ubuntu-trusty main" > /etc/apt/sources.list.d/docker.list

# Web Upd8 PPA for Oracle Java 8 for Marathon 0.11+
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 7B2C3B0889BF5709A105D03AC2518248EEA14886
echo "deb http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main" > /etc/apt/sources.list.d/webupd8team-java-trusty.list

# Upgrade the system
apt-get update
apt-get upgrade -y

# Install python things
apt-get install -y \
    python2.7 \
    python-dev \
    python-pip \
    python-virtualenv

# Install Java 8 after accepting the license agreement
echo "oracle-java8-installer shared/accepted-oracle-license-v1-1 select true" | /usr/bin/debconf-set-selections
apt-get install -y oracle-java8-installer

# Tell dpkg not to overwrite our config files when installing mesos, marathon and supervisor
apt-get install -y -o Dpkg::Options::="--force-confold" \
    marathon \
    mesos \
    supervisor

# Install docker and nginx
apt-get install -y \
    docker-engine \
    nginx-light \
    unzip

# Curl and jq are useful to have
apt-get install -y \
    curl \
    jq

# Install consular
apt-get install -y libffi-dev
pip install consular

# Install consul and consul-template
mkdir -p /tmp/consul
mkdir -p /usr/share/consul

wget -P /tmp/consul -qc https://releases.hashicorp.com/consul/0.5.2/consul_0.5.2_linux_amd64.zip
unzip -d /tmp/consul/ /tmp/consul/consul_0.5.2_linux_amd64.zip
mv /tmp/consul/consul /usr/local/bin/consul

wget -P /tmp/consul -qc https://releases.hashicorp.com/consul/0.5.2/consul_0.5.2_web_ui.zip
unzip -d /tmp/consul/ /tmp/consul/consul_0.5.2_web_ui.zip
mv /tmp/consul/dist /usr/share/consul/ui

wget -P /tmp/consul -qc https://releases.hashicorp.com/consul-template/0.11.1/consul-template_0.11.1_linux_amd64.zip
unzip -d /tmp/consul/ /tmp/consul/consul-template_0.11.1_linux_amd64.zip
mv /tmp/consul/consul-template /usr/local/bin/consul-template
rm -rf /tmp/consul

# Add the vagrant user to the docker group so that the docker commands can be used without sudo
usermod -aG docker vagrant
