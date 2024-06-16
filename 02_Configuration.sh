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

clear

HOST_NAME=''
ROOT_PASSWD=''
USER=''
USER_PASSWD=''

clear
ZONEINFO="Europe/London"

# ------------------------------------------------------
# Set System Time
# ------------------------------------------------------

ln -sf /usr/share/zoneinfo/$ZONEINFO /etc/localtime
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

pacman --needed --noconfirm -S  grub efibootmgr reflector xdg-desktop-portal-wlr grub-btrfs
pacman --needed --noconfirm -S  networkmanager network-manager-applet wpa_supplicant efibootmgr dialog
pacman --needed --noconfirm -S  base-devel linux-headers pacman-contrib os-prober 
pacman --needed --noconfirm -S  xdg-user-dirs xdg-utils terminus-font
pacman --needed --noconfirm -S  zsh zsh-completions bat alsa-utils nfs-utils inetutils dnsutils brightnessctl
pacman --needed --noconfirm -S  udiskie ntfs-3g openssh bluez bluez-utils git moreutils htop zip unzip inxi hplip
pacman --needed --noconfirm -S  bluez bluez-utils cups firewalld mtools dosfstools avahi dnsmasq nss-mdns ipset
pacman --needed --noconfirm -S  pipewire pipewire-alsa pipewire-pulse pipewire-jack

# ------------------------------------------------------
# set lang utf8 US
# ------------------------------------------------------
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" >> /etc/locale.conf

# ------------------------------------------------------
# Set Keyboard
# ------------------------------------------------------
echo "FONT=ter-v18n" >> /etc/vconsole.conf
echo "KEYMAP=$keyboardlayout" >> /etc/vconsole.conf

# ------------------------------------------------------
# Set hostname and localhost
# ------------------------------------------------------
echo "$hostname" >> /etc/hostname
echo "127.0.0.1 localhost" >> /etc/hosts
echo "::1       localhost" >> /etc/hosts
echo "127.0.1.1 $hostname.localdomain $hostname" >> /etc/hosts
clear

# ------------------------------------------------------
# Set Root Password
# ------------------------------------------------------
echo "Set root password"
passwd root

# ------------------------------------------------------
# Add User
# ------------------------------------------------------
echo "Add user $username"
useradd -m -G wheel $username
passwd $username

# ------------------------------------------------------
# Enable Services
# ------------------------------------------------------
systemctl enable NetworkManager
systemctl enable bluetooth
systemctl enable cups.service
systemctl enable sshd
systemctl enable avahi-daemon
systemctl enable reflector.timer
systemctl enable fstrim.timer
systemctl enable firewalld
systemctl enable acpid

# ------------------------------------------------------
# Grub installation
# ------------------------------------------------------
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB --removable
grub-mkconfig -o /boot/grub/grub.cfg

# ------------------------------------------------------
# Add btrfs and setfont to mkinitcpio
# ------------------------------------------------------
# Before: BINARIES=()
# After:  BINARIES=(btrfs setfont)
sed -i 's/BINARIES=()/BINARIES=(btrfs setfont)/g' /etc/mkinitcpio.conf
mkinitcpio -p linux

# ------------------------------------------------------
# Add user to wheel
# ------------------------------------------------------
clear
echo "Uncomment %wheel group in sudoers (around line 85):"
echo "Before: #%wheel ALL=(ALL:ALL) ALL"
echo "After:  %wheel ALL=(ALL:ALL) ALL"
echo ""
read -p "Open sudoers now?" c
EDITOR=vim sudo -E visudo
usermod -aG wheel $username

# ------------------------------------------------------
# Copy installation scripts to home directory 
# ------------------------------------------------------
cp /archinstall/3-yay.sh /home/$username
cp /archinstall/4-zram.sh /home/$username
cp /archinstall/5-timeshift.sh /home/$username
cp /archinstall/6-preload.sh /home/$username
cp /archinstall/snapshot.sh /home/$username

clear
echo "     _                   "
echo "  __| | ___  _ __   ___  "
echo " / _' |/ _ \| '_ \ / _ \ "
echo "| (_| | (_) | | | |  __/ "
echo " \__,_|\___/|_| |_|\___| "
echo "                         "
echo ""
echo "Please find the following additional installation scripts in your home directory:"
echo "- yay AUR helper: 3-yay.sh"
echo "- zram swap: 4-zram.sh"
echo "- timeshift snapshot tool: 5-timeshift.sh"
echo "- preload application cache: 6-preload.sh"
echo ""
echo "Please exit & shutdown (shutdown -h now), remove the installation media and start again."
echo "Important: Activate WIFI after restart with nmtui."


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
# Set terminal keyboard
# ------------------------------------------------------

echo "KEYMAP=us-acentos" >> /etc/vconsole.conf
echo "FONT=ter-132n" >> /etc/vconsole.conf
echo "FONT_MAP=8859-1" >> /etc/vconsole.conf


# ------------------------------------------------------
# Set hostname and localhost
# ------------------------------------------------------

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

# ------------------------------------------------------
# Add User
# ------------------------------------------------------

echo "Add user $USER"
useradd -m -g users -s /bin/zsh "$USER"
echo "${USER}:${USER_PASSWD}" | chpasswd

# ------------------------------------------------------
# Enable Services
# ------------------------------------------------------
systemctl enable NetworkManager
systemctl enable bluetooth
systemctl enable cups.service
systemctl enable sshd
#systemctl enable avahi-daemon
systemctl enable reflector.timer
systemctl enable fstrim.timer
systemctl enable firewalld
systemctl enable acpid
systemctl enable paccache.timer


# ------------------------------------------------------
# Grub installation
# ------------------------------------------------------

grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB --removable
grub-mkconfig -o /boot/grub/grub.cfg

# ------------------------------------------------------
# Add btrfs and setfont to mkinitcpio

# Before: MODULE=()
# After:  MODULE=(btrfs nvidia nvidia_modeset nvidia_uvm nvidia_drm setfont)
# ------------------------------------------------------

sed -i 's/MODULE.*/MODULE=\(btrfs nvidia nvidia_modeset nvidia_uvm nvidia_drm\)/' /etc/mkinitcpio.conf
mkinitcpio -p linux


# ------------------------------------------------------
# Make user an administrator
# Add user permissions to file in sudoers.d folder under user name
# ------------------------------------------------------

clear

echo "$USER ALL=(ALL) ALL" >>"/etc/sudoers.d/$USER"

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

