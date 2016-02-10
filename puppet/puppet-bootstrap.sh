#!/bin/bash -e

PUPPET_VERSION=${1?"Please suppply '3' or '4' as the puppet version."}

ENVDIR='/vagrant/puppet/environments/seed_stack'

case $PUPPET_VERSION in
    '3')
        deb='puppetlabs-release-trusty.deb'
        puppet_remove=''
        puppet_install='apt-get install -qy puppet'
    ;;
    '4')
        deb='puppetlabs-release-pc1-trusty.deb'
        puppet_remove='apt-get remove -qy puppet'
        puppet_install='apt-get install -qy puppet-agent'
    ;;
esac

# Set up puppetlabs repos.
wget -c https://apt.puppetlabs.com/${deb}
dpkg -i ${deb}
apt-get update

# Upgrade to new puppet and install some dependencies.
${puppet_remove}
${puppet_install}
apt-get autoremove -qy
apt-get install -qy --no-install-recommends bundler git ruby-dev


# Install puppet modules
cd /vagrant/puppet
bundle install --without test
bundle exec librarian-puppet install --verbose --path=${ENVDIR}/modules
