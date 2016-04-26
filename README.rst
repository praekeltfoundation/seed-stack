Seed Stack
==========

Install Vagrant_ and then::

    $ git clone git://github.com/praekelt/seed-stack.git
    $ cd seed-stack
    $ vagrant plugin install vagrant-hostmanager
    $ vagrant up standalone boot

This will result in a stack running:

1. Zookeeper_
2. Mesos_ Master
3. Mesos_ Slave
4. Marathon_
5. Docker_
6. `Docker Registry`_
7. Consul_
8. Consular_
9. Consul-Template_
10. Nginx_
11. Mission Control

All of this is installed and configured using Puppet_. For more information,
see the `Puppet README`_.

The available VMs defined in the Vagrantfile are as follows:
- ``standalone`` - a Seed Stack combination controller/worker with a Docker
  Registry and load-balancer
- ``controller`` - a Seed Stack controller with a load-balancer
- ``worker`` - a Seed Stack worker with a Docker Registry
- ``boot`` - a bootstrap machine Puppet server used for provisioning other VMs
  (*must* be provisioned last)


You can probably run the standalone VM and controller/worker VMs at the same
time, but there shouldn't be any need to do so.

Once running, you can manually launch the sample ``python-server`` application
through marathon::

    $ curl -XPOST \
        -d @python-server.json \
        -H 'Content-Type: application/json' \
        http://standalone.seed-stack.local:8080/v2/apps

You can watch the deployment progress in the Marathon web UI (see below).
Deploying for the first time on a newly provisioned VM may take a while because
it has to download the docker image first.

Then you should be able to use the application in your web browser at
http://python-server.192.168.55.9.xip.io

(For the controller/worker setup, use ``controller.seed-stack.local`` and
``192.168.55.11`` instead.)

The following services are available on the standalone or controller VM:

Marathon
    http://standalone.seed-stack.local:8080

Mesos
    http://standalone.seed-stack.local:5050

Consul
    http://standalone.seed-stack.local:8500/ui/

Mission Control (log in with admin/pass)
    http://mc2.infr.standalone.seed-stack.local

In order to access apps running in Mission Control, you may need to add
``/etc/hosts`` entries for their domains.


.. _Vagrant: http://www.vagrantup.com
.. _Mesos: https://mesos.apache.org/
.. _Marathon: http://mesosphere.github.io/marathon/
.. _Docker: https://www.docker.com
.. _Docker Registry: https://docs.docker.com/registry/
.. _Consul: http://consul.io
.. _Consular: http://consular.rtfd.org
.. _Consul-Template: https://github.com/hashicorp/consul-template
.. _Nginx: http://www.nginx.org
.. _Zookeeper: https://zookeeper.apache.org/
.. _Puppet: http://docs.puppetlabs.com/puppet/3/reference/
.. _Puppet README: puppet/README.md


Acknowledgements
----------------

The vagrant plugin used for provisioning with a bootstrap machine is heavily
inspired by the one in https://github.com/dcos/dcos-vagrant
