#!/bin/bash -e
set -x

# Tell dpkg not to overwrite our config files when installing supervisor
apt-get install -y -o Dpkg::Options::="--force-confold" supervisor
rm /etc/supervisor/*.dpkg-dist

# Copy over the config
source /vagrant/provision/copy_config.sh
copy_config /etc/supervisor
