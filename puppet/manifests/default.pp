node default {

  include oracle_java

  class { 'docker':
    dns => $ipaddress_docker0,
  }

  # We need this because mesos::install doesn't wait for apt::update before
  # trying to install the package.
  Class['apt::update'] -> Package['mesos']

  $mesos_zk = 'zk://localhost:2181/mesos'

  class { 'mesos':
    repo => 'mesosphere',
    zookeeper => $mesos_zk,
    require => Class['oracle_java'],
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
    require => Class['oracle_java'],
  }

  class { 'consul':
    config_hash => {
      'bootstrap_expect' => 1,
      'server'           => true,
      'data_dir'         => '/var/consul',
      'ui_dir'           => '/var/consul/ui',
      'log_level'        => 'INFO',
      'enable_syslog'    => true,
      'advertise_addr'   => $ipaddress_eth0,
      'client_addr'      => '0.0.0.0',
      'domain'           => 'consul.',
    },
    services => {
      'marathon'  => { port => 8080 },
      'mesos'     => { port => 5050 },
      'zookeeper' => { port => 2181 },
    },
  }

  class { 'consul_template':
    config_dir       => '/etc/consul-template',
    consul_host      => '127.0.0.1',
    consul_port      => 8500,
    consul_retry     => '10s',
    # For some reason, consul-template doesn't like this option.
    # consul_max_stale => '10m',
    log_level        => 'warn',
  }

  file { '/etc/consul-template/nginx-upstreams.ctmpl':
    source => 'puppet:///modules/consular/nginx-upstreams.ctmpl',
  }
  ~>
  consul_template::watch { 'nginx-upstreams':
    destination => '/etc/nginx/sites-enabled/seed-upstreams.conf',
    command     => '/etc/init.d/nginx reload',
  }

  file { '/etc/consul-template/nginx-websites.ctmpl':
    source => 'puppet:///modules/consular/nginx-websites.ctmpl',
  }
  ~>
  consul_template::watch { 'nginx-websites':
    destination => '/etc/nginx/sites-enabled/seed-websites.conf',
    command     => '/etc/init.d/nginx reload',
  }

  file { '/etc/consul-template/nginx-services.ctmpl':
    source => 'puppet:///modules/consular/nginx-services.ctmpl',
  }
  ~>
  consul_template::watch { 'nginx-services':
    destination => '/etc/nginx/sites-enabled/seed-services.conf',
    command     => '/etc/init.d/nginx reload',
  }

  package { 'nginx-light': }
  ~>
  service { 'nginx': }

  package { 'dnsmasq': }
  ~>
  file { '/etc/dnsmasq.d/consul':
    content => "cache-size=0\nserver=/consul/127.0.0.1#8600",
  }
  ~>
  service { 'dnsmasq': }

  class { 'consular':
    consular_args => [
      '--host=localhost',
      '--sync-interval=300',
      '--purge',
      '--registration-id=localhost',
      '--consul=http://localhost:8500',
      '--marathon=http://localhost:8080',
    ],
  }
}
