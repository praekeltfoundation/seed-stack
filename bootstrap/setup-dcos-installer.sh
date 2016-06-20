#!/bin/bash -e

mkdir -p /root/dcos/genconf

cat <<'EOF' > /root/dcos/genconf/ip-detect
#!/usr/bin/env bash
set -o nounset -o errexit
echo $(ip route show to match 192.168.55.0 |\
    grep -Eo '[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}' | tail -1)
EOF

cp /vagrant/dcos_generate_config.sh /root/dcos/
