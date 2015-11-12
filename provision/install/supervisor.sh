#!/bin/bash -e
set -x

# Install supervisor
apt-get install -y supervisor

# Copy over the config
source /vagrant/provision/install/copy-config.sh
copy_config /etc/supervisor /etc/supervisor/conf.d
service supervisor restart
