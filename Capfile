require 'capistrano/setup'

require 'capistrano/deploy'
require 'capistrano/rails'
require 'capistrano/npm'
require 'whenever/capistrano' unless ENV['NO_WHENEVER_SETUP']
require 'capistrano/linked_files'
require 'capistrano/rails/assets'

require 'capistrano/sidekiq'

require 'capistrano/scm/git'
install_plugin Capistrano::SCM::Git

Dir.glob('lib/capistrano/tasks/*.rake').each { |r| import r }
