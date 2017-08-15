require 'json'

def ignition_template()
  {ignition: {version: "2.0.0", config: {}}, storage: {}, networkd: {}, passwd: {}}
end

def hostname_entry(hostname)
  {filesystem: "root", path: "/etc/hostname", contents: {source: "data:,%s" % hostname, verification: {}}, mode: 0644, user: {id: 0}, group: {id: 0}}
end

def virtualbox_ip_entry(ip)
  {name: "00-eth1.network", contents: "[Match]\nName=eth1\n\n[Network]\nAddress=%s" % ip}
end

def vmware_ip_entry(ip)
  {name: "00-ens34.network", contents: "[Match]\nName=ens34\n\n[Network]\nAddress=%s" % ip}
end

# Vagrant insecure key
VAGRANT_INSECURE_KEY = "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NOTd0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcWyLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQ== vagrant insecure public key"

def ssh_entry()
  {name: "core", sshAuthorizedKeys: [VAGRANT_INSECURE_KEY]}
end

HOSTNAME_REGEX = /^(?=.{1,255}$)[0-9A-Za-z](?:(?:[0-9A-Za-z]|-){0,61}[0-9A-Za-z])?(?:\.[0-9A-Za-z](?:(?:[0-9A-Za-z]|-){0,61}[0-9A-Za-z])?)*\.?$/

def merge_ignition(ignition_path, hostname, ip, env, provider)
  if !ignition_path.nil?
    ign_file = File.new(ignition_path, "rb")
    config = JSON.parse(File.read(ign_file), :symbolize_names => true)
  else
    config = ignition_template()
    # set this so the write function at the end can be simple
    ignition_path = "config.ign"
  end

  # Handle hostname
  if !hostname.nil?
    if !(hostname =~ (HOSTNAME_REGEX)).nil?
      config[:storage] ||= {:files => []}
      config[:storage][:files] ||= []
      config[:storage][:files] += [hostname_entry(hostname)]
    else
      env[:machine].ui.info "WARNING: Invalid hostname specified in config.ignition.hostname; ignoring hostname for Ignition Config Drive"
    end
  end

  # Handle networking
  if !ip.nil?
    config[:networkd] ||= {:units => []}
    config[:networkd][:units] ||= []
    if provider == "virtualbox"
      config[:networkd][:units] += [virtualbox_ip_entry(ip)]
    elsif provider == "vmware"
      config[:networkd][:units] += [vmware_ip_entry(ip)]
    else
      env[:machine].ui.info "WARNING: Invalid config.ignition.provider; failed to configure networking"
    end
  end

  # Handle ssh key
  config[:passwd] ||= {:users => []}
  config[:passwd][:users] ||= []
  if config[:passwd][:users].select {|user| user[:name] == "core"} != []
    config[:passwd][:users].select{|user| user[:name] == "core"}[0][:sshAuthorizedKeys] ||= []
    config[:passwd][:users].select{|user| user[:name] == "core"}[0][:sshAuthorizedKeys] += [VAGRANT_INSECURE_KEY]
  else
    config[:passwd][:users] += [ssh_entry()]
  end

  File.open(ignition_path + ".merged","wb") do |f|
    f.write(config.to_json)
  end
end
