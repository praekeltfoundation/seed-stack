class marathon(
  $ensure         = 'present',
  $zookeeper      = undef,
  $master         = undef,
  $owner          = 'root',
  $group          = 'root',
  $options        = {},
  ) {

  require ::mesos::master

  class { 'marathon::config':
    zookeeper => $zookeeper,
    master    => $master,
    owner     => $owner,
    group     => $group,
    options   => $options,
  }

  package { 'marathon':
    ensure  => $ensure,
    name    => 'marathon',
    require => Class['apt::update'],
  }

  service { 'marathon':
    ensure     => 'running',
    hasstatus  => true,
    hasrestart => true,
    require    => Package['marathon'],
  }
}
