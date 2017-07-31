# Vagrant::Ignition
A Vagrant plugin that generates and mounts gpt partitioned drive for Ignition to use. It is only designed to work with the Virtualbox provider for now.


## Installation
Build the app using:

    $ gem build vagrant-ignition.gemspec

And install it with:

    $ vagrant plugin install vagrant-ignition-0.0.2.gem

## Usage
To use this plugin, a couple of config options must be set in a project's Vagrantfile config section.

Options:

`config.ignition.enabled`: Set to true to enable this plugin

`config.ignition.path`: Set to the path of the base ignition config (can be nil if there is no base)

`config.ignition.config_obj`: Set equal to `config.vm.provider :virtualbox`

`config.ignition.drive_root`: Set to desired root directory of generated config drive (optional)

`config.ignition.drive_name`: Set to desired filename of generated config drive (optional)

`config.ignition.hostname`: Set to desired hostname of the machine (optional)

`config.ignition.ip`: Set to desired ip of eth1 (only applies if a private network is being created)

## Contributing

Bug reports are welcome at https://issues.coreos.com/.
