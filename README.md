# GetIt

GetIt is a document delivery microservice for FindIt built using Sinatra.

# Installation

Clone the repository. You will also need to install the `puppet_applications` repository.
Copy the GetIt config file from the relevant puppet_applications folder to your local app's config directory: `cp ../puppet-applications/modules/kyandi/templates/production/config.local.yml config/`

You will need to install Vagrant and VirtualBox. Make sure that virtualization is enabled in your BIOS. 
From your `vagrant` folder you should now be able to run `vagrant up`.

You will need to deploy the application code to the vagrant box: `bundle exec cap deploy:setup`

## Gotchas

The gems are not pinned to specific versions and there may arise some mismatch problems between the gems installed to the system and the vagrant machine's ruby version (1.9.3). To avoid this, make sure that you don't accidentally regenerate `Gemfile.lock` with newer gems.
