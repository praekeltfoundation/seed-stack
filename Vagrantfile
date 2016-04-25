# -*- mode: ruby -*-
# vi: set ft=ruby :

require_relative 'lib/vagrant-dcos'
require_relative 'lib/vagrant-seed'

DOMAIN = "seed-stack.local"

MACHINES = {
  # Bootstrap machine. This must always be provisioned last.
  "boot" => {
    :ip => "192.168.55.2",
    :machine_type => "bootstrap",
    :memory => "512",
  },

  # Standalone controller+worker.
  "standalone" => {
    :ip => "192.168.55.9",
    :machine_type => "controller",  # It's a worker as well.
    :memory => "1536"
  },

  # Separate controller and worker.
  "controller" => {
    :ip => "192.168.55.11",
    :machine_type => "controller",
  },
  "worker" => {
    :ip => "192.168.55.21",
    :machine_type => "worker",
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
        :dcos_ssh, preserve_order: true,
        name: 'Shared SSH Key')

      machine.vm.provision(
        :shell, preserve_order: true,
        path: "puppet/puppet-bootstrap.sh")

      if name == "boot"
        machine.vm.provision(
          :shell, preserve_order: true,
          path: "puppet/puppetmaster-bootstrap.sh")

        machine.vm.provision(
          :seed_install, preserve_order: true,
          machines: MACHINES)
      end

    end
  end

end
