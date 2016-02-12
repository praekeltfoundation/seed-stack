# Puppet provisioning
The Vagrant box is provisioned using [Puppet](http://docs.puppetlabs.com/puppet/3/reference/).

The primary module used to provision the box is [`praekeltfoundation/seed_stack`](https://forge.puppetlabs.com/praekeltfoundation/seed_stack). See the documentation for the module for more information.

### Notes
* We use the latest Puppet 4.x (installed from the puppetlabs apt repo) by default.
* An older puppet version can be used instead by setting the `PUPPET_VERSION` environment variable before running `vagrant up`:
  * `PUPPET_VERSION=3.4` will select the system version of Puppet (3.4.3) that is installed by default on the [`ubuntu/trusty64`](https://atlas.hashicorp.com/ubuntu/boxes/trusty64) base box.
  * `PUPPET_VERSION=3.8` will select the latest Puppet 3.8.x (installed from the puppetlabs apt repo).
  * `PUPPET_VERSION=4` (the default) will select the latest Puppet 4.x.
* [librarian-puppet](http://librarian-puppet.com) is run on the VM to manage upstream Puppet modules.

### Travis tests
The Puppet configuration has a few tests run on it using [Travis CI](https://travis-ci.org/praekelt/seed-stack). You can run the same tests as Travis on your local machine with the following commands (first making sure that you have Ruby **1.9.3** and [Bundler](http://bundler.io) installed):
```shell
cd puppet
bundle install
bundle exec rake
```
