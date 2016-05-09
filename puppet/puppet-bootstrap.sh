#!/bin/bash -e


source /etc/os-release
osversion="$ID $VERSION_ID"
case ${osversion} in
    "debian 8")
        distid=jessie ;;
    "ubuntu 14.04")
        distid=trusty ;;
    *)
        echo "Unknown OS: ${osversion}" >2; exit 1 ;;
esac

if [ "$distid" = "jessie" ]; then
    if [ -f /etc/apt/sources.list.d/backports.list ]; then
        echo "Found jessie backports repo."
    else
        echo "Adding jessie backports repo."
        apt-get install apt-transport-https
        echo 'deb http://httpredir.debian.org/debian jessie-backports main contrib non-free' > /etc/apt/sources.list.d/backports.list
    fi
fi

if [ -f /etc/apt/sources.list.d/puppetlabs-pc1.list ]; then
    echo "Found puppetlabs repo."
else
    echo "Setting up puppetlabs repo."
    deb="puppetlabs-release-pc1-${distid}.deb"
    wget -c https://apt.puppetlabs.com/${deb}
    dpkg -i ${deb}
fi

if dpkg-query -l puppet-agent > /dev/null; then
    echo "Found puppet-agent package."
else
    echo "Installing puppet-agent package."
    apt-get update
    apt-get remove -qy puppet chef
    apt-get install -qy --auto-remove puppet-agent
fi

# Symlink puppet into /usr/sbin because sudo and $PATH.
if [ -x /opt/puppetlabs/bin/puppet -a ! -e /usr/sbin/puppet ]; then
    ln -s /opt/puppetlabs/bin/puppet /usr/sbin/puppet
    # We need to install this where puppet's ruby can find it.
    /opt/puppetlabs/puppet/bin/gem install --no-ri --no-rdoc inifile
fi
