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

gem 'bulk_insert'
gem 'curb'
gem 'dotiw'
gem 'useragent'
gem 'bcrypt'
gem 'attr_encrypted', '~> 3.0.0'
gem 'addressable'

gem 'postmark-rails'

# admin session management
gem 'active_model_otp', '~> 1.2.0'
gem 'rqrcode', '~> 0.10.1'

gem 'bitcoin-ruby', require: 'bitcoin'

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
  gem 'web-console', '>= 3.3.0'
  gem 'listen', '>= 3.0.5', '< 3.2'
end

group :production do
  gem 'unicorn'
end
