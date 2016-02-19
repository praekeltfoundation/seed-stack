# == Class: xylem::node
#
# Installs the Xylem glusterfs backend and configures and manages the service.
#
# === Parameters
#
# [*gluster*]
#   If `true` xylem will manage glusterfs volumes on this node.
#
# [*gluster_mounts*]
#   List of brick mounts on each glusterfs peer host.
#
# [*gluster_nodes*]
#   List of glusterfs peer hosts.
#
# [*gluster_replica*]
#   The number of replicas for a replicated volume. If given, it must be an
#   integer greater than or equal to 2.
#
# [*gluster_stripe*]
#   The number of stripes for a striped volume. If given, it must be an integer
#   greater than or equal to 2.
#
# [*postgres*]
#   If `true` xylem will manage postgres databases.
#
# [*postgres_host*]
#   Host to create databases on.
#
# [*postgres_user*]
#   User to create databases with.
#
# [*postgres_password*]
#   Optional password for postgres user.
#
# [*postgres_secret*]
#   Secret key for storing generated credentials.
#
# [*repo_manage*]
#   If true, xylem::repo will be used to manage the package repository.
#
# [*repo_source*]
#   Repository source passed to xylem::repo.
#
# [*package_ensure*]
#   The ensure value for the seed-xylem package.
#
class xylem::node (
  $gluster           = false,
  $gluster_mounts    = undef,
  $gluster_nodes     = undef,
  $gluster_replica   = undef,
  $gluster_stripe    = undef,

  $postgres          = false,
  $postgres_host     = undef,
  $postgres_user     = undef,
  $postgres_password = undef,
  $postgres_secret   = undef,

  $repo_manage       = true,
  $repo_source       = 'p16n-seed',
  $package_ensure    = 'installed',
){
  validate_bool($gluster)
  validate_bool($postgres)
  validate_bool($repo_manage)

  if $gluster {
    unless is_array($gluster_mounts) and count($gluster_mounts) >= 1 {
      fail('gluster_mounts must be an array with at least one element')
    }
    unless is_array($gluster_nodes) and count($gluster_nodes) >= 1 {
      fail('gluster_nodes must be an array with at least one element')
    }
  }

  if $postgres {
    if $postgres_host == undef { fail('postgres_host must be provided') }
    if $postgres_user == undef { fail('postgres_user must be provided') }
    if $postgres_secret == undef { fail('postgres_secret must be provided') }
  }

  if $repo_manage {
    class { 'xylem::repo':
      manage => $repo_manage,
      source => $repo_source,
    }
  }

  package { 'seed-xylem':
    ensure => $package_ensure,
  }
  ->
  file {'/etc/xylem/xylem.yml':
    ensure  => present,
    content => template('xylem/xylem.yml.erb'),
    mode    => '0644',
  }
  ~>
  service {'xylem':
    ensure => running,
  }

  if defined(Class['xylem::repo']) {
    Class['xylem::repo'] -> Package['seed-xylem']
  }
}
