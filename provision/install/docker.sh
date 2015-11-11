#!/bin/bash -e
set -x

# Docker repo
apt-key adv --keyserver hkp://pgp.mit.edu:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
echo "deb http://apt.dockerproject.org/repo ubuntu-trusty main" > /etc/apt/sources.list.d/docker.list
apt-get update

apt-get install -y docker-engine

# Add the vagrant user to the docker group so that the docker commands can be used without sudo
usermod -aG docker vagrant
