#!/bin/bash -e
set -x

# Install dependencies for building Twisted and cryptography
apt-get install -y build-essential libssl-dev libffi-dev python-dev

# Install consular
pip install consular

# Remove the build-time dependencies
apt-get purge -y --auto-remove build-essential libssl-dev libffi-dev python-dev

# Install the run-time dependencies
apt-get install -y libffi6 openssl

# Copy over the config
CONF_DIRS=(/etc/consular)
for dir in $CONF_DIRS; do
    mkdir -p "$dir"
    for src in $(find "/vagrant${dir}" -type f -maxdepth 1); do
        cp "$src" "$dir/$(basename $src)"
    done
done
