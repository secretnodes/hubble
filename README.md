# Puzzle

This document covers usage info on how to run Puzzle on your own servers.

Puzzle, forked with :heart: by [secretnodes.org](https://secretnodes.org) from [hubble](https://github.com/figment-networks/hubble) by [Figment Networks](https://github.com/figment-networks/)


## Dependencies

- Ruby 2.5+
- Node LTS
- Accessible PostgreSQL database.
- Memcached running on localhost.
- [PostMark](https://postmarkapp.com) account for email notifications.
- [Rollbar](https://rollbar.com) account for exception tracking.
- [libsecp25k1](https://github.com/bitcoin-core/secp256k1) (with `--enable-module-recovery` configure option)


## How to Setup Puzzel in Production

### Production

1. Fork this repo!
1. Provision your host machine
Install some dependencies for Ruby and Rails.

To make sure we have everything necessary for Webpacker support in Rails, we're first going to start by adding the Node.js and Yarn repositories to our system before installing them.

```
sudo apt install curl
curl -sL https://deb.nodesource.com/setup_12.x | sudo -E bash -
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list

sudo apt-get update
sudo apt-get install git-core zlib1g-dev build-essential libssl-dev libreadline-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev libcurl4-openssl-dev software-properties-common libffi-dev nodejs yarn
```
Configure rbenv
Installing with rbenv is a simple two step process. First you install rbenv, and then ruby-build:

```
cd
git clone https://github.com/rbenv/rbenv.git ~/.rbenv
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(rbenv init -)"' >> ~/.bashrc
exec $SHELL

git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
echo 'export PATH="$HOME/.rbenv/plugins/ruby-build/bin:$PATH"' >> ~/.bashrc
exec $SHELL

rbenv install 2.5.8
rbenv global 2.5.8
ruby -v
```
install Bundler
```
gem install bundler
```
Installing Rails
```
gem install rails -v 5.1.7
```

When using rbenv, you'll need to run the following command to make the rails executable available:

```
rbenv rehash
```
Now that you've installed Rails, you can run the rails -v command to make sure you have everything installed correctly:
```
rails -v
# Rails 5.1.7
```
Setting Up PostgreSQL

```
sudo apt-get install postgresql
```

[Guide Source](https://gorails.com/setup/ubuntu/18.04)

1. Generate encrypted secrets with `bin/rails secrets:setup`. Use `config/encrypted_secrets_quickstart.yml` to see what values are needed for what environments. Store `config/secrets.yml.enc` somewhere safe as it won't be committed.
1. Setup your instance:
    ```
    export HUBBLE_ADMIN_EMAIL=your@email.com
    export HUBBLE_HOST=ip-or-hostname-of-server
    export HUBBLE_RAILS_ENV=production
    export HUBBLE_KEY=~/.ssh/hubble-key.pem
    export HUBBLE_DOMAIN=hubble.your.domain
    export HUBBLE_REMOTE_USER=hubble
    ./setup/bootstrap.sh
    ```
    This automated process is meant for a Ubuntu 18.04 LTS install. We use AWS for this. Puzzle uses HTTPS everywhere, so watch the output for when it asks you to create a DNS record.
1. Assuming that all goes well, there will be a URL you can visit to claim an admin account and setup a password/2FA.
1. In admin, create a new Cosmos chain with the chain name and gaiad RPC/LCD info. Make sure to click 'enable' at the top.
1. Next ssh into the machine, start `screen` and do the initial sync:
    ```
    cd /hubble/app/current
    bin/rake sync:cosmos:all events:cosmos:all stats:cosmos:all
    ```
    That will take a good long while depending on how long the chain you're syncing has been going for.
1. Once it's done, you will want to install the crontab entries. You can either run `bin/bundle exec whenever --update-crontab` right now, or just deploy again and they'll get installed automatically.

### Development
1. Pull the repo into your local environment
2. Make sure you have Ruby 2.5.1 and bundler 2.0 installed on your local machine. 
3. Run `bundle install` from the project root.
4. Once all gems are installed properly, create the database by running `rake db:create` and `rake db:migrate`. `rake db:migrate` might fail the first time but it should succeed on subsequent tries. 
5. run `rails db:seed`. You should get an output with `Admin Created:` followed by a URL. You'll need this in the next step. 
6. run `rails s`. Go to the URL and create a password. 
7. That's it! Your development environment is now set up. 

## How to Deploy

Use the appropriate generated deploy script if you used our setup scripts:

```
bin/deploy-{RAILS_ENV}.sh
```

Or do it manually:

```
RAILS_ENV=staging DEPLOY_USER=hubble DEPLOY_HOST=ip-or-hostname DEPLOY_KEYS=~/.ssh/hubble.pem bin/bundle cap staging deploy
```
