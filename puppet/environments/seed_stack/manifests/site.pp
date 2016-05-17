# Repos
class repos {
  include apt

  class { 'apt::backports': pin => 500 }

  package { 'apt-transport-https': before => Class['apt::update'] }

  apt::source{ 'p16n-seed':
    location => 'https://praekeltfoundation.github.io/packages/',
    repos    => 'main',
    release  => 'trusty',
    key      => {
      id     => '864DC0AA3139DFA3C332B9527EAFC9B3F996C16C',
      server => 'keyserver.ubuntu.com',
    },
  }

}

# Stuff for all nodes.
class common {
  include repos

  class { 'docker':
    ensure         => $seed_stack::params::docker_ensure,
    storage_driver => 'devicemapper',
  }

}


# Stuff for dcos nodes.
class dcos_node($gluster_nodes) {
  include common

  package { ['selinux-utils', 'ipset', 'unzip', 'gawk', 'glusterfs-client']:
    ensure  => 'present',
    require => [Class['apt::update'], Class['apt::backports']],
  }

  ['mkdir', 'ln', 'tar'].each |$cmd| {
    file { "/usr/bin/${cmd}":
      ensure => 'link',
      target => "/bin/${cmd}",
    }
  }

  file { '/etc/docker':
    ensure => 'directory',
  }
  ->
  class { 'xylem::docker':
    repo_manage => false,
    backend     => $gluster_nodes[0],
    require     => [
      Apt::Source['p16n-seed'],
      Class['apt::update'],
      File['/etc/docker'],
    ],
  }

}

# Stuff for xylem/gluster
class xylem_node($gluster_nodes) {

  file { ['/data/', '/data/brick1/', '/data/brick2']:
    ensure  => 'directory',
  }

  package { 'glusterfs-server':
    ensure  => '3.7*',
    require => [Class['apt::backports'], Class['apt::update']],
  }
  ->
  service { 'glusterfs-server': ensure => 'running' }

  package { 'redis-server': ensure => 'installed' }
  ->
  service { 'redis-server': ensure => 'running' }

  class { 'xylem::node':
    gluster         => true,
    gluster_mounts  => ['/data/brick1/', '/data/brick2'],
    gluster_nodes   => $gluster_nodes,
    gluster_replica => 2,
    repo_manage     => false,
    require         => [
      Apt::Source['p16n-seed'],
      Class['apt::update'],
      Service['glusterfs-server'],
      Service['redis-server'],
    ],
  }

  Class['apt::update'] -> Package['seed-xylem']

}

node 'boot.seed-stack.local' {
  include common
}

# node 'standalone.seed-stack.local' {
#   class { 'seed_stack::controller':
#     advertise_addr    => $ipaddress_eth0,
#     controller_addrs  => [$ipaddress_eth0],
#     controller_worker => true,
#   }
#   class { 'seed_stack::worker':
#     advertise_addr        => $ipaddress_eth0,
#     controller_addrs      => [$ipaddress_eth0],
#     controller_worker     => true,
#     xylem_backend         => 'standalone.seed-stack.local',
#     gluster_client_manage => false,
#   }

#   # We need at least two replicas, so they both have to live on the same node
#   # in the single-machine setup.
#   file { ['/data/', '/data/brick1/', '/data/brick2']:
#     ensure  => 'directory',
#   }

#   package { 'redis-server': ensure => 'installed' }
#   ->
#   service { 'redis-server': ensure => 'running' }
#   ->
#   class { 'seed_stack::xylem':
#     gluster_mounts  => ['/data/brick1/', '/data/brick2'],
#     gluster_hosts   => ['standalone.seed-stack.local'],
#     gluster_replica => 2,
#   }

#   # If this is sharing with seed_stack::worker, we need to add listen_addr so
#   # that seed_stack::router doesn't mask our server blocks.
#   class { 'seed_stack::load_balancer':
#     listen_addr => $ipaddress_eth0,
#   }

#   include docker_registry

#   class { 'seed_stack::mc2':
#     infr_domain   => 'infr.standalone.seed-stack.local',
#     hub_domain    => 'hub.standalone.seed-stack.local',
#     marathon_host => $ipaddress_lo,
#   }
# }

