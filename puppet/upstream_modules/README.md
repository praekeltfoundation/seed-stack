## Puppet upstream modules directory
Upstream Puppet modules are automatically downloaded to this directory when the Vagrant box is provisioned by [r10k](https://github.com/puppetlabs/r10k) based on the contents of the [Puppetfile](../Puppetfile).

The following 3rd party modules (and their dependencies) are installed:
* [camptocamp/openssl](https://forge.puppetlabs.com/camptocamp/openssl)
* [deric/mesos](https://forge.puppetlabs.com/deric/mesos)
* [garethr/docker](https://forge.puppetlabs.com/garethr/docker)
* [gdhbashton/consul_template](https://forge.puppetlabs.com/gdhbashton/consul_template)
* [KyleAnderson/consul](https://forge.puppetlabs.com/KyleAnderson/consul)
* [stankevich/python](https://forge.puppetlabs.com/stankevich/python)
