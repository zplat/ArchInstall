#!/bin/bash

#   ____             __ _                       _   _             
#  / ___|___  _ __  / _(_) __ _ _   _ _ __ __ _| |_(_) ___  _ __  
# | |   / _ \| '_ \| |_| |/ _` | | | | '__/ _` | __| |/ _ \| '_ \ 
# | |__| (_) | | | |  _| | (_| | |_| | | | (_| | |_| | (_) | | | |
#  \____\___/|_| |_|_| |_|\__, |\__,_|_|  \__,_|\__|_|\___/|_| |_|
#                         |___/                                   

# ------------------------------------------------------
# Key variables
# ------------------------------------------------------

HOST_NAME=''
ROOT_PASSWD=''
USER=''
USER_PASSWD=''

ARCH_RESPOSITORY=''

# ------------------------------------------------------
# Set System Time
# ------------------------------------------------------

ln -sf /usr/share/zoneinfo/Europe/London /etc/localtime
hwclock --systohc

# ------------------------------------------------------
# Update reflector
# ------------------------------------------------------

echo "Start reflector..."
reflector -c "United Kingdom" -p https -a 6 --sort rate --save /etc/pacman.d/mirrorlist

# ------------------------------------------------------
# Synchronize mirrors
# ------------------------------------------------------

pacman -Syy

# ------------------------------------------------------
# Install Packages
# ------------------------------------------------------

pacman --needed --noconfirm -S  grub efibootmgr grub-btrfs reflector pacman-contrib xdg-user-dirs xdg-utils terminus-font
pacman --needed --noconfirm -S  networkmanager network-manager-applet wpa_supplicant dialog
pacman --needed --noconfirm -S  base-devel linux-headers
pacman --needed --noconfirm -S  zsh zsh-completions bat git cups openssh udiskie 
#pacman --needed --noconfirm -S  nfs-utils inetutils nss-mdns dnsmasq
pacman --needed --noconfirm -S  ntfs-3g htop zip unzip hplip mtools dosfstools moreutils inxi
pacman --needed --noconfirm -S  bluez bluez-utils firewalld ipset
pacman --needed --noconfirm -S  pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber alsa-utils
pacman --needed --noconfirm -S  nvidia nvidia-utils nvidia-settings opencl-nvidia
# ------------------------------------------------------

# ------------------------------------------------------
# set language locale.
# Configure locale.conf.
# set lang utf8 GB
# ------------------------------------------------------

echo "en_GB.UTF-8 UTF-8" >> /etc/locale.gen
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
echo "ja_JP.UTF-8 UTF-8" >> /etc/locale.gen
echo "ko_KR.UTF-8 UTF-8" >> /etc/locale.gen #Well over the top!

locale-gen

echo "LANG=en_GB.UTF-8" >> /etc/locale.conf

# ------------------------------------------------------
# Set Keyboard
# ------------------------------------------------------

echo "FONT=ter-v18n" >> /etc/vconsole.conf
echo "KEYMAP=us-acentos" >> /etc/vconsole.conf
echo "FONT_MAP=8859-1" >> /etc/vconsole.conf

# ------------------------------------------------------
# Set hostname and localhost
# ------------------------------------------------------

echo "Set hostname and localhost"
echo "$HOST_NAME" >>/etc/hostname
echo "127.0.0.1 localhost" >> /etc/hosts
echo "::1       localhost" >> /etc/hosts
echo "127.0.1.1  ${HOST_NAME}.localdomain $HOST_NAME" >> /etc/hosts
clear

# ------------------------------------------------------
# Set Root Password
# ------------------------------------------------------

echo "Set root password"
echo "root:${ROOT_PASSWD}" | chpasswd
clear

# ------------------------------------------------------
# Add User and password
# ------------------------------------------------------

echo "Add user $USER"
useradd -m -g users -s /bin/zsh "$USER"
echo "set user password"
echo "${USER}:${USER_PASSWD}" | chpasswd
clear

# ------------------------------------------------------
# Enable Services
# ------------------------------------------------------

systemctl enable NetworkManager
systemctl enable bluetooth
systemctl enable cups.service
systemctl enable sshd
systemctl enable reflector.timer
systemctl enable fstrim.timer
systemctl enable firewalld
systemctl enable paccache.timer

# ------------------------------------------------------
# Grub installation
# ------------------------------------------------------

echo "Install Grub"
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB --removable
grub-mkconfig -o /boot/grub/grub.cfg
clear

# ------------------------------------------------------
# Update pacman repositories. multilib.
# ------------------------------------------------------

sed -i 's/^#\[multilib\]/\[multilib\]/' /etc/pacman.conf
sed -i '/^\[multilib\]/ {n;s/^#//}' /etc/pacman.conf
sed -i '/^#ParallelDownloads/ {n;s//ILoveCandy/}' /etc/pacman.conf
sed -i 's/^#ParallelDownloads/ParallelDownloads' /etc/pacman.conf
sed -i 's/^#Color/Color' /etc/pacman.conf
pacman -Syy

