#!/bin/bash
apt update && sudo apt upgrade -y
apt install xfce4 xfce4-goodies xorg dbus-x11 x11-xserver-utils -y
apt install xrdp -y
systemctl status xrdp
adduser xrdp ssl-cert
systemctl restart xrdp
apt-get install gnome-software -y
sudo apt install flatpak -y
sudo apt install gnome-software-plugin-flatpak -y
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo