require_relative 'vmdk_gen'

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
          end

          config_path = env[:machine].config.ignition.path
          config_vmdk = env[:machine].config.ignition.config_vmdk
 					# VirtualBox on Windows fails to load a vmdk if the linked raw drive is listed with it's full path instead of relative... just use relative for now
         	#config_drive = File.join(File.dirname(__FILE__), "config_drive" + i.to_s  + ".img")
         	config_img = env[:machine].config.ignition.config_img

          hostname = env[:machine].config.ignition.hostname
          ip = env[:machine].config.ignition.ip

          vmdk_gen(config_path, config_vmdk, config_img, hostname, ip)

          env[:machine].ui.info "Configuring Ignition Drive"
          env[:machine].provider.driver.execute("storageattach", "#{env[:machine].id}", "--storagectl", "IDE Controller", "--device", "0", "--port", "1", "--type", "hdd", "--medium", "#{config_vmdk}")

					# Continue through the middleware chain
          @app.call(env)
        end
      end
    end
  end
end
