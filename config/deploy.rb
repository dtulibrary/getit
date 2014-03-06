require 'bundler/capistrano'

# disable touch of public/* folders
set :normalize_asset_timestamps, false

if(variables.include?(:host))
  set :application, "#{host}"
else
 set :application, 'kyandi.vagrant.vm'
end

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
  if(variables.include?(:scm_user))
    set :scm_username, "#{scm_user}"
  else
    set :scm_username, "#{user}"
  end
  set :repository, "#{scm}"
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
