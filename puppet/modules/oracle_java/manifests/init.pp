class oracle_java {

  # Install Oracle Java 8 for Ubuntu from the Web Upd8 PPA
  # https://launchpad.net/~webupd8team/+archive/ubuntu/java
  # NOTE: Installing this module means that you have accepted the Oracle license agreement

  apt::ppa { 'ppa:webupd8team/java': }

  exec { 'accept-oracle-license':
    command => 'echo "oracle-java8-installer shared/accepted-oracle-license-v1-1 select true" | /usr/bin/debconf-set-selections',
    unless  => '/usr/bin/debconf-show oracle-java8-installer | fgrep "shared/accepted-oracle-license-v1-1: true"',
    path    => "/usr/bin:/usr/sbin:/bin",
  }

  package { 'oracle-java8-installer':
    ensure  => installed,
    require => [
      Exec['accept-oracle-license'],
      Apt::Ppa['ppa:webupd8team/java'],
      Class['apt::update'],
    ],
  }
}
