# config valid for current version and patch releases of Capistrano
lock '~> 3.14.1'
set :rbenv_type, :system
set :rbenv_ruby, '2.7.1'

set :application, 'puzzle'
set :repo_url, 'https://github.com/secretnodes/puzzle' # DO NOT CHANGE THIS EVER

# Default branch is :master
set :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Default deploy_to directory is /var/www/my_app_name
set :deploy_to, '/puzzle/app'
set :init_system, :systemd


# Default value for :linked_files is []
before 'deploy:check:linked_files', 'linked_files:upload_files'
append :linked_files, 'config/database.yml', 'config/credentials.yml.enc', 'config/master.key', 'config/skylight.yml'

# Default value for linked_dirs is []
append :linked_dirs, 'log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'public/system', 'public/packs', 'node_modules'

set :npm_flags, '--production --silent --no-progress'

# Default value for default_env is {}
set :default_env, { path: '/puzzle/ruby-2.7.1/bin:/puzzle/node-14.4.3/bin:$PATH', ruby_version: 'ruby 2.7.1' }

# Default value for local_user is ENV['USER']
set :local_user, -> { ENV['DEPLOY_USER'] } if ENV['DEPLOY_USER']

before "deploy:assets:precompile", "deploy:yarn_install"

namespace :deploy do
  desc 'Run rake yarn:install'
  task :yarn_install do
    on roles(:web) do
      within release_path do
        execute("cd #{release_path} && yarn install")
      end
    end
  end
end

set :keep_releases, 2
set :keep_assets, 2

task :restart_web do
  on roles(:web) do
    execute "sudo systemctl restart puzzle-unicorn-#{fetch(:rails_env)}"
  end
end

if !ENV.has_key?('NO_RESTART')
  after 'deploy:symlink:release', :restart_web
end

namespace :syncing do
  task :suspend do
    on roles(:cron) do
      execute 'sudo systemctl stop cron'
    end
  end

  task :resume do
    on roles(:cron) do
      execute 'sudo systemctl start cron'
    end
  end
end
