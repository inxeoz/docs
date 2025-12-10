#!/bin/bash

sudo cloudflared service uninstall
sudo rm /etc/cloudflared/config.yml
sudo systemctl daemon-reload

sudo mkdir -p /etc/cloudflared
sudo cp ~/.cloudflared/config.yml /etc/cloudflared/
sudo cp ~/.cloudflared/cert.pem /etc/cloudflared/
sudo cp ~/.cloudflared/*.json /etc/cloudflared/
sudo chmod 600 /etc/cloudflared/*   # cloudflared requires strict perms

sudo cloudflared service install
