module VagrantPlugins
  module Ignition
    class Config < Vagrant.plugin("2", :config)
      attr_accessor :enabled
      attr_accessor :path
      attr_accessor :ssh_part_location
      attr_accessor :config_obj
      attr_accessor :config_img
      attr_accessor :config_vmdk
      attr_accessor :hostname
      attr_accessor :ip

      def initialize
        @enabled     = UNSET_VALUE
        @path        = UNSET_VALUE
        @ssh_path    = UNSET_VALUE
        @config_obj  = UNSET_VALUE
        @config_img  = UNSET_VALUE
        @config_vmdk = UNSET_VALUE
        @hostname    = UNSET_VALUE
        @ip          = UNSET_VALUE
      end

			def finalize!
        @enabled     = false         if @enabled     == UNSET_VALUE
        @path        = nil           if @path        == UNSET_VALUE
        @config_img  = "config.img"  if @config_img  == UNSET_VALUE
        @config_vmdk = "config.vmdk" if @config_vmdk == UNSET_VALUE
        @hostname    = nil           if @hostname    == UNSET_VALUE
        @ssh_path    = nil           if @ssh_path    == UNSET_VALUE
        @ip          = nil           if @ip          == UNSET_VALUE
      end
    end
  end
end
