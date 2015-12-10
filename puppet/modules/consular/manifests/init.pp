class consular {
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
    'openssl',
    'libffi6',
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
}
