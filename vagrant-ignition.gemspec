# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "vagrant-ignition/version"

Gem::Specification.new do |spec|
  spec.name          = "vagrant-ignition"
  spec.version       = "0.0.2"
  spec.authors       = ["Alexander Pavel", "Alex Crawford"]
  spec.email         = ["alex.pavel@coreos.com", "alex.crawford@coreos.com"]

  spec.description   = %q{"A Vagrant plugin for VirtualBox based machines that creates and mounts an Ignition configuration disk for consumption by Ignition"}
  spec.summary       = spec.description
  spec.homepage      = "https://github.com/coreos/vagrant-ignition"
  spec.license       = "Apache-2.0"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.15"
  spec.add_development_dependency "rake", "~> 10.0"
end
