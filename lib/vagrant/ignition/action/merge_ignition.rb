require 'json'

IGNITION_TEMPLATE = <<EOF
{"ignition":{"version":"2.0.0","config":{}},"storage":{},"networkd":{},"passwd":{}}
EOF

HOSTNAME_TEMPLATE = <<EOF
{"filesystem": "root","path": "/etc/hostname","contents": {"source": "data:,%s","verification": {}},"mode": 644,"user": {"id": 0},"group": {"id": 0}}
EOF

NETWORK_TEMPLATE = <<EOF
{"name": "00-eth1.network","contents": "[Match]\\nName=eth1\\n\\n[Network]\\nAddress=%s"}
EOF

# Vagrant insecure key
SSH_TEMPLATE = <<EOF
{"name":"core","sshAuthorizedKeys":["ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NOTd0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcWyLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQ== vagrant insecure public key"]}
EOF


def merge_ignition(ignition_path, hostname, ip)
  if !ignition_path.nil?
    ign_file = File.new(ignition_path, "rb")
    config = JSON.parse(File.read(ign_file))
  else
    config = JSON.parse(IGNITION_TEMPLATE)
    # set this so the write function at the end can be simple
    ignition_path = "config.ign"
  end

  # Handle hostname
  if !hostname.nil?
    if config["storage"].nil?
      config["storage"] = {"storage" => []}
    end 
    if !config["storage"]["files"].nil?
      config["storage"]["files"] += [JSON.parse(HOSTNAME_TEMPLATE % hostname)]
    else
      config["storage"]["files"] = [JSON.parse(HOSTNAME_TEMPLATE % hostname)]
    end
  end

  # Handle eth1
  if !ip.nil?
    if config["networkd"].nil?
      config["networkd"] = {"networkd" => []}
    end 
    if !config["networkd"]["units"].nil?
      config["networkd"]["units"] += [JSON.parse(NETWORK_TEMPLATE % ip)]
    else
      config["networkd"]["units"] = [JSON.parse(NETWORK_TEMPLATE % ip)]
    end
  end

  # Handle ssh key
  if config["passwd"].nil?
    config["passwd"] = {"passwd" => []}
  end 
  if !config["passwd"]["users"].nil?
    config["passwd"]["users"] += [JSON.parse(SSH_TEMPLATE)]
  else
    config["passwd"]["users"] = [JSON.parse(SSH_TEMPLATE)]
  end

  File.open(ignition_path + ".merged","w") do |f|
    f.write(config.to_json)
  end
end
