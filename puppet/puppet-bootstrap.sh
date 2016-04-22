#!/bin/bash -e

if [ -f /etc/apt/sources.list.d/puppetlabs-pc1.list ]; then
    echo "Found puppetlabs repo."
else
    echo "Setting up puppetlabs repo."
    deb='puppetlabs-release-pc1-trusty.deb'
    wget -c https://apt.puppetlabs.com/${deb}
    dpkg -i ${deb}
fi

if dpkg-query -l puppet-agent > /dev/null; then
    echo "Found puppet-agent package."
else
    echo "Installing puppet-agent package."
    apt-get update
    apt-get remove -qy puppet
    apt-get autoremove -qy
    apt-get install -qy puppet-agent
fi

# Symlink puppet into /usr/sbin because sudo and $PATH.
if [ -x /opt/puppetlabs/bin/puppet -a ! -e /usr/sbin/puppet ]; then
    ln -s /opt/puppetlabs/bin/puppet /usr/sbin/puppet
    # We need to install this where puppet's ruby can find it.
    /opt/puppetlabs/puppet/bin/gem install --no-ri --no-rdoc inifile
fi
