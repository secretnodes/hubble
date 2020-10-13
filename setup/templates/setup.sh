#!/usr/bin/env bash

set -e

echo "Creating /puzzle..."
sudo mkdir -p /puzzle
sudo chown -R $USER:$USER /puzzle

echo
echo

echo "INSTALLING DEPS..."
sudo add-apt-repository ppa:certbot/certbot > /dev/null
sudo apt update > /dev/null
sudo apt install -y libpq-dev libcurl4-openssl-dev nginx \
                    zlib1g-dev libssl-dev libreadline-dev \
                    build-essential software-properties-common \
                    python-certbot-nginx libsecp256k1-dev postgresql postgresql-contrib memcached > /dev/null
echo "DONE"

sleep 1
echo
echo

echo "INSTALLING RUBY..."
if [ -d "/puzzle/ruby-2.7.1" ]; then
  echo "SKIP"
else
  git clone https://github.com/rbenv/ruby-build.git /tmp/ruby-build
  sudo bash -c "PREFIX=/puzzle/ruby-build /tmp/ruby-build/install.sh"
  rm -rf /tmp/ruby-build
  /puzzle/ruby-build/bin/ruby-build 2.7.1 /puzzle/ruby-2.7.1
  echo "export PATH=\$PATH:/puzzle/ruby-2.7.1/bin" >> ~/.bashrc
  echo "export RAILS_ENV={{RAILS_ENV}}" >> ~/.bashrc
  source ~/.bashrc
  /puzzle/ruby-2.7.1/bin/ruby -v > /dev/null
  if [ ! $? -eq 0 ]; then
    echo "Ruby not installed correctly?"
    exit 1
  fi
  echo "gem: --no-rdoc --no-ri" > ~/.gemrc
  /puzzle/ruby-2.7.1/bin/gem install bundler
  echo "DONE"
fi

sleep 1
echo
echo

echo "INSTALLING NODE..."
if [ -d "/puzzle/node-8.12" ]; then
  echo "SKIP"
else
  curl -s https://nodejs.org/dist/v8.12.0/node-v8.12.0-linux-x64.tar.xz > /tmp/node.tar.xz
  mkdir -p /puzzle/node-8.12
  tar xf /tmp/node.tar.xz --directory /puzzle/node-8.12 --strip-components=1
  rm /tmp/node.tar.xz
  echo "export PATH=$PATH:/puzzle/node-8.12/bin" >> ~/.bashrc
  source ~/.bashrc
  /puzzle/node-8.12/bin/node -v > /dev/null
  if [ ! $? -eq 0 ]; then
    echo "Node not installed correctly?"
    exit 1
  fi
  echo "DONE"
fi
