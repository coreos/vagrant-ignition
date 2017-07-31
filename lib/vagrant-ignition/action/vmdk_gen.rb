#!/usr/bin/ruby
require_relative 'merge_ignition'
require_relative 'IgnitionDiskGenerator'

def vmdk_gen(ignition_path, drive_name, drive_root, hostname, ip, env)
  # This ensures changes the directory to the drive_root so the img and
  # vmdk can be generated in the same directory as well as avoid some
  # path name bugs
  orig_dir = Dir.pwd
  Dir.chdir(drive_root)
  vmdk_name = drive_name + ".vmdk"
  config_drive = drive_name + ".img"
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
  Dir.chdir(orig_dir)
end
