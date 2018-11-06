#!/usr/bin/env bash

export RAILS_ENV={{RAILS_ENV}}
export DEPLOY_USER={{REMOTE_USER}}
export DEPLOY_HOST={{HOST}}
export DEPLOY_KEYS={{KEY}}
bin/bundle exec cap $RAILS_ENV deploy
