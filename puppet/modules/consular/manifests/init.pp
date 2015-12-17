class consular(
  $consular_args = [],
) {
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
