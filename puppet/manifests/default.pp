node default {

  $docker_ensure = '1.9.1*'
  $mesos_ensure = '0.24.1*'
  $marathon_ensure = '0.13.0*'
  $consul_version = '0.6.0'
  $consul_template_version = '0.12.0'

  include oracle_java

  class { 'docker':
    ensure => $docker_ensure,
    dns => $ipaddress_docker0,
    docker_users => ['vagrant'],
  }

  # NOTE: This cert wrangling is only good for a single machine. We need some
  # other mechanism to get our certs to the right place in a multi-node setup.
  package { 'openssl': }
  ->
  file { '/var/docker-certs': ensure => directory }
  ->
  openssl::certificate::x509 { 'docker-registry':
    country => 'NT',
    organization => 'seed-stack',
    commonname => 'docker-registry.service.consul',
    base_dir => '/var/docker-certs',
  }
  ~>
  file { '/usr/local/share/ca-certificates/docker-registry.crt':
    ensure => link,
    target => '/var/docker-certs/docker-registry.crt',
  }
  ~>
  exec { 'update-ca-certificates':
    refreshonly => true,
    command => '/usr/sbin/update-ca-certificates',
    notify => [Service['docker']],
  }

  # We need this because mesos::install doesn't wait for apt::update before
  # trying to install the package.
  Class['apt::update'] -> Package['mesos']

  $mesos_zk = 'zk://localhost:2181/mesos'

  class { 'mesos':
    ensure => $mesos_ensure,
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
    ensure => $marathon_ensure,
    zookeeper => 'zk://localhost:2181/marathon',
    master => $mesos_zk,
    options => {
      hostname => 'localhost',
      event_subscriber => 'http_callback',
    },
    require => Class['oracle_java'],
  }

  package { 'unzip':
    ensure => installed,
  }

  class { 'consul':
    version => $consul_version,
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
      'marathon'        => { port => 8080 },
      'mesos'           => { port => 5050 },
      'zookeeper'       => { port => 2181 },
      'docker-registry' => { port => 5000 },
    },
    require => Package['unzip']
  }

  class { 'consul_template':
    version          => $consul_template_version,
    # FIXME: Consul Template 0.12.0+ is only available from the new
    # releases.hashicorp.com website. v0.23.0 of the consul_template module
    # doesn't build correct URLs for that site - so we have to give it the full
    # URL. v0.24.0 does support the new site but also has a new bug that breaks
    # (at least) first runs of the module. File an issue or PR with the module
    # maintainer or switch to Consul Template debs.
    download_url     => "https://releases.hashicorp.com/consul-template/${consul_template_version}/consul-template_${consul_template_version}_linux_amd64.zip",
    config_dir       => '/etc/consul-template',
    consul_host      => '127.0.0.1',
    consul_port      => 8500,
    consul_retry     => '10s',
    # For some reason, consul-template doesn't like this option.
    # consul_max_stale => '10m',
    log_level        => 'warn',
    require => Package['unzip']
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

  docker::run { 'registry':
    image => 'registry:2',
    ports => ['5000:5000'],
    volumes => [
      '/var/docker-registry:/var/lib/registry',
      '/var/docker-certs:/certs',
    ],
    env => [
      'REGISTRY_HTTP_TLS_CERTIFICATE=/certs/docker-registry.crt',
      'REGISTRY_HTTP_TLS_KEY=/certs/docker-registry.key',
    ],
    extra_parameters => ['--restart=always'],
    require => [Service['docker']],
    subscribe => [Openssl::Certificate::X509['docker-registry']],
  }

}
