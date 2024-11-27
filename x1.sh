#!/bin/bash
sudo apt-get update
sudo apt-get dist-upgrade -Vy
sudo apt-get autoremove -y
sudo apt-get autoclean
sudo apt-get clean
sudo apt-add-repository ppa:fish-shell/release-3 -y
sudo apt install libwebkit2gtk-4.0-dev libgtk-3-dev libappindicator3-dev -y
sudo apt-get install fish -y
sudo apt install openvpn -y