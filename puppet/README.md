# Puppet provisioning
The Vagrant box is provisioned using [Puppet](http://docs.puppetlabs.com/puppet/3/reference/).

The primary module used to provision the box is [`praekeltfoundation/seed_stack`](https://forge.puppetlabs.com/praekeltfoundation/seed_stack). See the documentation for the module for more information.

### Notes
* We use the system version of Puppet (3.4.3) that is installed by default on the [`ubuntu/trusty64`](https://atlas.hashicorp.com/ubuntu/boxes/trusty64) base box.
* [librarian-puppet](http://librarian-puppet.com) is run on the VM to manage upstream Puppet modules.

### Travis tests
The Puppet configuration has a few tests run on it using [Travis CI](https://travis-ci.org/praekelt/seed-stack). You can run the same tests as Travis on your local machine with the following commands (first making sure that you have Ruby **1.9.3** and [Bundler](http://bundler.io) installed):
```shell
cd puppet
bundle install
bundle exec rake
```
