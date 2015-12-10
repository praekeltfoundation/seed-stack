node default {

  include oracle_java
  include docker

  # We need this because mesos::install doesn't wait for apt::update before
  # trying to install the package.
  Class['apt::update'] -> Package['mesos']

  $mesos_zk = 'zk://localhost:2181/mesos'

  class { 'mesos':
    repo => 'mesosphere',
    zookeeper => $mesos_zk,
  }

  class { 'mesos::master':
    options => {
      hostname => 'localhost',
      quorum => 1,
    },
  }

  class { 'mesos::slave':
    resources => {
      'ports(*)' => '[10000-10050]',
    },
    options => {
      hostname => 'localhost',
      containerizers => 'docker,mesos',
      executor_registration_timeout => '5mins',
    },
  }

  class { 'marathon':
    zookeeper => 'zk://localhost:2181/marathon',
    master => $mesos_zk,
    options => {
      hostname => 'localhost',
      event_subscriber => 'http_callback',
    },
  }

}
