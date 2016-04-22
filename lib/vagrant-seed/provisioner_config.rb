# -*- mode: ruby -*-
# vi: set ft=ruby :

module VagrantPlugins
  module Seed
    class ProvisionerConfig < Vagrant.plugin(2, :config)
      attr_accessor :machines
      attr_accessor :max_install_threads

      def initialize()
        super
        @machines = UNSET_VALUE
        @max_install_threads = UNSET_VALUE
      end

      def finalize!
        # defaults after merging
        @machines = {} if @machine_types == UNSET_VALUE
        @max_install_threads = 4 if @max_install_threads == UNSET_VALUE
      end

      # The validation method is given a machine object, since validation is done for each machine that Vagrant is managing
      def validate(machine)
        errors = _detected_errors

        unless @max_install_threads > 0
          errors << "Invalid config: 'max_install_threads' must be greater than zero"
        end

        if @machines.nil? || @machines.empty? || @machines == UNSET_VALUE
            errors << "Invalid config: 'machines' is required"
        end

        return { "seed_install" => errors }
      end
    end
  end
end
