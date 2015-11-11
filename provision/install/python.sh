#!/bin/bash -e
set -x

apt-get install -y python2.7

# Install pip, avoiding the recommended dev dependencies and then updating
apt-get install -y --no-install-recommends python-pip
pip install --upgrade pip
