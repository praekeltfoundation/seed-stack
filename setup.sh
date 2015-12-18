#!/bin/bash -e

command_exists() {
    command -v $1 >/dev/null 2>&1
}

command_exists vagrant || {
    echo "The 'vagrant' executable could not be found. Please make sure Vagrant is installed."
    exit 1
}

if ! vagrant plugin list | fgrep "vagrant-host-shell"; then
    vagrant plugin install vagrant-host-shell
else
    echo "'vagrant-host-shell' Vagrant plugin already installed..."
fi

command_exists ruby || {
    echo "The 'ruby' executable could not be found. Please make sure Ruby 1.9.x - 2.1.x is installed."
    exit 1
}

RUBY_VERSION="$(ruby --version | cut -d' ' -f 2)"
RUBY_MAJ_VERSION="${RUBY_VERSION:0:3}"
echo "Ruby version detected: '$RUBY_VERSION' - major version: '$RUBY_MAJ_VERSION'"

if [[ ! "1.9 2.0 2.1" =~ "$RUBY_MAJ_VERSION" ]]; then
    echo "Ruby major version '$RUBY_MAJ_VERSION' not supported. Please make sure Ruby 1.9.x - 2.1.x is installed."
    exit 1
fi

command_exists gem || {
    echo "The 'gem' executable could not be found. Please make sure Rubygems is installed."
    exit 1
}

if ! gem list -i r10k >/dev/null; then
    echo "Installing 'r10k' gem..."
    gem install r10k
else
    echo "'r10k' Ruby gem already installed..."
fi

command_exists r10k || {
    echo "The 'r10k' executable could not be found. Please make sure the Ruby gem binary directory is in your PATH."
    exit 1
}

echo "Everything looks good to go! Try running 'vagrant up'."
