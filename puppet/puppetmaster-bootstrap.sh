#!/bin/bash -e

PUPDIR=/etc/puppetlabs/code
ENVDIR=${PUPDIR}/environments/production
VGRDIR=/vagrant/puppet

if dpkg-query -l puppetserver > /dev/null; then
    echo "Found puppetserver package."
else
    echo "Installing puppetserver package and related things."
    apt-get install -qy --no-install-recommends \
            puppetserver bundler git ruby-dev
fi

# Copy our puppet configs over.
cp -a ${VGRDIR}/environments/seed_stack/{environment.conf,manifests} ${ENVDIR}/

# This is a bit expensive, so only do it if the server isn't already running.
if service puppetserver status > /dev/null; then
    echo "Found running puppetserver, not configuring or installing modules."
else
    echo "Configuring puppetserver and installing modules."

    # Install puppet modules.
    cd /vagrant/puppet
    bundle install --without test
    bundle exec librarian-puppet install --verbose --path=${ENVDIR}/modules

    # We're a little VM, no need for gigs of reserved memory.
    sed -i \
        -e 's/-Xm\([sx]\)\w\+/-Xm\1192m/g' \
        /etc/default/puppetserver

    echo '*.seed-stack.local' > /etc/puppetlabs/puppet/autosign.conf

    service puppetserver start
fi
