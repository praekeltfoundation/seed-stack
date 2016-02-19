# The baseline for module testing used by Puppet Labs is that each manifest
# should have a corresponding test manifest that declares that class or defined
# type.
#
# Tests are then run by using puppet apply --noop (to check for compilation
# errors and view a log of events) or by fully applying the test in a virtual
# environment (to compare the resulting system state to the desired state).
#
# Learn more about module testing here:
# http://docs.puppetlabs.com/guides/tests_smoke.html
#
include xylem

class {'xylem::docker':
  server => '127.0.0.1'
}

class {'xylem::node':
  gluster         => true,
  gluster_mounts  => ['/data/1', '/data/2'],
  gluster_nodes   => ['test'],
  gluster_replica => 2,
  gluster_stripe  => 2,
  postgres        => true,
  postgres_host   => 'localhost',
  postgres_user   => 'postgres',
  postgres_secret => 'testkey',
}
