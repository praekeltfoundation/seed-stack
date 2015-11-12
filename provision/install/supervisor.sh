#!/bin/bash -e
set -x

# Tell dpkg not to overwrite our config files when installing supervisor
apt-get install -y -o Dpkg::Options::="--force-confold" supervisor
rm /etc/supervisor/*.dpkg-dist

# Copy over the config
CONF_DIRS=(/etc/supervisor)
for dir in $CONF_DIRS; do
    mkdir -p "$dir"
    for src in $(find "/vagrant${dir}" -type f -maxdepth 1); do
        cp "$src" "$dir/$(basename $src)"
    done
done
