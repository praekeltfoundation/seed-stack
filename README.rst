Seed Stack
==========

This version builds a seed cluster (with a minimum of three machines plus a
smaller bootstrap VM) on top of DC/OS.

Install Vagrant_ and then::

    $ git clone git://github.com/praekelt/seed-stack.git
    $ cd seed-stack
    $ vagrant plugin install vagrant-hostmanager

At this point, download the DC/OS installer linked from
https://dcos.io/docs/1.7/administration/installing/local/ (The filename should
be `dcos_generate_config.sh`) and put it in the root of your repo (next to
`Vagrantfile`). Then::

    $ vagrant up controller worker public boot

This will result in a stack running:

1. DC/OS and all its components
2. Mission Control

All of this is installed and configured using Puppet_ and a custom Vagrant
provisioner plugin. For more information, see the `Puppet README`_.

The available VMs defined in the Vagrantfile are as follows:
- ``controller`` - a DC/OS master node
- ``worker`` - a DC/OS private agent node
- ``public`` - a DC/OS public agent node running a marathon-lb endpoint
- ``boot`` - a bootstrap machine Puppet server used for provisioning other VMs
  (*must* be provisioned last)

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

DC/OS console:
    http://controller.seed-stack.local

Marathon
    http://controller.seed-stack.local:8080

Mesos
    http://controller.seed-stack.local:5050

Mission Control (log in with admin/pass)
    http://mc2.infr.controller.seed-stack.local (This actually points to the
    public agent node despite the `controller` in the hostname.)

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
