#!/usr/bin/env bash

clear

echo ░█████╗░████████╗░█████╗░  ░█████╗░██████╗░░█████╗░██╗░░██╗  ░██████╗░█████╗░██████╗░██╗██████╗░████████╗
echo ██╔══██╗╚══██╔══╝██╔══██╗  ██╔══██╗██╔══██╗██╔══██╗██║░░██║  ██╔════╝██╔══██╗██╔══██╗██║██╔══██╗╚══██╔══╝
echo ███████║░░░██║░░░██║░░██║  ███████║██████╔╝██║░░╚═╝███████║  ╚█████╗░██║░░╚═╝██████╔╝██║██████╔╝░░░██║░░░
echo ██╔══██║░░░██║░░░██║░░██║  ██╔══██║██╔══██╗██║░░██╗██╔══██║  ░╚═══██╗██║░░██╗██╔══██╗██║██╔═══╝░░░░██║░░░
echo ██║░░██║░░░██║░░░╚█████╔╝  ██║░░██║██║░░██║╚█████╔╝██║░░██║  ██████╔╝╚█████╔╝██║░░██║██║██║░░░░░░░░██║░░░

echo "enter EFI paritition: (example /dev/sda1)"
read EFI

echo "enter SWAP paritition: (example /dev/sda2)"
read SWAP

echo "enter Root paritition: (example /dev/sda3)"
read ROOT 

echo "enter username"
read USER 

echo "enter password"
read PASSWORD 

# make filesystems
echo -e "\nCreating Filesystems...\n"

mkfs.vfat -F32 -n "EFISYSTEM" "${EFI}"
mkswap "${SWAP}"
swapon "${SWAP}"
mkfs.ext4 -L "ROOT" "${ROOT}"

# mount target
mount -t ext4 "${ROOT}" /mnt
mkdir /mnt/boot
mount -t vfat "${EFI}" /mnt/boot/

pacstrap /mnt base linux linux-firmware base-devel networkmanager git --noconfirm --needed

# fstab
genfstab -U /mnt >> /mnt/etc/fstab

bootctl install --path /mnt/boot
echo "default arch.conf" >> /mnt/boot/loader/loader.conf
cat <<EOF > /mnt/boot/loader/entries/arch.conf
title Arch Linux
linux /vmlinuz-linux
initrd /initramfs-linux.img
options root=${ROOT} rw
EOF


cat <<REALEND > /mnt/next.sh
useradd -m $USER
usermod -aG wheel,storage,power,audio $USER
echo $USER:$PASSWORD | chpasswd
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

echo "Arch-Btw" > /etc/hostname

pacman -S xorg pulseaudio --noconfirm --needed

systemctl enable NetworkManager

REALEND

arch-chroot /mnt sh next.sh
