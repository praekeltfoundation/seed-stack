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
  config.vm.box = "bento/ubuntu-14.04"

  # Disable automatic box update checking. If you disable this, then
  # boxes will only be checked for updates when the user runs
  # `vagrant box outdated`. This is not recommended.
  # config.vm.box_check_update = false

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 80 on the guest machine.

  config.vm.network "forwarded_port", guest: 7070, host: 7070 # MC2
  config.vm.network "forwarded_port", guest: 9000, host: 9000 # Supervisor
  config.vm.network "forwarded_port", guest: 8080, host: 8080 # Marathon
  config.vm.network "forwarded_port", guest: 5050, host: 5050 # Mesos
  config.vm.network "forwarded_port", guest: 5051, host: 5051 # Mesos
  config.vm.network "forwarded_port", guest: 8500, host: 8500 # Consul
  config.vm.network "forwarded_port", guest: 80, host: 8000

  # NOTE: these map the port resources advertised by the mesos-slave
  #       uncomment these if you want to access them directly on the host
  # for i in 10000..10050
  #   config.vm.network "forwarded_port", guest: i, host: i
  # end

  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  # config.vm.network "private_network", ip: "192.168.33.10"

  # Create a public network, which generally matched to bridged network.
  # Bridged networks make the machine appear as another physical device on
  # your network.
  # config.vm.network "public_network"

  # Share an additional folder to the guest VM. The first argument is
  # the path on the host to the actual folder. The second argument is
  # the path on the guest to mount the folder. And the optional third
  # argument is a set of non-required options.
  # config.vm.synced_folder "../data", "/vagrant_data"
  config.vm.synced_folder "./etc/supervisor", "/etc/supervisor"
  config.vm.synced_folder "./etc/marathon", "/etc/marathon"
  config.vm.synced_folder "./etc/mesos", "/etc/mesos"
  config.vm.synced_folder "./etc/mesos-master", "/etc/mesos-master"
  config.vm.synced_folder "./etc/mesos-slave", "/etc/mesos-slave"
  config.vm.synced_folder "./etc/consul.d", "/etc/consul.d"
  config.vm.synced_folder "./etc/consular", "/etc/consular"

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
  config.vm.provision "shell", path: "provision/install.sh"

  config.vm.provision "shell", run: "always", path: "provision/restart-services.sh"
end
