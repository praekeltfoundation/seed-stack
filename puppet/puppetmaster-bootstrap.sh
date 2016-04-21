#!/bin/bash -e

PUPDIR=/etc/puppetlabs/code
ENVDIR=${PUPDIR}/environments/production

apt-get install -qy --no-install-recommends puppetserver bundler git ruby-dev

# Copy our puppet configs over.
# cp /vagrant/puppet/hiera.yaml ${PUPDIR}/
cp -a /vagrant/puppet/environments/seed_stack ${ENVDIR}

# Install puppet modules.
cd /vagrant/puppet
bundle install --without test
bundle exec librarian-puppet install --verbose --path=${ENVDIR}/modules

# We're a little VM, no need for gigs of reserved memory.
sed -i \
    -e 's/-Xm\([sx]\)\w\+/-Xm\1256m/g' \
    /etc/default/puppetserver

echo '*.seed-stack.local' > /etc/puppetlabs/puppet/autosign.conf

service puppetserver start

# Get our hands on the key to all the machines.
cd $HOME
cp /vagrant/.vagrant/dcos/private_key_vagrant ssh_key
chmod 600 ssh_key
