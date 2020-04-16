source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

gem 'rails', '~> 5.2'
gem 'pg', '>= 0.18', '< 2.0'
gem 'sass-rails', '~> 5.0'
gem 'jbuilder', '~> 2.5'
gem 'bootsnap', require: false

gem 'babel-transpiler'
gem 'actionmailer_inline_css'

gem 'curb'
gem 'typhoeus'
gem 'dotiw'
gem 'useragent'
gem 'bcrypt'
gem 'attr_encrypted', '~> 3.0.0'
gem 'addressable'
gem 'dalli'
gem 'redcarpet'
gem 'rinku'
gem 'acts_as_list'

gem 'postmark-rails'
gem 'twitter'

# temp, used for uploading reports to s3
# gem 'aws-sdk-s3', '~> 1'
# gem 'sqlite3'

# admin session management
gem 'active_model_otp', '~> 1.2.0'
gem 'rqrcode', '~> 0.10.1'

gem 'bitcoin-ruby', require: 'bitcoin' # bech32
gem 'bitcoin-secp256k1', require: 'secp256k1'
gem 'bip_mnemonic' # bip39
gem 'money-tree' # bip32

gem 'whenever', require: false
gem 'rollbar'
gem 'lograge'
gem 'rack-attack'

group :development, :test do
  gem 'puma'
  gem 'capistrano', '~> 3.11', require: false
  gem 'capistrano-rails', '~> 1.4', require: false
  gem 'capistrano-linked-files', require: false
  gem 'capistrano-npm', require: false
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  gem 'letter_opener_web', '~> 1.0'
end

group :development do
  gem 'pry'
  gem 'web-console', '>= 3.3.0'
  gem 'listen', '>= 3.0.5', '< 3.2'
end

group :production do
  gem 'unicorn'
end