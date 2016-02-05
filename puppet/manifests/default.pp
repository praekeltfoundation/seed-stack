# This contains setup common to all gluster nodes. Peers and volumes need to be
# configured on the individual nodes.
class glusterfs_common {
  # NOTE: If there are three gluster nodes, an extra puppet provisioning run
  # needs to happen after all nodes are up and running so that the existing
  # cluster can invite new nodes. I have no idea what happens with four or
  # more.

  apt::ppa { 'ppa:gluster/glusterfs-3.7': }

  package { 'glusterfs-server':
    ensure  => '3.7.6*',
    require => [Apt::Ppa['ppa:gluster/glusterfs-3.7'], Class['apt::update']],
  }

  file { ['/data', '/data/brick1']: ensure => 'directory' }
}

node 'standalone.seed-stack.local' {
  class { 'seed_stack::controller':
    address              => $ipaddress_eth0,
    controller_addresses => [$ipaddress_eth0],
    controller_worker    => true,
  }
  class { 'seed_stack::worker':
    address           => $ipaddress_eth0,
    controller_worker => true,
  }

  include seed_stack::load_balancer

  include docker_registry

  include glusterfs_common

  gluster_peer { 'standalone.seed-stack.local': }

  # We need at least two replicas, so they both have to live on the same node
  # in the single-machine setup.
  file { '/data/brick2':
    ensure  => 'directory',
    require => File['/data'],
  }

  # `force => true` allows the bricks to live on the root filesystem. In the
  # single-node setup, it also allows both replicas to live on the same node.
  gluster_volume { 'data1':
    replica => 2,
    force   => true,
    bricks  => [
      'standalone.seed-stack.local:/data/brick1/data1',
      'standalone.seed-stack.local:/data/brick2/data1',
    ],
    require => [
      File['/data/brick1'],
      File['/data/brick2'],
    ],
  }

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

# This needs to be on exactly two nodes.
class gluster_cluster {
  include glusterfs_common

  gluster_peer { ['controller.seed-stack.local', 'worker.seed-stack.local']: }

  # `force => true` allows the bricks to live on the root filesystem.
  gluster_volume { 'data1':
    replica => 2,
    force   => true,
    bricks  => [
      'controller.seed-stack.local:/data/brick1/data1',
      'worker.seed-stack.local:/data/brick1/data1',
    ],
  }
}

node 'controller.seed-stack.local' {
  include seed_stack_cluster
  include gluster_cluster

  class { 'seed_stack::controller':
    address              => $seed_stack_cluster::controller_ip,
    controller_addresses => [$seed_stack_cluster::controller_ip],
  }

  include seed_stack::load_balancer
}

node 'worker.seed-stack.local' {
  include seed_stack_cluster
  include gluster_cluster

  class { 'seed_stack::worker':
    address              => $seed_stack_cluster::worker_ip,
    controller_addresses => [$seed_stack_cluster::controller_ip]
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
