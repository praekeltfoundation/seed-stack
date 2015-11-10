#!/bin/bash -e
set -x

# DEPENDENCIES: consul

# Get Dnsmasq to forward all DNS queries ending in 'consul' to Consul
NAMESERVER='10.0.2.3' # VirtualBox DNS

apt-get install -y dnsmasq

echo "nameserver $NAMESERVER" >  /etc/resolv.primary
echo -e "resolv-file=/etc/resolv.primary\ncache-size=0" > /etc/dnsmasq.conf
echo "server=/consul/127.0.0.1#8600" > /etc/dnsmasq.d/consul
service dnsmasq restart

# Make Docker containers use the host for DNS queries
DOCKER0_IP="$(ip addr show dev docker0 | grep -o 'inet [0-9.]\+' | cut -c6-)"
echo "DOCKER_OPTS=\"--dns $DOCKER0_IP\"" > /etc/default/docker
service docker restart
