#!/bin/bash -e

ENVDIR='/vagrant/puppet/environments/seed_stack'

# Install some dependencies.
apt-get install -qy --no-install-recommends bundler git ruby-dev

# Install puppet modules
cd /vagrant/puppet
bundle install --without test
bundle exec librarian-puppet install --verbose --path=${ENVDIR}/modules
