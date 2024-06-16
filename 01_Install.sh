#!/usr/bin/env sh

clear
#echo "    _             _       ___           _        _ _ "
#echo "   / \   _ __ ___| |__   |_ _|_ __  ___| |_ __ _| | |"
#echo "  / _ \ | '__/ __| '_ \   | || '_ \/ __| __/ _' | | |"
#echo " / ___ \| | | (__| | | |  | || | | \__ \ || (_| | | |"
#echo "/_/   \_\_|  \___|_| |_| |___|_| |_|___/\__\__,_|_|_|"
#echo ""
#echo ""
#echo "-----------------------------------------------------"
#echo ""
#echo "Important: Please make sure that you have partitioned the harddisc!"
#echo "------------------------------------------"
#echo "Warning: Run this script at your own risk."
#echo "------------------------------------------"
#echo ""

# ------------------------------------------------------
# Enter partition names
# ------------------------------------------------------

lsblk

read -p "Enter the name of the EFI partition (eg. sda1): " BOOTDRIVE
read -p "Enter the name of the ROOT partition (eg. sda2): " ROOTDRIVE


read -p "Enter the name of the drive Win 11 is on: " WINDOWS
read -p "Enter the name of the drive for joint Win11/Linux storage: " STORAGE

#-------------------------------------------------------
# Update mirrors
#-------------------------------------------------------

reflector -c "United Kingdom" -a 6 --sort rate --save /etc/pacman.d/mirrorlist
pacman -Syy

# ------------------------------------------------------
# Sync time
# Update network time protocol.
# ------------------------------------------------------

timedatectl set-ntp true

# ------------------------------------------------------
# Format partitions
# ------------------------------------------------------

mkfs.fat -F 32 /dev/$BOOTDRIVE;     #Format Boot partition.
mkfs.btrfs -f /dev/$ROOTDRIVE

# ------------------------------------------------------
# Mount points for btrfs
# Mount actual Vol: mnt
# Create the subvols: @ (root), @cache, @home, @snapshots, @log
# Unmount the actual Vol
# ------------------------------------------------------

mount /dev/$ROOTDRIVE /mnt
btrfs su cr /mnt/@
btrfs su cr /mnt/@cache
btrfs su cr /mnt/@home
btrfs su cr /mnt/@snapshots
btrfs su cr /mnt/@log
umount /mnt

# ------------------------------------------------------
# remount subvols with btrfs options
# ------------------------------------------------------

SSD_OPTIONS="noatime,ssd,compress=zstd,space_cache=v2,discard=async,subvol"

mount -o "$SSD_OPTIONS"=@ /dev/$ROOTDRIVE /mnt
mkdir -p /mnt/{boot/efi,home,.snapshots,var/{cache,log}}
mount -o "$SSD_OPTIONS"=@cache /dev/$ROOTDRIVE /mnt/var/cache
mount -o "$SSD_OPTIONS"=@home /dev/$ROOTDRIVE /mnt/home
mount -o "$SSD_OPTIONS"=@log /dev/$ROOTDRIVE /mnt/var/log
mount -o "$SSD_OPTIONS"=@snapshots /dev/$ROOTDRIVE /mnt/.snapshots
mount /dev/$BOOTDRIVE /mnt/boot/efi
# mkdir /mnt/vm
# mount /dev/$sda3 /mnt/vm


# ------------------------------------------------------
# Install base packages
# ------------------------------------------------------
pacstrap -K /mnt base base-devel git linux linux-firmware openssh reflector rsync intel-ucode neovim btrfs-progs


# ------------------------------------------------------
# Generate fstab
# ------------------------------------------------------
genfstab -U /mnt >> /mnt/etc/fstab
cat /mnt/etc/fstab

# ------------------------------------------------------
# Install configuration scripts
# ------------------------------------------------------
mkdir /mnt/archinstall
cp 2-configuration.sh /mnt/archinstall/


# ------------------------------------------------------
# Chroot to installed sytem
# ------------------------------------------------------
arch-chroot /mnt ./archinstall/2-configuration.sh

