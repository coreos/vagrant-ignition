module VagrantPlugins
  module Ignition
    class Config < Vagrant.plugin("2", :config)
      attr_accessor :enabled
      attr_accessor :path
      attr_accessor :config_obj
      attr_accessor :drive_name
      attr_accessor :drive_root
      attr_accessor :hostname
      attr_accessor :ip

      def initialize
        @enabled     = UNSET_VALUE
        @path        = UNSET_VALUE
        @config_obj  = UNSET_VALUE
        @drive_name  = UNSET_VALUE
        @drive_root  = UNSET_VALUE
        @hostname    = UNSET_VALUE
        @ip          = UNSET_VALUE
      end

      def finalize!
        @enabled     = false         if @enabled     == UNSET_VALUE
        @path        = nil           if @path        == UNSET_VALUE
        @drive_name  = "config"      if @drive_name  == UNSET_VALUE
        @drive_root  = "./"          if @drive_root  == UNSET_VALUE
        @hostname    = nil           if @hostname    == UNSET_VALUE
        @ip          = nil           if @ip          == UNSET_VALUE
      end
    end
  end
end
