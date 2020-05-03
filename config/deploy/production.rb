server ENV['DEPLOY_HOST'], user: 'root', roles: %w{ app db web }
set :ssh_options, {
  keys: ['~/.ssh/puzzle_id_rsa2'],
  forward_agent: true
}

set :rails_env, 'production'
set :branch, 'master'
