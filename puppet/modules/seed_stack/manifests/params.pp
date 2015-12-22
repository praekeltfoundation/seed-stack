# == Class: seed_stack::params
#
class seed_stack::params {

  $docker_ensure            = '1.9.1*'

  $mesos_ensure             = '0.24.1*'
  $mesos_cluster            = 'seed-stack'
  $mesos_resources          = {}

  $marathon_ensure          = '0.13.0*'
  $marathon_default_options = { # TODO
    'event_subscriber' => 'http_callback' # HTTP callbacks for Consular
  }

  $consul_version           = '0.6.0'
  $consul_advertise_addr    = '127.0.0.1'
  $consul_client_addr       = '0.0.0.0'
  $consul_domain            = 'consul.'

  $consular_ensure          = '1.2.0*'
  $consular_sync_interval   = '300'

  $consul_template_version  = '0.12.0'
}
