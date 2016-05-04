# -*- mode: ruby -*-
# vi: set ft=ruby :

module VagrantPlugins
  module Seed
    class KernelArgsProvisioner < Vagrant.plugin(2, :provisioner)

      def configure(root_config)
      end

      def provision
        kargs = 'cgroup_enable=memory swapaccount=1'
        unless @machine.communicate.test("grep '#{kargs}' /etc/default/grub")
          sedcmd = "s/\\(GRUB_CMDLINE_LINUX\\)=\"\\(.*\\)\"/\\1=\"\\2 #{kargs}\"/"
          @machine.communicate.sudo([
              'apt-get -t jessie-backports install -qy linux-image-amd64 linux-headers-amd64',
              "sed -i '#{sedcmd}' /etc/default/grub",
              'update-grub',
              # 'shutdown -h now',
            ].join("\n")) do |type, data|
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
          @machine.action(:reload, {provision_enabled: false})
        end
      end

    end
  end
end
