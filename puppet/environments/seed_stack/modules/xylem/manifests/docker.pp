# == Class: xylem::docker
#
# Installs the Xylem Docker plugin and configured and manages the service.
#
# === Parameters
#
# [*backend*]
#   The xylem backend host to talk to.
#
# [*repo_manage*]
#   If true, xylem::repo will be used to manage the package repository.
#
# [*repo_source*]
#   Repository source passed to xylem::repo.
#
# [*package_ensure*]
#   The ensure value for the docker-xylem package.
#
class xylem::docker (
  $backend,
  $repo_manage    = true,
  $repo_source    = 'p16n-seed',
  $package_ensure = 'installed',
) {
  validate_bool($repo_manage)

  if $repo_manage {
    class { 'xylem::repo':
      manage => $repo_manage,
      source => $repo_source,
    }
  }

  package { 'docker-xylem':
    ensure => $package_ensure,
  }
  ->
  file { '/etc/docker/xylem-plugin.yml':
    ensure  => present,
    content => template('xylem/xylem-plugin.yml.erb'),
    mode    => '0644',
  }
  ~>
  service { 'docker-xylem':
    ensure => running,
  }

  if defined(Class['xylem::repo']) {
    Class['xylem::repo'] -> Package['docker-xylem']
  }
}
