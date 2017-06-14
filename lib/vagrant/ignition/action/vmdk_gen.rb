#!/usr/bin/ruby
require_relative 'merge_ignition'
require_relative 'gpt'

def vmdk_gen(ignition_path, vmdk_name, config_drive, hostname, ip)
  merge_ignition(ignition_path, hostname, ip)
  if !ignition_path.nil?
    create_disk(ignition_path + ".merged", config_drive)
  else
    create_disk("config.ign.merged", config_drive)
  end

  if File.exist?(vmdk_name)
    File.delete(vmdk_name)
  end
  if (/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM) != nil
    vbox_out = `"C:\\Program Files\\Oracle\\VirtualBox\\VBoxManage.exe" internalcommands createrawvmdk -filename #{vmdk_name} -rawdisk #{config_drive}`
  else 
    vbox_out = `VBoxManage internalcommands createrawvmdk -filename #{vmdk_name} -rawdisk #{config_drive}`
  end
end
