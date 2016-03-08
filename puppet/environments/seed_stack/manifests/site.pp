node 'standalone.seed-stack.local' {
  class { 'seed_stack::controller':
    advertise_addr    => $ipaddress_eth0,
    controller_addrs  => [$ipaddress_eth0],
    controller_worker => true,
  }
  class { 'seed_stack::worker':
    advertise_addr        => $ipaddress_eth0,
    controller_addrs      => [$ipaddress_eth0],
    controller_worker     => true,
    xylem_backend         => 'standalone.seed-stack.local',
    gluster_client_manage => false,
  }

  # We need at least two replicas, so they both have to live on the same node
  # in the single-machine setup.
  file { ['/data/', '/data/brick1/', '/data/brick2']:
    ensure  => 'directory',
  }

  package { 'redis-server': ensure => 'installed' }
  ->
  service { 'redis-server': ensure => 'running' }
  ->
  class { 'seed_stack::xylem':
    gluster_mounts  => ['/data/brick1/', '/data/brick2'],
    gluster_hosts   => ['standalone.seed-stack.local'],
    gluster_replica => 2,
  }

  include seed_stack::load_balancer

  include docker_registry

}

# Keep track of node IP addresses across the cluster
# FIXME: A better, more automatic way to do this
class seed_stack_cluster {
  $controller_ip = '192.168.0.2'
  $worker_ip = '192.168.0.3'

  host { 'controller.seed-stack.local':
    ip           => $controller_ip,
    host_aliases => ['controller'],
  }
  host { 'worker.seed-stack.local':
    ip           => $worker_ip,
    host_aliases => ['worker'],
  }
}

node 'controller.seed-stack.local' {
  include seed_stack_cluster

  package { 'redis-server': ensure => 'installed' }
  ->
  service { 'redis-server': ensure => 'running' }
  ->
  class { 'seed_stack::xylem':
    gluster_mounts  => ['/data/brick1/', '/data/brick2'],
    gluster_hosts   => ['controller.seed-stack.local'],
    gluster_replica => 2,
  }

  class { 'seed_stack::controller':
    advertise_addr   => $seed_stack_cluster::controller_ip,
    controller_addrs => [$seed_stack_cluster::controller_ip],
  }

  include seed_stack::load_balancer
}

node 'worker.seed-stack.local' {
  include seed_stack_cluster

  class { 'seed_stack::worker':
    advertise_addr   => $seed_stack_cluster::worker_ip,
    controller_addrs => [$seed_stack_cluster::controller_ip],
    xylem_backend    => 'controller.seed-stack.local',
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
    country      => 'NT',
    organization => 'seed-stack',
    commonname   => 'docker-registry.service.consul',
    base_dir     => '/var/docker-certs',
  }
  ~>
  file { '/usr/local/share/ca-certificates/docker-registry.crt':
    ensure => link,
    target => '/var/docker-certs/docker-registry.crt',
  }
  ~>
  exec { 'update-ca-certificates':
    refreshonly => true,
    command     => '/usr/sbin/update-ca-certificates',
    notify      => [Service['docker']],
  }

  docker::run { 'registry':
    image            => 'registry:2',
    ports            => ['5000:5000'],
    volumes          => [
      '/var/docker-registry:/var/lib/registry',
      '/var/docker-certs:/certs',
    ],
    env              => [
      'REGISTRY_HTTP_TLS_CERTIFICATE=/certs/docker-registry.crt',
      'REGISTRY_HTTP_TLS_KEY=/certs/docker-registry.key',
    ],
    extra_parameters => ['--restart=always'],
    require          => [Service['docker']],
    subscribe        => [Openssl::Certificate::X509['docker-registry']],
  }
}
