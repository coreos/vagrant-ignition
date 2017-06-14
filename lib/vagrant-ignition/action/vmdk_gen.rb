#!/usr/bin/ruby
require_relative 'merge_ignition'
require_relative 'IgnitionDiskGenerator'

def vmdk_gen(ignition_path, vmdk_name, config_drive, hostname, ip, env)
  merge_ignition(ignition_path, hostname, ip, env)
  if !ignition_path.nil?
    IgnitionDiskGenerator.create_disk(ignition_path + ".merged", config_drive)
  else
    IgnitionDiskGenerator.create_disk("config.ign.merged", config_drive)
  end

  if File.exist?(vmdk_name)
    File.delete(vmdk_name)
  end
  env[:machine].provider.driver.execute("internalcommands", "createrawvmdk", "-filename", "#{vmdk_name}", "-rawdisk", "#{config_drive}")
end
