# -*- mode: ruby -*-
# vi: set ft=ruby :

module VagrantPlugins
  module Seed
    class KernelArgsProvisioner < Vagrant.plugin(2, :provisioner)

      def configure(root_config)
      end

      def provision
        kargs = 'cgroup_enable=memory swapaccount=1'
        aptget = 'apt-get install --no-install-recommends -qy -t jessie-backports'
        sedcmd = "s/\\(GRUB_CMDLINE_LINUX\\)=\"\\(.*\\)\"/\\1=\"\\2 #{kargs}\"/"
        unless @machine.communicate.test("grep '#{kargs}' /etc/default/grub")
          @machine.communicate.sudo([
              "#{aptget} linux-image-amd64 linux-headers-amd64 virtualbox-guest-modules",
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
