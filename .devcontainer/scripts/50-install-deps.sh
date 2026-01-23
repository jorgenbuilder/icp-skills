#!/bin/bash
set -e

echo "==> Installing dependencies..."

sudo npm install -g agent-browser
sudo -v
yes | sudo agent-browser install --with-deps -y
sudo npm i -g vercel