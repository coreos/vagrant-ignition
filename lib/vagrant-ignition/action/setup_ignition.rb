require_relative 'vmdk_gen'
require 'base64'

module VagrantPlugins
  module Ignition
    module Action
      class SetupIgnition
        def initialize(app, env)
          @app = app
        end

        def call(env)
          @env = env

          if env[:machine].config.ignition.enabled == false
            @app.call(env)
            return
          end

          ignition_path = env[:machine].config.ignition.path
          drive_name = env[:machine].config.ignition.drive_name
          drive_root = env[:machine].config.ignition.drive_root

          hostname = env[:machine].config.ignition.hostname
          ip = env[:machine].config.ignition.ip
          provider = env[:machine].config.ignition.provider

          merge_ignition(ignition_path, hostname, ip, env, provider)
          if provider == "virtualbox"
            vmdk_gen(ignition_path, drive_name, drive_root, hostname, ip, env)

            env[:machine].ui.info "Configuring Ignition Config Drive"
            env[:machine].provider.driver.execute("storageattach", "#{env[:machine].id}", "--storagectl", "IDE Controller", "--device", "0", "--port", "1", "--type", "hdd", "--medium", "#{File.join(drive_root, (drive_name + ".vmdk"))}")
          elsif provider == "vmware"
            data = ""
            if !ignition_path.nil?
              data = File.read(ignition_path + ".merged")
            else
              data = File.read("config.ign.merged")
            end
            env[:machine].ui.info "Setting Ignition GuestInfo"

            File.open(env[:machine].provider.driver.vmx_path.to_s, 'ab') do |file|
              file.puts "guestinfo.coreos.config.data" + " = " + Base64.strict_encode64(data)
              file.puts "guestinfo.coreos.config.data.encoding = base64"
            end
          end

          # Continue through the middleware chain
          @app.call(env)
        end
      end
    end
  end
end
