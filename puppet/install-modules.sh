#!/bin/bash -e

# Install the upstream Puppet modules using librarian-puppet (and install that
# beforehand if it hasn't been installed yet).

if ! gem list -i librarian-puppet >/dev/null; then
    echo "Installing 'librarian-puppet' Ruby gem..."
    gem install --no-ri --no-rdoc librarian-puppet
else
    echo "'librarian-puppet' Ruby gem already installed..."
fi

librarian-puppet install --verbose --path=upstream_modules
