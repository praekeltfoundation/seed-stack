# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure(2) do |config|
  # The most common configuration options are documented and commented below.
  # For a complete reference, please see the online documentation at
  # https://docs.vagrantup.com.

  # Every Vagrant development environment requires a box. You can search for
  # boxes at https://atlas.hashicorp.com/search.
  config.vm.box = "ubuntu/trusty64"

  if Vagrant.has_plugin?("vagrant-cachier")
    # Configure cached packages to be shared between instances of the same base
    # box. More info on http://fgrehm.viewdocs.io/vagrant-cachier/usage
    config.cache.scope = :box
  end

  # Disable automatic box update checking. If you disable this, then
  # boxes will only be checked for updates when the user runs
  # `vagrant box outdated`. This is not recommended.
  # config.vm.box_check_update = false

  # Give our box a name, because "default" is confusing.
  config.vm.define "standalone" do |standalone|
    standalone.vm.hostname = "standalone.seed-stack.local"

    # Create a forwarded port mapping which allows access to a specific port
    # within the machine from a port on the host machine. In the example below,
    # accessing "localhost:8080" will access port 80 on the guest machine.

    standalone.vm.network "forwarded_port", guest: 8080, host: 8080
    standalone.vm.network "forwarded_port", guest: 5050, host: 5050
    standalone.vm.network "forwarded_port", guest: 5051, host: 5051
    standalone.vm.network "forwarded_port", guest: 8500, host: 8500
    standalone.vm.network "forwarded_port", guest: 80, host: 8000

    # NOTE: these map the port resources advertised by the mesos-slave
    #       uncomment these if you want to access them directly on the host
    # for i in 10000..10050
    #   standalone.vm.network "forwarded_port", guest: i, host: i
    # end
  end

  config.vm.define "controller" do |controller|
    controller.vm.hostname = "controller.seed-stack.local"

    # Create a private network, which allows host-only access to the machine
    # using a specific IP.
    controller.vm.network "private_network", ip: "192.168.0.2"
    controller.vm.network "forwarded_port", guest: 8080, host: 8080
    controller.vm.network "forwarded_port", guest: 5050, host: 5050
    controller.vm.network "forwarded_port", guest: 8500, host: 8500
    controller.vm.network "forwarded_port", guest: 80, host: 8000
  end

  config.vm.define "worker" do |worker|
    worker.vm.hostname = "worker.seed-stack.local"

    worker.vm.network "private_network", ip: "192.168.0.3"
    worker.vm.network "forwarded_port", guest: 5051, host: 5051
  end

  # Create a public network, which generally matched to bridged network.
  # Bridged networks make the machine appear as another physical device on
  # your network.
  # config.vm.network "public_network"

  # Share an additional folder to the guest VM. The first argument is
  # the path on the host to the actual folder. The second argument is
  # the path on the guest to mount the folder. And the optional third
  # argument is a set of non-required options.
  # config.vm.synced_folder "../data", "/vagrant_data"

  # Provider-specific configuration so you can fine-tune various
  # backing providers for Vagrant. These expose provider-specific options.
  # Example for VirtualBox:
  #
  config.vm.provider "virtualbox" do |vb|
    vb.memory = "1024"
    vb.cpus = 1
  end
  #
  # View the documentation for the provider you are using for more
  # information on available options.

  # Define a Vagrant Push strategy for pushing to Atlas. Other push strategies
  # such as FTP and Heroku are also available. See the documentation at
  # https://docs.vagrantup.com/v2/push/atlas.html for more information.
  # config.push.define "atlas" do |push|
  #   push.app = "YOUR_ATLAS_USERNAME/YOUR_APPLICATION_NAME"
  # end

  # Enable provisioning with a shell script. Additional provisioners such as
  # Puppet, Chef, Ansible, Salt, and Docker are also available. Please see the
  # documentation for more information about their specific syntax and use.

  # Install librarian-puppet dependencies
  config.vm.provision :shell, inline: "apt-get -y install git ruby-dev"
  # Download Puppet modules using librarian-puppet
  config.vm.provision :shell do |shell|
    shell.inline = "cd /vagrant/puppet && ./install-modules.sh"
  end

  # Provision the VM using Puppet
  config.vm.provision :puppet do |puppet|
    puppet.module_path = ["puppet/modules"]
    puppet.manifests_path = "puppet/manifests"
  end
  # Run the puppet provisioner a second time to finish glusterfs setup.
  config.vm.provision :puppet do |puppet|
    puppet.module_path = ["puppet/modules"]
    puppet.manifests_path = "puppet/manifests"
  end


end