# Keep track of node IP addresses across the cluster
# FIXME: A better, more automatic way to do this
class seed_stack_cluster {
  # The hostmanager vagrant plugin manages the hosts entries for us, but
  # various things still need the IPs. Bleh.
  $controller_ip = '192.168.55.11'
  $public_ip = '192.168.55.20'
  $worker_ip = '192.168.55.21'

  $gluster_nodes = ['controller.seed-stack.local']
}

node 'controller.seed-stack.local' {
  include common
  include seed_stack_cluster

  class { 'dcos_node': gluster_nodes => $seed_stack_cluster::gluster_nodes }

  class { 'xylem_node': gluster_nodes => $seed_stack_cluster::gluster_nodes }

  # class { 'seed_stack::controller':
  #   advertise_addr   => $seed_stack_cluster::controller_ip,
  #   controller_addrs => [$seed_stack_cluster::controller_ip],
  # }

  # include seed_stack::load_balancer

  class { 'seed_stack::mc2':
    infr_domain      => 'infr.controller.seed-stack.local',
    hub_domain       => "${seed_stack_cluster::public_ip}.xip.io",
    marathon_host    => 'http://marathon.mesos:8080',
    container_params => {
      'add-host' => 'servicehost:172.17.0.1',
    },
    app_labels       => {
      'HAPROXY_GROUP'   => 'external',
      'HAPROXY_0_VHOST' => 'mc2.infr.controller.seed-stack.local',
    },
    notify           => Service['xylem'],
  }
}

node 'worker.seed-stack.local' {
  include common
  include seed_stack_cluster

  class { 'dcos_node': gluster_nodes => $seed_stack_cluster::gluster_nodes }

  # class { 'seed_stack::worker':
  #   advertise_addr   => $seed_stack_cluster::worker_ip,
  #   controller_addrs => [$seed_stack_cluster::controller_ip],
  #   xylem_backend    => 'controller.seed-stack.local',
  # }

  # include docker_registry
}

node 'public.seed-stack.local' {
  include common
  include seed_stack_cluster

  class { 'dcos_node': gluster_nodes => $seed_stack_cluster::gluster_nodes }

  # class { 'seed_stack::worker':
  #   advertise_addr   => $seed_stack_cluster::worker_ip,
  #   controller_addrs => [$seed_stack_cluster::controller_ip],
  #   xylem_backend    => 'controller.seed-stack.local',
  # }

  # include docker_registry
}

# # Standalone Docker registry for testing
# # TODO: Move this to the seed_stack module once we have a proper system for
# # distributing the CA cert.
# class docker_registry {
#   # NOTE: This cert wrangling is only good for a single machine. We need some
#   # other mechanism to get our certs to the right place in a multi-node setup.
#   package { 'openssl': }
#   ->
#   file { '/var/docker-certs': ensure => directory }
#   ->
#   openssl::certificate::x509 { 'docker-registry':
#     country      => 'NT',
#     organization => 'seed-stack',
#     commonname   => 'docker-registry.service.consul',
#     base_dir     => '/var/docker-certs',
#   }
#   ~>
#   file { '/usr/local/share/ca-certificates/docker-registry.crt':
#     ensure => link,
#     target => '/var/docker-certs/docker-registry.crt',
#   }
#   ~>
#   exec { 'update-ca-certificates':
#     refreshonly => true,
#     command     => '/usr/sbin/update-ca-certificates',
#     notify      => [Service['docker']],
#   }

#   docker::run { 'registry':
#     image            => 'registry:2',
#     ports            => ['5000:5000'],
#     volumes          => [
#       '/var/docker-registry:/var/lib/registry',
#       '/var/docker-certs:/certs',
#     ],
#     env              => [
#       'REGISTRY_HTTP_TLS_CERTIFICATE=/certs/docker-registry.crt',
#       'REGISTRY_HTTP_TLS_KEY=/certs/docker-registry.key',
#     ],
#     extra_parameters => ['--restart=always'],
#     require          => [Service['docker']],
#     subscribe        => [Openssl::Certificate::X509['docker-registry']],
#   }
# }
