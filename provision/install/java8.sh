#!/bin/sh -eux

# We do this in install.sh to avoid unnecessary `apt-get update` runs.

# # Web Upd8 PPA for Oracle Java 8 for Marathon 0.11+
# apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 7B2C3B0889BF5709A105D03AC2518248EEA14886
# echo "deb http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main" > /etc/apt/sources.list.d/webupd8team-java-trusty.list
# apt-get update

# Install Java 8 after accepting the license agreement
echo "oracle-java8-installer shared/accepted-oracle-license-v1-1 select true" | /usr/bin/debconf-set-selections
apt-get install -y oracle-java8-installer
