# -*- mode: ruby -*-
# vi: set ft=ruby :

# This is mostly borrowed from vagrant-dcos.

module VagrantPlugins
  module Seed
    class Provisioner < Vagrant.plugin(2, :provisioner)

      def configure(root_config)
      end

      def provision
        dcos_installer_setup
        install_machines_of_type("controller")
        install_machines_of_type("worker")
        dcos_cli_setup
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

      def install_machine(machine)
        @machine.ui.success "Installing #{machine.name}..."
        run_puppet(machine)
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
        gen_conf = {
          'clusterparams:controller_ip'     => '192.168.55.11',
          'clusterparams:public_ip'         => '192.168.55.20',
          'clusterparams:worker_ip'         => '192.168.55.21',
          'clusterparams:gluster_nodes'     => ['controller.seed-stack.local',],
          'clusterparams:infr_domain'       => 'infr.controller.seed-stack.local',
          'clusterparams:controller_ips'    => get_controller_ips,
          'clusterparams:hub_domain'        => "%{hiera('clusterparams:public_ip')}.xip.io",
          'clusterparams:dcos_package_opts' => "{
            'marathon-lb' => {
              'mem' => 256,
              'cpus' => 1
              }
            }",
        }
        path = '/etc/puppetlabs/code/environments/production/hieradata/clusterparams.yaml'
        sudo("cat <<'EOF' > #{path}\n#{gen_conf.to_yaml}EOF")
        run_puppet(@machine)
      end

      def dcos_cli_setup
        universe_url = 'https://github.com/praekeltfoundation/universe/archive/mc2.zip'
        marathon_lb_opts = {
          'marathon-lb' => {
            'mem' => 256,
            'cpus' => 1,
          }
        }
        sudo([
            'apt-get install -qy --no-install-recommends virtualenv',
            'cd /root',
            'rm -rf dcos-cli-bootstrap',
            'virtualenv dcos-cli-bootstrap',
            'source dcos-cli-bootstrap/bin/activate',
            'which pip',
            'pip install -U pip virtualenv',
            'mkdir -p dcos',
            'cd dcos',
            'curl -O https://downloads.dcos.io/dcos-cli/install-optout.sh',
            'bash ./install-optout.sh . https://controller.seed-stack.local --add-path yes',
            'source ./bin/env-setup',
            "dcos package repo add Seed #{universe_url}",
            "cat <<'EOF' > options.json\n#{marathon_lb_opts.to_json}\nEOF",
            # We do this twice because it sometimes fails "due to concurrent
            # access".
            'dcos package install --options=options.json --yes marathon-lb',
            'dcos package install --options=options.json --yes mc2',
            'dcos package install --options=options.json --yes marathon-lb',
            'dcos package install --options=options.json --yes mc2',
          ].join("\n"))
      end

    end
  end
end
