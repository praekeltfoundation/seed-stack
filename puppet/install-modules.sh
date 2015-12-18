#!/bin/bash -e

# Install the upstream Puppet modules using r10k (and install that beforehand if
# it hasn't been installed yet.)

if ! gem list -i r10k >/dev/null; then
    echo "Installing 'r10k' Ruby gem..."
    gem install --no-ri --no-rdoc r10k
else
    echo "'r10k' Ruby gem already installed..."
fi

r10k puppetfile install --verbose info --puppetfile /vagrant/puppet/Puppetfile
