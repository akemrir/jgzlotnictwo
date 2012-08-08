# encoding: utf-8
require 'capistrano_colors'
# require 'capistrano/ext/multistage'
# require 'thinking_sphinx/deploy/capistrano'
#require 'config/boot'
require "bundler/capistrano"
require "rvm/capistrano"                  # Load RVM's capistrano plugin.
# require 'delayed/recipes'
# load 'deploy/assets'

set :application, "jgzlotnictwo.pl"
set :user, 'xenon'
set :runner, 'xenon'
set :deploy_to, "/home/xenon/app/#{application}"
server "94.23.145.245:4662", :app, :web, :db, :primary => true
set :rvm_ruby_string, '1.9.3-p194@jgzlotnictwo.pl'

default_environment["PATH"] = "/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
default_run_options[:pty] = true

set :scm, :mercurial
set :repository,    "http://109.197.103.83:4000"
set :deploy_via,    :remote_cache
set :copy_exclude,  %w(test .git .hg doc config/database.yml)
set :use_sudo,      :false
set :run_method,    "run"
set :keep_releases, 5
ssh_options[:forward_agent] = true

namespace :deploy do
  desc "Start the Thin processes"
  task :start do
    sudo "cd #{release_path}; bundle exec thin start -C jgzl_xen.yml"
  end

  desc "Stop the Thin processes"
  task :stop do
    sudo "cd #{release_path}; bundle exec thin stop -C jgzl_xen.yml"
  end

  desc "Restart the Thin processes"
  task :restart do
    sudo "cd #{release_path}; bundle exec thin restart -C jgzl_xen.yml"
  end

  # before 'deploy:setup', 'rvm:install_rvm'   # install rvm¶
  # before 'deploy:setup', 'rvm:install_ruby'  # install ruby and create gemset, or:¶
  before 'deploy:setup', 'rvm:create_gemset' # only create gemset¶
end
