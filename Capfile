require 'capistrano/setup'

require 'capistrano/deploy'
require 'capistrano/rails'
require 'capistrano/npm'
require 'whenever/capistrano' unless ENV['NO_WHENEVER_SETUP']
require 'capistrano/linked_files'
require 'capistrano/rails/assets'

require 'capistrano/sidekiq'
install_plugin Capistrano::Sidekiq  # Default sidekiq tasks
# Then select your service manager
install_plugin Capistrano::Sidekiq::Systemd 
# or  
install_plugin Capistrano::Sidekiq::Upstart  # tests needed
# or  
install_plugin Capistrano::Sidekiq::Monit  # tests needed

require 'capistrano/scm/git'
install_plugin Capistrano::SCM::Git

Dir.glob('lib/capistrano/tasks/*.rake').each { |r| import r }
