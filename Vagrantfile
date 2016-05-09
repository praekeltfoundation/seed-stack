# -*- mode: ruby -*-
# vi: set ft=ruby :

require_relative 'lib/vagrant-seed'

DOMAIN = "seed-stack.local"

MACHINES = {
  # Bootstrap machine. This must always be provisioned last.
  "boot" => {
    :ip => "192.168.55.2",
    :machine_type => "bootstrap",
    :memory => "768",
  },

  # Standalone controller+worker.
  "standalone" => {
    :ip => "192.168.55.9",
    :machine_type => "controller",  # It's a worker as well.
    :aliases => ["mc2.infr.standalone.seed-stack.local"],
    :memory => "1536",
  },

  # Separate controller and worker.
  "controller" => {
    :ip => "192.168.55.11",
    :machine_type => "controller",
    :aliases => ["mc2.infr.controller.seed-stack.local"],
  },
  "worker" => {
    :ip => "192.168.55.21",
    :machine_type => "worker",
  },
}


def prov(machine, name, options={})
  options = options.merge({ preserve_order: true })
  machine.vm.provision(name, options)
end


Vagrant.configure(2) do |config|
  # config.vm.box = "ubuntu/xenial64"
  # config.vm.box = "bento/ubuntu-16.04"
  config.vm.box = "debian/contrib-jessie64"

  unless Vagrant.has_plugin?("vagrant-hostmanager")
    STDERR.puts "The 'vagrant-hostmanager' plugin is required. Install it with 'vagrant plugin install vagrant-hostmanager'"
    exit(1)
  end

  # configure vagrant-hostmanager plugin
  config.hostmanager.enabled = true
  config.hostmanager.manage_host = true
  config.hostmanager.ignore_private_ip = false

  # configure vagrant-vbguest plugin
  if Vagrant.has_plugin?('vagrant-vbguest')
    # config.vbguest.auto_update = true
    config.vbguest.auto_update = false
  end

  if Vagrant.has_plugin?("vagrant-cachier")
    # Configure cached packages to be shared between instances of the same base
    # box. More info on http://fgrehm.viewdocs.io/vagrant-cachier/usage
    config.cache.scope = :box
  end

  MACHINES.each do |name, mcfg|
    config.vm.define name do |machine|

      machine.vm.box = mcfg.fetch(:box, config.vm.box)

      machine.vm.hostname = "#{name}.#{DOMAIN}"
      machine.vm.network "private_network", ip: "#{mcfg[:ip]}"
      machine.hostmanager.aliases = mcfg.fetch(:aliases, [])

      machine.vm.provider "virtualbox" do |vb|
        vb.memory = mcfg.fetch(:memory, "1024")
        vb.cpus = 2
      end

      prov(machine, :shell, path: "puppet/puppet-bootstrap.sh")

      case name
      when "controller", "worker"
        machine.vm.provision(:set_kernel_args, preserve_order: true)
      when "boot"
        prov(machine, :shell, path: "puppet/puppetmaster-bootstrap.sh")
        prov(machine, :seed_install, machines: MACHINES)
      end

    end
  end

end
