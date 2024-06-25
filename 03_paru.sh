#!/bin/bash
#         
# |  _ \   __ _ _ __  _   _
# | |_) | / _` | '__/| | | |
# |  __/|| (_| | |   | |_| |
# |_|     \__,_|_|   \__,|_|         
# ------------------------------------------------------
# Install Script for Paru
# ------------------------------------------------------

# WARNING: Run this script at your own risk.

clear
echo " |  _ \   __ _ _ __  _   _  "
echo " | |_) | / _` | '__/| | | | "
echo " |  __/|| (_| | |   | |_| | " 
echo " |_|     \__,_|_|   \__,|_| "
echo "                 "
echo ""

# -----------------------------------------------------
# Confirm Start
# -----------------------------------------------------
while true; do
    read -p "DO YOU WANT TO START THE INSTALLATION NOW? (Yy/Nn): " yn
    case $yn in
        [Yy]* )
            echo "Installation started."
        break;;
        [Nn]* ) 
            exit;
        break;;
        * ) echo "Please answer yes or no.";;
    esac
done
git clone https://aur.archlinux.org/paru-git.git 
cd yay-git
makepkg -si

echo "DONE!
