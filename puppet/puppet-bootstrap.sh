#!/bin/bash -e

PUPPET_VERSION=${1:-nothing}

ENVDIR='/vagrant/puppet/environments/seed_stack'

case $PUPPET_VERSION in
    '3.4')
        deb=''
        ;;
    '3.8')
        deb='puppetlabs-release-trusty.deb'
        puppet_remove=''
        puppet_install='apt-get install -qy puppet'
        ;;
    '4')
        deb='puppetlabs-release-pc1-trusty.deb'
        puppet_remove='apt-get remove -qy puppet'
        puppet_install='apt-get install -qy puppet-agent'
        ;;
    *)
        echo "Please suppply '3.4', '3.8', or '4' as the puppet version."
        exit 1
esac

# Set up puppetlabs repos and upgrade puppet if necessary.
if [ -n "${deb}" ]; then
    wget -c https://apt.puppetlabs.com/${deb}
    dpkg -i ${deb}
    sourcelist=$(echo /etc/apt/sources.list.d/puppetlabs*.list)
    apt-get update \
            -o Dir::Etc::sourcelist="${sourcelist}" \
            -o Dir::Etc::sourceparts="-" \
            -o APT::Get::List-Cleanup="0"
    ${puppet_remove}
    ${puppet_install}
    apt-get autoremove -qy
fi

# If we're using Puppet 4.x, symlink it into /usr/sbin because sudo and $PATH.
if [ -x /opt/puppetlabs/bin/puppet -a ! -e /usr/sbin/puppet ]; then
   ln -s /opt/puppetlabs/bin/puppet /usr/sbin/puppet
fi

# Install some dependencies.
apt-get install -qy --no-install-recommends bundler git ruby-dev

# Install puppet modules
cd /vagrant/puppet
bundle install --without test
bundle exec librarian-puppet install --verbose --path=${ENVDIR}/modules
