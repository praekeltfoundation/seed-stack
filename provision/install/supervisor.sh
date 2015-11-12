#!/bin/bash -e
set -x

# Install supervisor
apt-get install -y supervisor

# Copy over the config
source /vagrant/provision/copy_config.sh
copy_config /etc/supervisor
service supervisor restart
