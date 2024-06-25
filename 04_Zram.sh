#!/bin/bash
#  _________      _    __  __ 
# |__  /  _ \    / \  |  \/  |
#   / /| |_) |  / _ \ | |\/| |
#  / /_|  _ <  / ___ \| |  | |
# /____|_| \_\/_/   \_\_|  |_|
#                       
# -----------------------------------------------------
# ZRAM Install Script

# -----------------------------------------------------

# WARNING: Run this script at your own risk.

clear
echo " _________      _    __  __ "
echo "|__  /  _ \    / \  |  \/  |"
echo "  / /| |_) |  / _ \ | |\/| |"
echo " / /_|  _ <  / ___ \| |  | |"
echo "/____|_| \_\/_/   \_\_|  |_|"
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

# -----------------------------------------------------
# Install zram
# -----------------------------------------------------
yay --noconfirm -S https://aur.archlinux.org/zramd.git

# -----------------------------------------------------
# Start/enable zram
# -----------------------------------------------------
sudo systemctl enable --now zramd

# -----------------------------------------------------
# Configure zram @ /etc/default/zramd
# -----------------------------------------------------

echo "DONE! ZRAM now installed and running."
