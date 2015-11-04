#!/bin/bash -e
set -x

apt-key adv --keyserver keyserver.ubuntu.com --recv E56151BF
echo "deb http://repos.mesosphere.io/debian jessie main" > /etc/apt/sources.list.d/mesosphere.list
echo "deb http://http.debian.net/debian jessie-backports main" > /etc/apt/sources.list.d/jessie-backports.list

apt-key adv --keyserver hkp://pgp.mit.edu:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
echo "deb http://apt.dockerproject.org/repo debian-jessie main" > /etc/apt/sources.list.d/docker.list

apt-get update
apt-get upgrade -y

apt-get install -y python2.7 python-virtualenv
# Tell dpkg not to overwrite our config files
apt-get install -y -o Dpkg::Options::="--force-confold" marathon mesos
apt-get install -y -o Dpkg::Options::="--force-confold" supervisor

apt-get install -y docker-engine
apt-get install -y nginx
apt-get install -y python-pip
apt-get install -y python-dev
apt-get install -y unzip
apt-get install -y curl jq
pip install "pyasn1>=0.1.8"
pip install consular

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

usermod -aG docker vagrant
