#!/usr/bin/env bash

echo "[Unit]
Description=Hubble Unicorn

[Service]
Type=forking
SyslogIdentifier=hubble-unicorn
User={{REMOTE_USER}}
Group={{REMOTE_USER}}
PIDFile=/hubble/app/shared/tmp/pids/unicorn.pid
WorkingDirectory=/hubble/app/current

ExecStart=/usr/local/bin/hubble-unicorn-{{RAILS_ENV}}.sh start
ExecReload=/usr/local/bin/hubble-unicorn-{{RAILS_ENV}}.sh upgrade
ExecStop=/usr/local/bin/hubble-unicorn-{{RAILS_ENV}}.sh stop

Restart=always
RestartSec=2

[Install]
WantedBy=multi-user.target" | sudo tee /etc/systemd/system/hubble-unicorn-{{RAILS_ENV}}.service
sudo systemctl enable hubble-unicorn-{{RAILS_ENV}}.service
