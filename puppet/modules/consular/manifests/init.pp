class consular(
  $consular_args = [],
) {
  # NOTE: This is a temporary PPA that is managed manually by a single
  # individual in his personal capacity. It needs to be replaced with a better
  # one that gets automated package updates and such.
  apt::ppa { 'ppa:jerith/consular': ensure => 'present' }
  ->
  file { '/etc/init/consular.conf':
    content => template('consular/init.consular.conf.erb'),
  }
  ~>
  package { 'python-consular':
    ensure => 'latest',
    require => Class['apt::update'],
  }
  ~>
  service { 'consular':
    ensure => running,
  }
}
