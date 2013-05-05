include vagrant_hosts

class {'kyandi': 
  environment  => 'unstable',
  conf_set   => 'vagrant',
  vhost_name => 'kyandi.vagrant.vm',
  thin_count => 2,
}
