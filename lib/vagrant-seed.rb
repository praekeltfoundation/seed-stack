require_relative 'vagrant-seed/plugin'

module VagrantPlugins
  module Seed
    def self.source_root
      @source_root ||= Pathname.new(File.expand_path('../../', __FILE__))
    end
  end
end
