#!/bin/bash -e
set -x

service zookeeper stop
update-rc.d -f zookeeper remove
service zookeeper restart

service mesos-master stop
update-rc.d -f mesos-master remove
service mesos-master restart
service marathon restart

service mesos-slave stop
update-rc.d -f mesos-slave remove
service mesos-slave restart

supervisorctl reload
