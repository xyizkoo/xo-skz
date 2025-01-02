#!/bin/bash
sudo apt install xrdp -y
sudo systemctl status xrdp
sudo adduser xrdp ssl-cert
sudo systemctl restart xrdp