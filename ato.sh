#!/usr/bin/env bash

echo "enter EFI paritition: (example /dev/sda1)"
read EFI

echo "enter SWAP paritition: (example /dev/sda2)"
read SWAP

echo "enter Root(/) paritition: (example /dev/sda3)"
read ROOT 

echo "enter username"
read USER 

echo "enter password"
read PASSWORD 

echo "choose Your DE"
echo "1. GNOME"
echo "2. KDE"
echo "3. XFCE"
echo "4. just terminal knwon as the tty"
read DESKTOP

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

pacstrap /mnt base linux linux-firmware base-devel networkmanager nano git vim --noconfirm --needed

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

sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" >> /etc/locale.conf

echo "Arch-Btw" > /etc/hostname
cat <<EOF > /etc/hosts
EOF

pacman -S xorg pulseaudio --noconfirm --needed

systemctl enable NetworkManager

#DESKTOP ENVIRONMENT
if [[ $DESKTOP == '1' ]]
then 
    pacman -S gnome gdm --noconfirm --needed
    systemctl enable gdm
elif [[ $DESKTOP == '2' ]]
then
    pacman -S plasma sddm --noconfirm --needed
    systemctl enable sddm
elif [[ $DESKTOP == '3' ]]
then
    pacman -S xfce4 lightdm lightdm-gtk-greeter --noconfirm --needed
    systemctl enable lightdm
else
    echo "TTY has been choosen"
fi

REALEND

arch-chroot /mnt sh next.sh
