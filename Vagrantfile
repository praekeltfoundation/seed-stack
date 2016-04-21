# -*- mode: ruby -*-
# vi: set ft=ruby :

require_relative 'lib/vagrant-dcos'

DOMAIN = "seed-stack.local"

MACHINES = {
  "boot" => {
    :ip => "192.168.55.2",
    :memory => "512",
  },
  "controller" => {
    :ip => "192.168.55.11",
  },
  "worker" => {
    :ip => "192.168.55.21",
  },
}


Vagrant.configure(2) do |config|
  config.vm.box = "ubuntu/trusty64"

  unless Vagrant.has_plugin?("vagrant-hostmanager")
    STDERR.puts "The 'vagrant-hostmanager' plugin is required. Install it with 'vagrant plugin install vagrant-hostmanager'"
    exit(1)
  end

  # configure vagrant-hostmanager plugin
  config.hostmanager.enabled = true
  config.hostmanager.manage_host = true
  config.hostmanager.ignore_private_ip = false

  if Vagrant.has_plugin?("vagrant-cachier")
    # Configure cached packages to be shared between instances of the same base
    # box. More info on http://fgrehm.viewdocs.io/vagrant-cachier/usage
    config.cache.scope = :box
  end

  MACHINES.each do |name, mcfg|
    config.vm.define name do |machine|

      machine.vm.hostname = "#{name}.#{DOMAIN}"
      machine.vm.network "private_network", ip: "#{mcfg[:ip]}"

      machine.vm.provider "virtualbox" do |vb|
        vb.memory = mcfg.fetch(:memory, "1024")
        vb.cpus = 1
      end

      # Provision a shared SSH key using the DC/OS installer's plugin.
      machine.vm.provision(
        :dcos_ssh,
        name: 'Shared SSH Key',
        preserve_order: true
      )

      machine.vm.provision :shell do |shell|
        shell.inline = "/vagrant/puppet/puppet-bootstrap.sh"
      end

      if name == "boot"
        machine.vm.provision :shell do |shell|
          shell.inline = "/vagrant/puppet/puppetmaster-bootstrap.sh"
        end

        # TODO: Figure out which machines need puppet runs.
        machine.vm.provision :shell do |shell|
          machines = ['controller', 'worker'].map { |m| "#{m}.#{DOMAIN}" }.join(' ')
          shell.inline = "/vagrant/puppet/runpuppet.sh #{machines}"
        end
      end

    end
  end

end
