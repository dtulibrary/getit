require 'bundler/capistrano'

# disable touch of public/* folders
set :normalize_asset_timestamps, false

set :application, ENV['HOST'] || 'kyandi.vagrant.vm'

set :deploy_to, "/var/www/#{application}"
role :web, "#{application}"
role :app, "#{application}"

default_run_options[:pty] = true

ssh_options[:forward_agent] = false
set :user, 'capistrano'
set :use_sudo, false
set :copy_exclude, %w(.git spec vagrant)

if fetch(:application).end_with?('vagrant.vm')
  set :scm, :none
  set :repository, '.'
  set :deploy_via, :copy
  set :copy_strategy, :export
  ssh_options[:keys] = [ENV['IDENTITY'] || './vagrant/puppet-applications/vagrant-modules/vagrant_capistrano_id_dsa']
else
  set :deploy_via, :remote_cache
  set :scm, :git
  set :scm_username, ENV['CAP_USER']
  set :repository, ENV['SCM']
  if variables.include?(:branch_name)
    set :branch, "#{branch_name}"
  else
    set :branch, 'master'
  end
  set :git_enable_submodules, 1
end

after "deploy:restart", "deploy:cleanup"

after "deploy:update", "config:symlink"
after "deploy:update", "deploy:cleanup"

namespace :config do
  desc "linking configuration to current release"
  task :symlink do
    run "ln -nfs #{deploy_to}/shared/config/config.local.yml #{release_path}/config/config.local.yml"
  end
end

namespace :deploy do
  [:start, :stop, :restart].each do |t|
    desc "#{t} server"
    task t, :roles => :app do
      run "/etc/init.d/thin #{t}"
    end
  end 
end
