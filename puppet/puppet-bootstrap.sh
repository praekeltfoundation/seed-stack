#!/bin/bash -e
# First some dependencies
apt-get install -qy --no-install-recommends bundler git ruby-dev

# Install gems
bundle install --without test

# Install Puppet modules
bundle exec librarian-puppet install --verbose
