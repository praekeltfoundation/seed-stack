# -*- mode: ruby -*-
# vi: set ft=ruby :

# require_relative 'executor'
# require 'thread'
# require 'yaml'

# This is mostly borrowed from vagrant-dcos.

module VagrantPlugins
  module Seed
    class Provisioner < Vagrant.plugin(2, :provisioner)

      def configure(root_config)
      end

      def provision
        install_machines_of_type("controller")
        install_machines_of_type("worker")
      end

      protected

      # execute remote command as root
      # print command, stdout, and stderr (indented)
      def remote_sudo(machine, command)
        machine.ui.output("sudo: #{command}")
        machine.communicate.sudo(command) do |type, data|
          unless data == "\n"
            output = '      ' + data.chomp
            case type
            when :stdout
              machine.ui.output(output)
            when :stderr
              machine.ui.error(output)
            end
          end
        end
      end

      def install_machine(machine)
        @machine.ui.success "Installing #{machine.name}..."
        script = [
          'puppet agent --server boot.seed-stack.local --waitforcert 2 --test',
          'puppetcode=$?',
          'case $puppetcode in',
          '  0|2) exit 0;;',
          '  *) exit $puppetcode;;',
          'esac',
        ].join("\n")
        remote_sudo(machine, "sh -c '#{script}'")
      end

      def install_machines_of_type(machine_type)
        @machine.env.active_machines.each do |name, provider|
          if @config.machines[name.to_s][:machine_type] == machine_type
            install_machine(@machine.env.machine(name, provider))
          end
        end
      end

    end
  end
end
