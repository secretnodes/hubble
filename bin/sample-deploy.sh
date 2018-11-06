#!/usr/bin/env bash

export RAILS_ENV=staging
export DEPLOY_USER=ubuntu
export DEPLOY_HOST=ec2-N-N-N-N.ca-central-1.compute.amazonaws.com
export DEPLOY_KEYS=~/.ssh/hubble.pem
bin/bundle exec cap $RAILS_ENV deploy
