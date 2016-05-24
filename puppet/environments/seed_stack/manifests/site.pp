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

#Nelson Classes
class dcos_install {

file { "/tmp/dcos":
    ensure => 'directory',
  }
}

#Class to do the installations from provisioner.rb
class dcos_installation { 
exec { 'change-dir':
  command => 'cd /tmp/dcos'
  }
exec { 'dcos-installer':                    
  command => 'curl -O http://boot.seed-stack.local:9012/dcos_install.sh'
  #refreshonly => true
  }


}

# Stuff for dcos nodes.
class dcos_node($gluster_nodes) {
  include common
  include dcos_install
  include dcos_installation

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

# Stuff for redis
class redis_node {
  package { 'redis-server': ensure => 'installed' }
  ->
  service { 'redis-server': ensure => 'running' }
}

# Stuff for xylem/gluster
class xylem_node($gluster_nodes) {
  include redis_node

  file { ['/data/', '/data/brick1/', '/data/brick2']:
    ensure  => 'directory',
  }

  package { 'glusterfs-server':
    ensure  => '3.7*',
    require => [Class['apt::backports'], Class['apt::update']],
  }
  ->
  service { 'glusterfs-server': ensure => 'running' }

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
  hiera_include('classes')
}


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


# Thing for MC2 manager.
class mc2_manager($infr_domain, $hub_domain) {
  include redis_node

  class { 'seed_stack::mc2':
    infr_domain      => $infr_domain,
    hub_domain       => $hub_domain,
    marathon_host    => 'http://marathon.mesos:8080',
    container_params => {
      'add-host' => 'servicehost:172.17.0.1',
    },
    app_labels       => {
      'HAPROXY_GROUP'   => 'external',
      'HAPROXY_0_VHOST' => "mc2.${infr_domain}",
    },
  }
}

node 'controller.seed-stack.local' {
  $role = 'controller'
  hiera_include('classes')
}

node 'worker.seed-stack.local' {
  $role = 'worker'
  hiera_include('classes')
}

node 'public.seed-stack.local' {
  $role = 'public'
  hiera_include('classes')
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
