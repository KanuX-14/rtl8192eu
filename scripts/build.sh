#!/bin/bash

# Environment variables
CURRENT_SHELL=$(ps -hp $$ | awk '{printf $5}')
CURRENT_USER=$(whoami)
CURRENT_HOME=""
CURRENT_PWD=$(pwd)
CORE=$(nproc)
IS_NOT_BLACKLISTED=$(cat /etc/modprobe.d/realtek.conf | grep "blacklist r8192eu")
INSTALLATION_PATH_DOES_NOT_EXIST=$(printf $PATH | grep /usr/local/sbin)
DO_DIRECTORY_EXISTS=0

# Colours
RED="\e[1;31m"
GREEN="\e[1;32m"
YELLOW="\e[1;33m"
BLUE="\e[1;34m"
PURPLE="\e[1;35m"
CYAN="\e[1;36m"
RESET_COLOUR="\e[0m"

# Set home based on user or root
if [ ${CURRENT_USER} == "root" ]; then
	CURRENT_HOME="/root"
else
	CURRENT_HOME="/home/${CURRENT_USER}"
fi

# Check if the repository already exists
if ! [ -d ../rtl8192eu ]; then
	if ! [ -d ${CURRENT_HOME}/rtl8192eu ]; then
		git clone --recursive https://gitlab.com/KanuX/rtl8192eu.git
	else
		printf "${YELLOW}""[!] Repository already exists.""${RESET_COLOUR}""\n"
	fi
	cd "${CURRENT_HOME}/rtl8192eu"
fi

# Check if the device is already blacklisted.
if [ -z "${IS_NOT_BLACKLISTED}" ]; then
	sudo mkdir -pv /etc/modprobe.d
	printf "blacklist r8192eu\n" | sudo tee "/etc/modprobe.d/realtek.conf"
fi

# Check if /usr/local/sbin exists.
if [ -z "${INSTALLATION_PATH_DOES_NOT_EXIST}" ]; then
	sudo mkdir -pv /usr/local/sbin
	printf "export PATH=/usr/local/sbin:$PATH\n" >> ."${CURRENT_SHELL}""rc"
fi

# Check the package manager.
if type dpkg &>/dev/null; then
	sudo apt-get update && sudo apt-get install gawk tar git gcc bc make linux-headers-$(uname -r) zenity -y
elif type pacman &>/dev/null; then
	sudo pacman -S --needed --noconfirm gawk tar git gcc bc make linux-headers zenity
elif type dnf &>/dev/null; then
	sudo dnf install -y gawk tar git gcc bc make kernel-devel zenity
else
	printf "${GREEN}""Consider installing the kernel headers by yourself.""${RESET_COLOUR}""\n"
fi

# Installation process.
sudo rmmod r8192eu # This one can be anything. I am using this one because is the common TL-WN722N v2/v3
sudo rmmod 8192eu 2&>/dev/null # Remove old/installed module. Visual purposes.
make -j${CORE} && sudo make install
sudo modprobe 8192eu # Load the new driver/module
sudo cp -v scripts/toggle-monitor.sh /usr/local/bin/toggle-monitor
sudo chown ${USER}:${USER} /usr/local/bin/toggle-monitor
sudo chmod +x /usr/local/bin/toggle-monitor
sudo cp -v rtl8192eu-toggle-monitor.desktop /usr/share/applications
printf "${GREEN}""The driver/module has been installed!""${RESET_COLOUR}""\n"
notify-send "The driver/module has been installed!"
