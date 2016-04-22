Seed Stack
==========

TODO: Update this to reflect the new way of doing things in this branch.

The vagrant plugin in `lib/vagrant-dcos` is from
https://github.com/dcos/dcos-vagrant and licensed under the Apache 2 license
that covers that repository.

To provision, run `vagrant up controller worker boot`. It's important that
`boot` is at the end of the list.


Older stuff that may be inaccurate:


Install Vagrant_ and then::

    $ git clone git://github.com/praekelt/seed-stack.git
    $ cd seed-stack
    $ vagrant up standalone

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

All of this is installed and configured using Puppet_. For more information, see the `Puppet README`_.

The available VMs defined in the Vagrantfile are as follows:
- ``standalone`` - a Seed Stack combination controller/worker with a Docker Registry and load-balancer
- ``controller`` - a Seed Stack controller with a load-balancer
- ``worker`` - a Seed Stack worker with a Docker Registry

You can run either the standalone VM or the controller and worker VMs but not both as their forwarded ports will conflict.

Once running launch the sample ``python-server`` application::

    $ curl -XPOST \
        -d @python-server.json \
        -H 'Content-Type: application/json' \
        http://localhost:8080/v2/apps

Then you should be able to use the application in your web browser at http://python-server.127.0.0.1.xip.io:8000

The following services have port forwarding configured and are available
on the host:

Marathon
    http://localhost:8080

Mesos
    http://localhost:5050

Consul
    http://localhost:8500/ui/

Nginx
    http://localhost:8000


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
