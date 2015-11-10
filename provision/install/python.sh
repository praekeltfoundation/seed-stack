#!/bin/bash -e
set -x

apt-get install -y python2.7

# Install the latest version of pip
apt-get install -y curl ca-certificates
curl -SL 'https://bootstrap.pypa.io/get-pip.py' | python
