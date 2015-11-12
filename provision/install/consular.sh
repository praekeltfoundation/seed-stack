#!/bin/bash -e
set -x

# Install dependencies for building Twisted and cryptography
apt-get install -y build-essential libssl-dev libffi-dev python-dev

# Install consular
pip install consular

# Remove the build-time dependencies
apt-get purge -y --auto-remove build-essential libssl-dev libffi-dev python-dev

# Install the run-time dependencies
apt-get install -y libffi6 openssl

# Copy over the config
source /vagrant/provision/copy_config.sh
copy_config /etc/consular
