Seed Stack
==========

Install Vagrant_ and then::

    $ git clone git://github.com/praekelt/seed-stack.git
    $ cd seed-stack
    $ vagrant up

This will result in a stack running:

1. Zookeeper_
2. Mesos_ Master
3. Mesos_ Slave
4. Marathon_
5. Consul_
6. Consular_
7. Nginx_

Once running launch the sample ``python-server`` application::

    $ curl -XPOST \
        -d @python-server.json \
        -H 'Content-Type: application/json' \
        http://localhost:8080/v2/apps

The following services have port forwarding configured and are available
on the host:

Supervisord
    http://localhost:9000

Marathon
    http://localhost:8080

Mesos
    http://localhost:5050

Nginx
    http://localhost:8000


.. _Vagrant: http://www.vagrantup.com
.. _Mesos: https://mesosphere.com/
.. _Marathon: http://mesosphere.github.io/marathon/
.. _Consul: http://consul.io
.. _Consular: http://consular.rtfd.org
.. _Nginx: http://www.nginx.org
.. _Zookeeper: https://zookeeper.apache.org/
