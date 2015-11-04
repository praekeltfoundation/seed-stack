#!/bin/bash -e
set -x

service zookeeper restart
service mesos-master restart
service marathon restart
service mesos-slave restart

supervisorctl reload
