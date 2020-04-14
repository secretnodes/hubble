#!/usr/bin/env bash

set -e

if [ -z PUZZLE_RAILS_ENV ]; then echo "Specify RAILS_ENV"; exit 1; fi
if [ -z PUZZLE_KEY ]; then echo "Specify ssh key in KEY"; exit 1; fi
if [ -z PUZZLE_HOST ]; then echo "Specify HOST to set up"; exit 1; fi
if [ -z PUZZLE_DOMAIN ]; then echo "Specify DOMAIN to run on"; exit 1; fi
if [ -z PUZZLE_REMOTE_USER ]; then echo "Specify REMOTE_USER to setup as"; exit 1; fi
if [ -z PUZZLE_ADMIN_EMAIL ]; then echo "Specify an email (for admin account & SSL certificate)"; exit 1; fi

echo
echo "Run setup..."
cat setup/templates/setup.sh | \
sed "s/{{RAILS_ENV}}/$PUZZLE_RAILS_ENV/g" | \
ssh -i $PUZZLE_KEY $PUZZLE_REMOTE_USER@$PUZZLE_HOST "bash -"

echo
echo "Deploying..."
DEPLOY_HOST=$PUZZLE_HOST DEPLOY_KEYS=$PUZZLE_KEY NO_RESTART=1 NO_WHENEVER_SETUP=1 bin/bundle exec cap $PUZZLE_RAILS_ENV deploy
echo "OK"

echo
echo "Setup certificate..."
echo
echo "***************************"
echo "Use the following command (in another shell) to help check when your DNS record is propagated:"
echo "while [ \$(dig +trace +short @8.8.8.8 @8.8.4.4 -t TXT _acme-challenge.$PUZZLE_DOMAIN | grep TXT | wc -l) -eq 0 ]; do echo -n '.'; sleep 5; done; echo 'DONE'"
echo "***************************"
echo
sleep 5
ssh -i $PUZZLE_KEY $PUZZLE_REMOTE_USER@$PUZZLE_HOST "sudo certbot --agree-tos --no-eff-email --email $PUZZLE_ADMIN_EMAIL --manual-public-ip-logging-ok --manual --preferred-challenges dns --domain $PUZZLE_DOMAIN certonly && echo SUCCESS || echo FAILED"
sleep 5

echo
echo "Install nginx config..."
cat setup/templates/site.conf | \
sed "s/{{DOMAIN}}/$PUZZLE_DOMAIN/g" | \
sed "s/{{RAILS_ENV}}/$PUZZLE_RAILS_ENV/g" | \
ssh -i $PUZZLE_KEY $PUZZLE_REMOTE_USER@$PUZZLE_HOST "cat - | sudo tee /etc/nginx/sites-available/$PUZZLE_DOMAIN.conf && sudo rm -f /etc/nginx/sites-enabled/default && sudo ln -sf /etc/nginx/sites-available/$PUZZLE_DOMAIN.conf /etc/nginx/sites-enabled/$PUZZLE_DOMAIN.conf && sudo systemctl reload nginx" > /dev/null
if [ $? -eq 0 ]; then
  echo "OK"
else
  echo "FAILED"
  exit 1
fi

echo
echo "Install app service..."
cat setup/templates/unicorn.sh | \
sed "s/{{RAILS_ENV}}/$PUZZLE_RAILS_ENV/g" | \
ssh -i $PUZZLE_KEY $PUZZLE_REMOTE_USER@$PUZZLE_HOST "cat - | sudo tee /usr/local/bin/puzzle-unicorn-$PUZZLE_RAILS_ENV.sh && sudo chmod +x /usr/local/bin/puzzle-unicorn-$PUZZLE_RAILS_ENV.sh" > /dev/null &&
cat setup/templates/service.sh | \
sed "s/{{RAILS_ENV}}/$PUZZLE_RAILS_ENV/g" | \
sed "s/{{REMOTE_USER}}/$PUZZLE_REMOTE_USER/g" | \
ssh -i $PUZZLE_KEY $PUZZLE_REMOTE_USER@$PUZZLE_HOST "bash -"
echo "OK"

echo
echo "Generating deploy script..."
cat setup/templates/deploy.sh | \
sed "s/{{RAILS_ENV}}/$PUZZLE_RAILS_ENV/g" | \
sed "s/{{REMOTE_USER}}/$PUZZLE_REMOTE_USER/g" | \
sed "s/{{HOST}}/$PUZZLE_HOST/g" | \
sed "s%{{KEY}}%$PUZZLE_KEY%g" | \
tee ./bin/deploy-$PUZZLE_RAILS_ENV.sh > /dev/null
chmod +x ./bin/deploy-$PUZZLE_RAILS_ENV.sh
echo "OK"

echo
echo "Creating admin user..."
cmd="export PATH=/puzzle/ruby-2.5.0/bin:/puzzle/node-8.12/bin:\$PATH && cd /puzzle/app/current && bin/rails runner -e $PUZZLE_RAILS_ENV \"admin = Administrator.find_by(email: '$PUZZLE_ADMIN_EMAIL') || Administrator.create(name: 'Admin', email: '$PUZZLE_ADMIN_EMAIL', one_time_setup_token: SecureRandom.hex); exit(0) if admin.is_set_up?; puts %{Admin Setup: https://$PUZZLE_DOMAIN/admin/sessions/new?token=#{admin.one_time_setup_token}}\""
ssh -i $PUZZLE_KEY $PUZZLE_REMOTE_USER@$PUZZLE_HOST "$cmd"
echo "OK"

echo
echo "Starting app..."
ssh -i $PUZZLE_KEY $PUZZLE_REMOTE_USER@$PUZZLE_HOST "sudo systemctl start puzzle-unicorn-$PUZZLE_RAILS_ENV"
echo "OK"