# ------------------------------------------------------
# change shell bash to zsh
# ------------------------------------------------------

chsh -s /bin/zsh

# ------------------------------------------------------
# Add btrfs, setfont and nvidia to mkinitcpio
# Before: MODULE=()
# After:  MODULE=(btrfs nvidia nvidia_modeset nvidia_uvm nvidia_drm setfont)
# ------------------------------------------------------

echo "Update mkinitcpio.conf and update linux"
sed -i 's/MODULE.*/MODULE=\(btrfs nvidia nvidia_modeset nvidia_uvm nvidia_drm setfont\)/' /etc/mkinitcpio.conf
mkinitcpio -p linux
clear

# ------------------------------------------------------
# Setup systemctl hooks
# ------------------------------------------------------

#   Set reflector defaults

echo "# Set the output path where the mirrorlist will be saved (--save).
--save /etc/pacman.d/mirrorlist
# Select the transfer protocol (--protocol).
--protocol https
# Select the country (--country).
# Consult the list of available countries with "reflector --list-countries" and
# select the countries nearest to you or the ones that you trust. For example:
--country FR,DE,IE,NL,GB
# Use only the  most recently synchronized mirrors (--latest).
--latest 100
# Sort the mirrors by synchronization time (--sort).
--sort score
" >/etc/xdg/reflector/reflector.conf

#    Automate package cleaning with paccache

echo "[Trigger]
Operation = Remove
Operation = Install
Operation = Upgrade
Type = Package
Target = *
[Action]
Description = Keep the last cache and the currently installed.
When = PostTransaction
Exec = /usr/bin/paccache -rvk2
" >/usr/share/libalpm/hooks/paccache.hook

#   List of orphan apps to remove

echo "[Trigger]
Operation = Install
Operation = Remove
Type = Package
Target = *
[Action]
When = PostTransaction
Exec = /usr/bin/bash -c \"/usr/bin/pacman -Qtd > $ARCH_RESPOSITORY/orphanpkglist.txt || /usr/bin/echo '==> no orphans found'\"
" >/usr/share/libalpm/hooks/pkgClean.hook

#    List of Core programs installed

echo "[Trigger]
Operation = Install
Operation = Remove
Type = Package
Target = *
[Action]
When = PostTransaction
Exec = /bin/sh -c '/usr/bin/pacman -Qqent > $ARCH_RESPOSITORY/corepkglist.txt'
" >/usr/share/libalpm/hooks/pkgCore.hook

#    List of AUR programs installed

echo "[Trigger]
Operation = Install
Operation = Remove
Type = Package
Target = *
[Action]
When = PostTransaction
Exec = /bin/sh -c '/usr/bin/pacman -Qqem > $ARCH_RESPOSITORY/aurpkglist.txt'
" >/usr/share/libalpm/hooks/pkgAUR.hook

# ------------------------------------------------------
# cacche
# ------------------------------------------------------

pacman -S ccache
sed -i 'x;/^BUILDENV/s/!ccache/ccache/' /etc/makepkg.conf

# ------------------------------------------------------
# MAKEFLAGS
# ------------------------------------------------------

CORES=$(nproc)
LOAD=$((CORES / 2))
JOBS=$((LOAD + 1))
sed -i "x;/^#MAKEFLAGS/s/"-j2"/-j${JOBS} -l${LOAD}/ " /etc/makepkg.conf
sed -i "x;/^#MAKEFLAGS/s/^#//" /etc/makepkg.conf


# ------------------------------------------------------
# Make user an administrator
# Add user permissions to file in sudoers.d folder under user name
# ------------------------------------------------------

echo "enable user to have super user permissions"
echo "$USER ALL=(ALL) ALL" >>"/etc/sudoers.d/$USER"
clear


# ------------------------------------------------------
# Copy installation scripts to home directory 
# ------------------------------------------------------
#cp /archinstall/3-yay.sh /home/$USER
#cp /archinstall/4-zram.sh /home/$USER
#cp /archinstall/5-timeshift.sh /home/$USER
#cp /archinstall/6-preload.sh /home/$USER
#cp /archinstall/snapshot.sh /home/$USER

clear
echo "     _                   "
echo "  __| | ___  _ __   ___  "
echo " / _' |/ _ \| '_ \ / _ \ "
echo "| (_| | (_) | | | |  __/ "
echo " \__,_|\___/|_| |_|\___| "
echo "                         "
echo ""
echo ""
echo "Please exit & shutdown (shutdown -h now), remove the installation media and start again."


echo "Please exit & shutdown (shutdown -h now), remove the installation media and start again."
echo "Important: Activate WIFI after restart with nmtui."

# ------------------------------------------------------
# Remove file permanently
# ------------------------------------------------------
shred -uvz 02_Configuration.sh
