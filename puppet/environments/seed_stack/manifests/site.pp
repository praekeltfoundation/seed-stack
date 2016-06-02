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

#Class to prepare Dcos and packages
class dcos_prepare {

  file { '/tmp/dcos':
    ensure => 'directory',
  }

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

}

#Class to download and install dcos
class dcos_install(String $dcos_role) {
  $sedcmd = 's@/usr/bin/curl@/opt/mesosphere/bin/curl@'
  $script_commands = [
                      "sed -i 's/devicemapper/deceivemapper/' dcos_install.sh",
                      "bash dcos_install.sh ${dcos_role}",
                      "sed -i '${sedcmd}' /etc/systemd/system/dcos-*.service",
                      'systemctl daemon-reload',
                      'touch /tmp/dcos/already-installed',]

  file { '/tmp/dcos/run_dcos_installer.sh':
    ensure  => present,
    content => join($script_commands, "\n")
  }

  exec { 'get-dcos-installer':
    command => 'curl -O http://boot.seed-stack.local:9012/dcos_install.sh',
    path    => ['/usr/bin', '/usr/sbin',],
    cwd     => '/tmp/dcos/',
    creates => '/tmp/dcos/dcos_install.sh',
  }

  exec { 'run-dcos-script':
    command   => 'bash -e run_dcos_installer.sh',
    path      => ['/bin', '/usr/bin', '/usr/sbin', '/sbin',],
    cwd       => '/tmp/dcos',
    creates   => '/tmp/dcos/already-installed',
    require   => [Exec['get-dcos-installer'], File['/tmp/dcos/run_dcos_installer.sh']],
    logoutput => true,
  }
}

#Class to puppet the dcos setup installer script
class bootstrap_prepare {

  $ip_route = 'ip route show to match 192.168.55.0'
  $grep_match = '[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}'
  $docker_sudo_commands = [
    'docker kill dcos-install',
    'docker rm dcos-install',
    'docker run --name dcos-install -d -p 9012:80 -v $PWD/genconf/serve:/usr/share/nginx/html:ro nginx',
    ]

  $ipdetect = [
    '#!/usr/bin/env bash',
    'set -o nounset -o errexit',
    "echo $(${ip_route} | grep -Eo '${grep_match}' | tail -1)",
  ]

  $gen_conf = {
    'bootstrap_url' => 'http://boot.seed-stack.local:9012',
    'cluster_name' => 'seed-stack',
    'exhibitor_storage_backend' => 'static',
    'ip_detect_filename' => '/genconf/ip-detect',
    'master_list' => hiera('clusterparams:controller_ips'),
    'resolvers' => ['8.8.8.8', '8.8.4.4'],
    'oauth_enabled' => false,
    'telemetry_enabled' => false,
  }

  file { ['/root/', '/root/dcos', '/root/dcos/genconf']:
    ensure  => directory,
  }

  file { '/root/dcos/genconf/ip-detect':
    ensure  => present,
    content => join($ipdetect, "\n"),
  }

  file { '/root/dcos/dcos_generate_config.sh':
    ensure => present,
    source => 'file:///vagrant/dcos_generate_config.sh',
  }

  file { '/root/dcos/genconf/config.yaml':
    ensure  => present,
    content => inline_template('<%= @gen_conf.to_yaml %>'),
    require => File['/root/dcos/genconf'],
  }
  file {'/root/dcos/docker_script.sh':
    ensure  => present,
    content => join($docker_sudo_commands, "\n"),
  }

  exec {'generate_configs':
    command => 'bash dcos_generate_config.sh',
    cwd     => '/root/dcos',
    path    => ['/bin', '/usr/bin', '/usr/sbin', '/sbin'],
    timeout => 900,
    require => [
      Class['docker'],
      File['/root/dcos/genconf/config.yaml'],
      File['/root/dcos/docker_script.sh'],
    ],
  }

  exec {'run_dcos_generate_config':
    command => 'bash docker_script.sh',
    cwd     => '/root/dcos',
    path    => ['/bin', '/usr/bin', '/usr/sbin', '/sbin'],
    require => Exec['generate_configs'],
  }
}

# Stuff for dcos nodes.
class dcos_node($gluster_nodes, $dcos_role) {
  include common
  contain dcos_prepare

  class { 'dcos_install':
    dcos_role => $dcos_role,
    require   => [Class['dcos_prepare'], Service['docker']],
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
  include bootstrap_prepare
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
    require          => Class['dcos_install'],
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
#Class to build gen_conf 
#class dcos_puppet_setup {
#  gen_conf = {
#    'bootstrap_url' => 'http://boot.seed-stack.local:9012',
#    'cluster_name' => 'seed-stack',
#    'exhibitor_storage_backend' => 'static',
#    'ip_detect_filename' => '/genconf/ip-detect',
#    'master_list' => get_controller_ips,
#    'resolvers' => ['8.8.8.8', '8.8.4.4'],
#    'oauth_enabled' => 'false',
#    'telemetry_enabled' => 'false',
#  }

#  file { ['/etc/puppetlabs/', '/etc/puppetlabs/code/',
#          '/etc/puppetlabs/code/environments/',
#          '/etc/puppetlabs/code/environments/production/',
#          '/etc/puppetlabs/code/environments/production/hieradata/']:
#    ensure => directory,
#  }
#  file { '/etc/puppetlabs/code/environments/production/hieradata/clusterparams.yaml':
#    ensure  => present,
#    content => gen_conf.to_yaml,
#    creates => '/etc/puppetlabs/code/environments/production/hieradata/clusterparams.yaml',
#  }

#}

