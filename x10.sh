#!/bin/bash
sudo apt install openssh-server
sudo systemctl start ssh 
sudo systemctl enable ssh
sudo systemctl restart ssh
sudo apt install xrdp -y
sudo systemctl status xrdp
sudo adduser xrdp ssl-cert
sudo systemctl restart xrdp