# Puppet provisioning
The Vagrant box is provisioned using [Puppet](http://docs.puppetlabs.com/puppet/3/reference/).

### Notes
* We use the system version of Puppet (3.4.3) that is installed by default on the [`ubuntu/trusty64`](https://atlas.hashicorp.com/ubuntu/boxes/trusty64) base box.
* [r10k](https://github.com/puppetlabs/r10k) is run on the VM to manage upstream Puppet modules.

### `upstream_modules` directory
Upstream Puppet modules are automatically downloaded by r10k to [this directory](upstream_modules) when the box is provisioned based on the contents of the [Puppetfile](Puppetfile).

**Note:** this directory is completely managed by r10k and any files that you manually add to it will be deleted by r10k when it runs.

The following 3rd party modules (and their dependencies) are installed:
* [camptocamp/openssl](https://forge.puppetlabs.com/camptocamp/openssl)
* [deric/mesos](https://forge.puppetlabs.com/deric/mesos)
* [garethr/docker](https://forge.puppetlabs.com/garethr/docker)
* [gdhbashton/consul_template](https://forge.puppetlabs.com/gdhbashton/consul_template)
* [KyleAnderson/consul](https://forge.puppetlabs.com/KyleAnderson/consul)
* [stankevich/python](https://forge.puppetlabs.com/stankevich/python)

### Travis tests
The Puppet configuration has a few tests run on it using [Travis CI](https://travis-ci.org/praekelt/seed-stack). You can run the same tests as Travis on your local machine with the following commands (first making sure that you have Ruby **1.9.3** and [Bundler](http://bundler.io) installed):
```shell
cd puppet
bundle install
bundle exec ./install-modules.sh
bundle exec ./run-tests.sh
```
