source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

gem 'rails'
gem 'pg'
gem 'sass-rails'
gem 'jbuilder'
# gem 'bootsnap', '~> 1.4.1', require: false
gem 'jquery-rails'
gem 'rails-ujs'

gem 'babel-transpiler'
gem 'actionmailer_inline_css'
gem 'turbolinks', '~> 5.1.0'

gem 'typhoeus'
gem 'dotiw'
gem 'useragent'
gem 'bcrypt'
gem 'attr_encrypted'
gem 'addressable'
gem 'dalli'
gem 'redcarpet'
gem 'rinku'
gem 'acts_as_list'

gem 'will_paginate'
gem 'will_paginate-bootstrap4'

gem 'postmark-rails'
gem 'twitter'

# temp, used for uploading reports to s3
gem 'aws-sdk-s3', '~> 1'
gem 'sqlite3'

# admin session management
gem 'rqrcode'

gem 'bitcoin-ruby', require: 'bitcoin' # bech32
gem 'bitcoin-secp256k1', require: 'secp256k1'
gem 'bip_mnemonic' # bip39
# gem 'money-tree' # bip32 -- causes abort 6 error

gem 'whenever', require: false
gem 'rollbar'
gem 'lograge'
gem 'rack-attack'

gem 'webpacker'

gem 'groupdate'

# # job queue
gem 'sidekiq'

# # js framework
gem "stimulus_reflex"
gem 'cable_ready'

# # authentication
gem 'devise'
gem 'devise-two-factor'

# authorization
gem 'cancancan', '~> 3.1'

# comments
gem 'acts_as_commentable'

#tags
gem 'gutentag', '~> 2.5'

group :development, :test do
  gem 'puma'
  gem 'capistrano', '~> 3.13', require: false
  gem 'capistrano-rails', '~> 1.4', require: false
  gem 'capistrano-linked-files', require: false
  gem 'capistrano-npm', require: false
  gem "capistrano-sidekiq", git: "https://github.com/rwojnarowski/capistrano-sidekiq.git"
  gem 'capistrano-rbenv', '~> 2.2', require: false
  gem 'capistrano-bundler', '~> 2.0', require: false
  gem 'ed25519'
  gem 'bcrypt_pbkdf'
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  gem 'letter_opener_web'
  gem 'pry-rails'
  gem 'pry-byebug'
end

group :development do
  gem 'pry'
  gem 'web-console'
  gem 'listen'
end

group :production do
  gem 'unicorn'
end
