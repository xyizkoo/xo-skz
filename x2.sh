#!/usr/bin/bash
set -euo pipefail

# Color
CYAN='\e[36;1m'
GREEN='\e[32m'
RESET='\e[0m'
YELLOW='\e[33m'

# Variables
t1='
----
Installing wifi drivers from 
https://github.com/RinCat/RTL88x2BU-Linux-Driver
---
'

# Functions
b1() {
    clear
    echo -e "${CYAN} ${t1} ${RESET}"
}

b2() {
    echo -e "${GREEN} sudo apt install linux-headers-$(uname -r) ${RESET}"
    echo -e "${GREEN} git clone https://github.com/RinCat/RTL88x2BU-Linux-Driver  ${RESET}"
    echo -e "${GREEN} make clean ${RESET}"
    echo -e "${GREEN} make ${RESET}"
    echo -e "${GREEN} sudo make install ${RESET}"
    echo -e ""
    echo -e "Executing..."
}

e1() {
    echo ""
    echo -e "${YELLOW}sudo apt install linux-headers-$(uname -r) ${RESET}"
    sudo apt install linux-headers-$(uname -r)
    echo -e "${GREEN}DONE....  ${RESET}"
    echo ""
    echo -e "${YELLOW}git clone https://github.com/RinCat/RTL88x2BU-Linux-Driver ${RESET}"
    git clone https://github.com/RinCat/RTL88x2BU-Linux-Driver
    echo -e "${GREEN}DONE....  ${RESET}"
    echo ""
    echo -e "${YELLOW}make clean ${RESET}"
    cd RTL88x2BU-Linux-Driver
    make clean
    make
    echo -e "${GREEN}DONE....  ${RESET}"
    echo ""
    echo -e "${YELLOW}sudo make install ${RESET}"
    sudo make install
    echo -e "${GREEN}DONE....  ${RESET}"
    echo ""
}

# Execution
b1
b2
e1