#!/bin/bash

if [ ! -d root-fs ]; then
	echo
	echo "###############################################"
	echo "# Error : The script need a root-fs directory #"
	echo "###############################################"
	echo
	exit 1
fi

rm -rf build
mkdir -p build

echo
echo "############################"
echo "# Creating u-boot-bananapi #"
echo "############################"
echo
if [ ! -d u-boot-bananapi ]; then
	git clone https://github.com/LeMaker/u-boot-bananapi.git
elif [ -d u-boot-bananapi ]; then
	( cd u-boot-bananapi && git pull )
fi
(cd u-boot-bananapi && 
	make CROSS_COMPILE=arm-linux-gnueabihf- Bananapi_config && 
	make CROSS_COMPILE=arm-linux-gnueabihf-
	cp u-boot-sunxi-with-spl.bin ../build/u-boot-sunxi-with-spl.bin)

echo
echo "########################"
echo "# Creating sunxi-tools #"
echo "########################"
echo
if [ ! -d sunxi-tools ]; then
	git clone https://github.com/LeMaker/sunxi-tools.git
elif [ -d sunxi-tools ]; then
	( cd sunxi-tools && git pull )
fi
(cd sunxi-tools && 
	make clean && 
	make)

echo
echo "#######################"
echo "# Creating script.bin #"
echo "#######################"
echo
if [ ! -d sunxi-boards ]; then
	git clone https://github.com/LeMaker/sunxi-boards.git
elif [ -d sunxi-boards ]; then
	( cd sunxi-boards && git pull )
fi
cp sunxi-boards/sys_config/a20/Bananapi.fex Bananapi.fex
# TODO : patch Bananapi.fex here
sunxi-tools/fex2bin Bananapi.fex build/script.bin


echo
echo "###################"
echo "# Creating uImage #"
echo "###################"
echo
if [ ! -d linux-bananapi ]; then
	git clone https://github.com/LeMaker/linux-bananapi.git
elif [ -d linux-bananapi ]; then
	( cd linux-bananapi && git pull )
fi
( cd linux-bananapi &&
	make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- sun7i_defconfig &&
	make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- menuconfig &&
	make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- uImage modules &&
	cp arch/arm/boot/uImage ../build/uImage &&
	cp .config ../build/.config &&
	make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- INSTALL_MOD_PATH=../build/modules modules_install )

IMG_FILE="bananapi.img"

echo
echo "#####################"
echo "# Creating img file #"
echo "#####################"
echo
dd if=/dev/zero of=${IMG_FILE} bs=1M count=3500
LOOP_DEV=`sudo losetup -f --show ${IMG_FILE}`
LOOP_PART_BOOT="${LOOP_DEV}p1"
LOOP_PART_SYS="${LOOP_DEV}p2"
echo
echo "#########################"
echo " +>${LOOP_DEV} "
echo " +->${LOOP_PART_BOOT} "
echo " +->${LOOP_PART_SYS} "
echo "#########################"
echo

echo
echo "#############################"
echo "# Creating partitions table #"
echo "#############################"
echo

sudo parted -s "${LOOP_DEV}" mklabel msdos
sudo parted -s "${LOOP_DEV}" unit cyl mkpart primary fat32 -- 0 2cyl
sudo parted -s "${LOOP_DEV}" unit cyl mkpart primary ext2 -- 2cyl -0
sudo parted -s "${LOOP_DEV}" set 1 boot on
sudo parted -s "${LOOP_DEV}" print
sudo partprobe "${LOOP_DEV}"

echo
echo "########################"
echo "# Creating filesystems #"
echo "########################"
echo
sudo mkfs.vfat "${LOOP_PART_BOOT}" -I -n boot
sudo mkfs.ext4 -O ^has_journal -E stride=2,stripe-width=1024 -b 4096 "${LOOP_PART_SYS}" -L system
sync

echo
echo "##########################"
echo "# Burning the bootloader #"
echo "##########################"
echo
sudo dd if=/dev/zero of=${LOOP_DEV} bs=1k count=1023 seek=1
sudo dd if=build/u-boot-sunxi-with-spl.bin of=${LOOP_DEV} bs=1024 seek=8
sync

echo
echo "######################"
echo "# Copying boot files #"
echo "######################"
echo
sudo mount -t vfat "${LOOP_PART_BOOT}" /mnt
sudo cp build/uImage /mnt
sudo cp build/script.bin /mnt
sudo cp uEnv.txt /mnt
sudo cp build/.config /mnt
sync

ls -al /mnt

sudo umount /mnt

echo
echo "##################"
echo "# Copying rootfs #"
echo "##################"
echo
sudo mount -t ext4 "${LOOP_PART_SYS}" /mnt
sudo rm -rf /mnt/*
sudo cp -r root-fs/* /mnt
if [ -f /mnt/README.md ]; then
	sudo rm -rf /mnt/README.md
fi
sync

echo
echo "###################"
echo "# Copying modules #"
echo "###################"
echo
sudo mkdir -p /mnt/lib/modules
sudo rm -rf /mnt/lib/modules/
sudo cp -r build/modules/lib /mnt/
sync

echo
echo "############################################"
echo "# Creating /proc, /sys, /mnt, /tmp & /boot #"
echo "############################################"
echo
sudo mkdir -p /mnt/proc
sudo mkdir -p /mnt/sys
sudo mkdir -p /mnt/mnt
sudo mkdir -p /mnt/tmp
sudo mkdir -p /mnt/boot
sync

ls -al /mnt

sudo umount /mnt

echo
echo Umount
echo
sudo losetup -d ${LOOP_DEV}