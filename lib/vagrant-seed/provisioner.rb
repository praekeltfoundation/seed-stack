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
        dcos_installer_setup
        install_machines_of_type("controller")
        install_machines_of_type("misc")
        install_machines_of_type("worker")
      end

      protected

      # execute remote command as root
      # print command, stdout, and stderr (indented)
      def remote_sudo(machine, command, opts=nil)
        machine.ui.output("sudo: #{command}")
        machine.communicate.sudo(command, opts) do |type, data|
          unless data == "\n"
            output = '      ' + data
            case type
            when :stdout
              machine.ui.output(output)
            when :stderr
              machine.ui.error(output)
            end
          end
        end
      end

      def sudo(command)
        remote_sudo(@machine, command)
      end

      def each_machine_of_type(machine_type)
        @machine.env.active_machines.each do |name, provider|
          if @config.machines[name.to_s][:machine_type] == machine_type
            yield @machine.env.machine(name, provider)
          end
        end
      end

      def run_puppet(machine)
        remote_sudo(machine,
          'puppet agent --server boot.seed-stack.local --waitforcert 2 --test',
          {good_exit: [0, 2]})
      end

      def install_docs(machine, role)
        machine.ui.success "Installing DC/OS on #{machine.name}..."
        commands = [
          'mkdir /tmp/dcos || true',
          'cd /tmp/dcos',
          'curl -O http://boot.seed-stack.local:9012/dcos_install.sh',
        ]
        if role == "controller"
          commands += ['bash dcos_install.sh master']
        else
          commands += ['bash dcos_install.sh slave']
        end
        # /usr/bin/curl doesn't like mesosphere libraries.
        sedcmd = 's@/usr/bin/curl@/opt/mesosphere/bin/curl@'
        commands += [
          "sed -i '#{sedcmd}' /etc/systemd/system/dcos-*.service",
          'systemctl daemon-reload',
        ]
        remote_sudo(machine, commands.join("\n"))
      end

      def install_machine(machine)
        @machine.ui.success "Installing #{machine.name}..."
        run_puppet(machine)
        dcos_role = @config.machines[machine.name.to_s][:machine_type]
        if ['controller', 'worker'].include? dcos_role
          install_docs(machine, dcos_role)
        end
      end

      def install_machines_of_type(machine_type)
        each_machine_of_type(machine_type) { |m| install_machine(m) }
      end

      def machine_type(name)
        @config.machines[name.to_s][:machine_type]
      end

      def get_controller_ips
        @machine.env.active_machines.collect do |name, _|
          mcfg = @config.machines[name.to_s]
          if mcfg[:machine_type] == 'controller'
            mcfg[:ip]
          else
            nil
          end
        end.compact
      end

      def dcos_installer_setup
        # First, puppet-provision the boot machine to get docker.
        run_puppet(@machine)
        # Now generate the DC/OS setup stuff.
        sudo('/vagrant/bootstrap/setup-dcos-installer.sh')
        gen_conf = {
          'bootstrap_url' => 'http://boot.seed-stack.local:9012',
          'cluster_name' => 'seed-stack',
          'exhibitor_storage_backend' => 'static',
          'ip_detect_filename' => '/genconf/ip-detect',
          'master_list' => get_controller_ips,
          'resolvers' => ['8.8.8.8', '8.8.4.4'],
          'oauth_enabled' => 'false',
          'telemetry_enabled' => 'false',
        }
        path = '/root/dcos/genconf/config.yaml'
        sudo("cat <<'EOF' > #{path}\n#{gen_conf.to_yaml}EOF")
        sudo('cd /root/dcos; bash dcos_generate_config.sh')
        sudo([
            'cd /root/dcos',
            'docker kill dcos-install',
            'docker rm dcos-install',
            'docker run --name dcos-install -d -p 9012:80 -v $PWD/genconf/serve:/usr/share/nginx/html:ro nginx',
          ].join("\n"))
      end

    end
  end
end
