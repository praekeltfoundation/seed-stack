node default {

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

  class { 'seed_stack::controller':
    address              => $ipaddress_eth0,
    controller_addresses => [$ipaddress_eth0],
    controller_worker    => true,
  }
  class { 'seed_stack::worker':
    address           => $ipaddress_eth0,
    controller_worker => true,
  }

  file { '/etc/consul-template/nginx-websites.ctmpl':
    source => 'puppet:///modules/seed_stack/nginx-websites.ctmpl',
  }
  ~>
  consul_template::watch { 'nginx-websites':
    source      => '/etc/consul-template/nginx-websites.ctmpl',
    destination => '/etc/nginx/sites-enabled/seed-websites.conf',
    command     => '/etc/init.d/nginx reload',
    require     => Service['nginx'],
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
