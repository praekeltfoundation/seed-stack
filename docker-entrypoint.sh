#!/bin/bash

echo "=> Starting Docker"
/usr/sbin/service docker start

echo "=> Starting Zookeeper"
/usr/sbin/service zookeeper start

echo "=> Starting Supervisord"
/usr/sbin/service supervisor start

echo "=> Tailing logs"
tail -qF /var/log/supervisor/*.log /var/log/zookeeper/*.log
