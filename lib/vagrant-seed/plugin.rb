# -*- mode: ruby -*-
# vi: set ft=ruby :

# Seed installer plugin, mostly borrowed from vagrant-dcos.

module VagrantPlugins
  module Seed
    VERSION = '0.1'

    class Plugin < Vagrant.plugin(2)
      name "seed"

      config :seed_install, :provisioner do
        require_relative 'provisioner_config'
        ProvisionerConfig
      end

      provisioner :seed_install do
        require_relative 'provisioner'
        Provisioner
      end
    end

  end
end
