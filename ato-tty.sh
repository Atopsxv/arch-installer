#!/usr/bin/env bash

clear

echo  .d8b.  d888888b  .d88b.        .d8b.  d8888b.  .o88b. db   db      .d8888.  .o88b. d8888b. d888888b d8888b. d888888b 
echo d8' `8b `~~88~~' .8P  Y8.      d8' `8b 88  `8D d8P  Y8 88   88      88'  YP d8P  Y8 88  `8D   `88'   88  `8D `~~88~~' 
echo 88ooo88    88    88    88      88ooo88 88oobY' 8P      88ooo88      `8bo.   8P      88oobY'    88    88oodD'    88    
echo 88~~~88    88    88    88      88~~~88 88`8b   8b      88~~~88        `Y8b. 8b      88`8b      88    88~~~      88    
echo 88   88    88    `8b  d8'      88   88 88 `88. Y8b  d8 88   88      db   8D Y8b  d8 88 `88.   .88.   88         88    
echo YP   YP    YP     `Y88P'       YP   YP 88   YD  `Y88P' YP   YP      `8888Y'  `Y88P' 88   YD Y888888P 88         YP    

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

echo -e "\nCreating Filesystems...\n"

mkfs.vfat -F32 -n "EFISYSTEM" "${EFI}"
mkswap "${SWAP}"
swapon "${SWAP}"
mkfs.ext4 -L "ROOT" "${ROOT}"

mount -t ext4 "${ROOT}" /mnt
mkdir /mnt/boot
mount -t vfat "${EFI}" /mnt/boot/

pacstrap /mnt base linux linux-firmware base-devel networkmanager git --noconfirm --needed

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
