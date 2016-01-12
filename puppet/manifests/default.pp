node 'standalone.seed-stack.local' {
  class { 'seed_stack::controller':
    address              => $ipaddress_eth0,
    controller_addresses => [$ipaddress_eth0],
  }
  class { 'seed_stack::worker':
    address    => $ipaddress_eth0,
    controller => true,
  }

  class { 'seed_stack::load_balancer':
    manage_nginx           => false,
    nginx_service          => Service['nginx'],
    manage_consul_template => false,
    upstreams              => false,
  }

  include docker_registry
}

node 'controller.seed-stack.local' {
  class { 'seed_stack::controller':
    address              => $ipaddress_eth1,
    controller_addresses => [$ipaddress_eth1],
  }

  include seed_stack::load_balancer
}

node 'worker.seed-stack.local' {
  class { 'seed_stack::worker':
    address              => $ipaddress_eth1,
    controller_addresses => ['192.168.0.2']
  }

  include docker_registry
}

# Standalone Docker registry for testing
# TODO: Move this to the seed_stack module once we have a proper system for
# distributing the CA cert.
class docker_registry {
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
