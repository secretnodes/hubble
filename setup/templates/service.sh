#!/usr/bin/env bash

echo "[Unit]
Description=Hubble Unicorn

[Service]
Type=forking
SyslogIdentifier=puzzle-unicorn
User={{REMOTE_USER}}
Group={{REMOTE_USER}}
PIDFile=/puzzle/app/shared/tmp/pids/unicorn.pid
WorkingDirectory=/puzzle/app/current

ExecStart=/usr/local/bin/puzzle-unicorn-{{RAILS_ENV}}.sh start
ExecReload=/usr/local/bin/puzzle-unicorn-{{RAILS_ENV}}.sh upgrade
ExecStop=/usr/local/bin/puzzle-unicorn-{{RAILS_ENV}}.sh stop

Restart=always
RestartSec=2

[Install]
WantedBy=multi-user.target" | sudo tee /etc/systemd/system/puzzle-unicorn-{{RAILS_ENV}}.service
sudo systemctl enable puzzle-unicorn-{{RAILS_ENV}}.service
