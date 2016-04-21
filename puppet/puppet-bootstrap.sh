#!/bin/bash -e

deb='puppetlabs-release-pc1-trusty.deb'

wget -c https://apt.puppetlabs.com/${deb}
dpkg -i ${deb}
apt-get update
apt-get remove -qy puppet
apt-get install -qy puppet-agent
apt-get autoremove -qy

# Symlink puppet into /usr/sbin because sudo and $PATH.
if [ -x /opt/puppetlabs/bin/puppet -a ! -e /usr/sbin/puppet ]; then
    ln -s /opt/puppetlabs/bin/puppet /usr/sbin/puppet
    # We need to install this where puppet's ruby can find it.
    /opt/puppetlabs/puppet/bin/gem install --no-ri --no-rdoc inifile
fi
