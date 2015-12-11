class consular(
  $consular_args = [],
) {
  class { 'python' :
    version    => 'system',
    pip        => 'present',
    dev        => 'present',
    virtualenv => 'present',
    gunicorn   => 'absent',
  }

  package { [
    'build-essential',
    'libssl-dev',
    'libffi-dev',
  ]: }
  ->
  file { '/var/consular':
    ensure => directory,
  }
  ~>
  file { '/var/consular/requirements.txt':
    content => 'consular',
  }
  ~>
  python::virtualenv { '/var/consular/venv':
    requirements => '/var/consular/requirements.txt',
  }
  ~>
  file { '/etc/init/consular.conf':
    content => template('consular/init.consular.conf.erb'),
  }
  ~>
  service { 'consular':
    ensure => running,
  }
}
