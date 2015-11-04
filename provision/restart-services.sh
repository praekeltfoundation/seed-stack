#!/bin/bash -e
set -x

service zookeeper restart
service mesos-master restart
service marathon restart
service mesos-slave restart

service supervisor restart
supervisorctl update

service nginx reload
