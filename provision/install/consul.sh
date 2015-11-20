#!/bin/bash -e
set -x

# DEPENDENCIES: supervisor

CONSUL_VERSION="0.5.2"
CONSUL_WEB_UI_VERSION=$CONSUL_VERSION
CONSUL_TEMPLATE_VERSION="0.11.1"

apt-get install unzip

# Install consul and consul-template
mkdir -p /tmp/consul
mkdir -p /usr/share/consul

wget -P /tmp/consul -qc https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_amd64.zip
unzip -d /tmp/consul/ /tmp/consul/consul_${CONSUL_VERSION}_linux_amd64.zip
mv /tmp/consul/consul /usr/local/bin/consul

wget -P /tmp/consul -qc https://releases.hashicorp.com/consul/${CONSUL_WEB_UI_VERSION}/consul_${CONSUL_WEB_UI_VERSION}_web_ui.zip
unzip -d /tmp/consul/ /tmp/consul/consul_${CONSUL_WEB_UI_VERSION}_web_ui.zip
if [ -d /usr/share/consul/ui ]; then
    rm -rf /usr/share/consul/ui
fi
mv /tmp/consul/dist /usr/share/consul/ui

wget -P /tmp/consul -qc https://releases.hashicorp.com/consul-template/${CONSUL_TEMPLATE_VERSION}/consul-template_${CONSUL_TEMPLATE_VERSION}_linux_amd64.zip
unzip -d /tmp/consul/ /tmp/consul/consul-template_${CONSUL_TEMPLATE_VERSION}_linux_amd64.zip
mv /tmp/consul/consul-template /usr/local/bin/consul-template
rm -rf /tmp/consul

apt-get purge -y --auto-remove unzip

# Copy over the config
source /vagrant/provision/install/copy-config.sh
copy_config /etc/consul.d/server /etc/consul.d/consul-template
supervisorctl restart consul consul_template
