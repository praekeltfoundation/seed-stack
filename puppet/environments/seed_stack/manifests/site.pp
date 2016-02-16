# This contains setup common to all gluster nodes. Peers and volumes need to be
# configured on the individual nodes.
class glusterfs_common {
  # NOTE: If there are three gluster nodes, an extra puppet provisioning run
  # needs to happen after all nodes are up and running so that the existing
  # cluster can invite new nodes. I have no idea what happens with four or
  # more.

  # The default repo and version are suitable for our needs.
  include gluster

  file { ['/data', '/data/brick1', '/data/brick2']: ensure => 'directory' }

}

# FIXME: This should be somewhere else.
class xylem_common {

  apt::source{'seed':
    location => 'https://praekeltfoundation.github.io/packages/',
    repos    => 'main',
    release  => inline_template('<%= @lsbdistcodename.downcase %>'),
    key      => {
      id     => '864DC0AA3139DFA3C332B9527EAFC9B3F996C16C',
      source => 'https://praekeltfoundation.github.io/packages/conf/seed.gpg.key',
    },
  }

  contain apt::update
}

# FIXME: This should be somewhere else.
class xylem_gluster($mounts=[], $nodes=[], $replica=false, $stripe=false) {
  include xylem_common

  $xylem_gluster_template = @(END)
  queues:
    - name: gluster
      plugin: seed.xylem.gluster
      gluster_mounts:
        <%- @mounts.each do |mp| -%>
        - <%= mp %>
        <%- end -%>
      gluster_nodes:
        <%- @nodes.each do |node| -%>
        - <%= node %>
        <%- end -%>
      <%- if @replica then -%>
      gluster_replica: <%= @replica %>
      <%- end -%>
      <%- if @stripe then -%>
      gluster_stripe: <%= @stripe %>
      <%- end -%>
  END

  package { 'seed-xylem':
    ensure          => latest,
    install_options => ['--force-yes'],
    require         => Apt::Source['seed'],
  }
  ->
  file {'/etc/xylem/xylem.yml':
    ensure  => present,
    content => inline_template($xylem_gluster_template),
    mode    => '0644',
  }
  ~>
  service { 'xylem':
    ensure    => running,
    require   => Package['seed-xylem'],
    subscribe => File['/etc/xylem/xylem.yml'],
  }

}

# FIXME: This should be somewhere else.
class xylem_docker($server) {
  include xylem_common

  file { '/run/docker/plugins':
    ensure => directory,
    mode   => '0755',
  }

  $xylem_plugin_template = @(END)
  host: <%= @server %>
  port: 7701
  mount_path: /var/lib/docker/volumes
  socket: /run/docker/plugins/xylem.sock
  END

  package { 'docker-xylem':
    ensure          => latest,
    install_options => ['--force-yes'],
    require         => Apt::Source['seed'],
  }
  ->
  file { '/etc/docker/xylem-plugin.yml':
    ensure  => present,
    content => inline_template($xylem_plugin_template),
    mode    => '0644',
  }
  ~>
  service {'docker-xylem':
    ensure    => running,
    subscribe => File['/etc/docker/xylem-plugin.yml'],
    require   => [
      Package['docker-xylem'],
      File['/run/docker/plugins'],
    ],
  }

}

node 'standalone.seed-stack.local' {
  class { 'seed_stack::controller':
    advertise_addr    => $ipaddress_eth0,
    controller_addrs  => [$ipaddress_eth0],
    controller_worker => true,
  }
  class { 'seed_stack::worker':
    advertise_addr    => $ipaddress_eth0,
    controller_addrs  => [$ipaddress_eth0],
    controller_worker => true,
  }

  include seed_stack::load_balancer

  include docker_registry

  include glusterfs_common

  gluster_peer { 'standalone.seed-stack.local': }

  # # `force => true` allows the bricks to live on the root filesystem. In the
  # # single-node setup, it also allows both replicas to live on the same node.
  # gluster_volume { 'data1':
  #   replica => 2,
  #   force   => true,
  #   bricks  => [
  #     'standalone.seed-stack.local:/data/brick1/data1',
  #     'standalone.seed-stack.local:/data/brick2/data1',
  #   ],
  #   require => [
  #     File['/data/brick1'],
  #     File['/data/brick2'],
  #   ],
  # }

  class { 'xylem_docker':
    server => $::fqdn,
    require => Class['docker'],
  }

  class { 'xylem_gluster':
    mounts => ['/data/brick1', '/data/brick2'],
    nodes  => [$::fqdn],
    stripe => 2,
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

  # # `force => true` allows the bricks to live on the root filesystem.
  # gluster_volume { 'data1':
  #   replica => 2,
  #   force   => true,
  #   bricks  => [
  #     'controller.seed-stack.local:/data/brick1/data1',
  #     'worker.seed-stack.local:/data/brick1/data1',
  #   ],
  # }

}

node 'controller.seed-stack.local' {
  include seed_stack_cluster
  include gluster_cluster

  class { 'seed_stack::controller':
    advertise_addr   => $seed_stack_cluster::controller_ip,
    controller_addrs => [$seed_stack_cluster::controller_ip],
  }

  class { 'xylem_gluster':
    mounts  => ['/data/brick1', '/data/brick2'],
    nodes   => ['controller.seed-stack.local', 'worker.seed-stack.local'],
    stripe  => 2,
    replica => 2,
  }

  include seed_stack::load_balancer
}

node 'worker.seed-stack.local' {
  include seed_stack_cluster
  include gluster_cluster

  class { 'seed_stack::worker':
    advertise_addr   => $seed_stack_cluster::worker_ip,
    controller_addrs => [$seed_stack_cluster::controller_ip]
  }

  class { 'xylem_docker':
    server  => 'controller.seed-stack.local',
    require => Class['docker'],
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
