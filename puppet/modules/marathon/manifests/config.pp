class marathon::config(
  $conf_dir  = '/etc/marathon/conf',
  $owner     = 'root',
  $group     = 'root',
  $zookeeper = undef,
  $master    = undef,
  $options   = {},
){

  # We need this because puppet can't make intermediate directories.
  file { '/etc/marathon':
    ensure => directory,
    owner  => $owner,
    group  => $group,
  }

  file { $conf_dir:
    ensure => directory,
    owner  => $owner,
    group  => $group,
  }

  mesos::property { 'zk':
    value   => $zookeeper,
    dir     => $conf_dir,
    file    => 'zk',
    service => Service['marathon'],
    require => File[$conf_dir],
  }

  mesos::property { 'master':
    value   => $master,
    dir     => $conf_dir,
    file    => 'master',
    service => Service['marathon'],
    require => File[$conf_dir],
  }

  create_resources(mesos::property,
    mesos_hash_parser($options, 'marathon'),
    {
      dir     => $conf_dir,
      service => Service['marathon'],
    }
  )

}
