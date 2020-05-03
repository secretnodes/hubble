#!/usr/bin/env bash

export RAILS_ENV={{RAILS_ENV}}
export DEPLOY_USER={{REMOTE_USER}}
export DEPLOY_HOST={{HOST}}
export DEPLOY_KEYS={{KEY}}
if [ -z "$SSH_AUTH_SOCK" ] ; then
 eval `ssh-agent -s`
 ssh-add ~/.ssh/puzzle_id_rsa
fi
bin/bundle exec cap $RAILS_ENV deploy
