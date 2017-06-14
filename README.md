# Vagrant::Ignition
This is a Vagrant plugin that generates and mounts gpt partitioned drive for Ignition to use. It is only designed to work with the Virtualbox provider for now.


## Installation
Build the app using:

    $ gem build vagrant-ignition.gemspec

And install it with:

    $ vagrant plugin install vagrant-ignition.gem

## Usage
To use this app, you simply set a couple of config options in your Vagrantfile's config section.
Options:
`config.ignition.enabled: Simply set this to true to enable this plugin`
`config.ignition.path: This must be set to the path of you base ignition config (this can be nil if you don't have a base)`
`config.ignition.config_obj: This must be set equal to `config.vm.provider :virtualbox``
`config.ignition.config_img: Where to store the generated image (optional)`
`config.ignition.config_vmdk: Where to store the generated vmdk (optional)`
`config.ignition.hostname: The hostname of your machine (optional)`
`config.ignition.ip: The ip address to set eth1 equal to (this only applies if you're creating a private network as well)`

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/coreos/vagrant-ignition.
