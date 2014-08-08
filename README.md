BananaPi img Generator
======================

A simple script and files to build a bootable SD img for the BananaPi board.

*Tested on Ubuntu 14.04 Desktop*

**Required
* GNU parted

**Setup your environement
You need 7Gb free space to run this script (depending of the RootFS used).
```bash
sudo apt-get update
sudo apt-get upgrade
sudo apt-get install kpartx build-essential u-boot-tools binutils-arm-linux-gnueabihf gcc-4.7-arm-linux-gnueabihf-base g++-4.7-arm-linux-gnueabihf gcc-arm-linux-gnueabihf cpp-arm-linux-gnueabihf libusb-1.0-0 libusb-1.0-0-dev git wget fakeroot kernel-package zlib1g-dev libncurses5-dev
```
*From [Building u-boot, script.bin and linux-kernel](http://wiki.lemaker.org/index.php?title=Building_u-boot,_script.bin_and_linux-kernel)*

Clone or copy your **RootFS** in a directory named root-fs near the build script.
*E.G. for Volumio RootFS ARMv7 :*
```bash
git clone https://github.com/volumio/RootFS.git root-fs
```

This script will clone the following repos to build the system.
* [u-boot-bananapi by LeMaker](https://github.com/LeMaker/u-boot-bananapi.git)
* [sunxi-tools by LeMaker](https://github.com/LeMaker/sunxi-tools.git)
* [sunxi-boards by LeMaker](https://github.com/LeMaker/sunxi-boards.git)
* [linux-bananapi by LeMaker](https://github.com/LeMaker/linux-bananapi.git)

**Run
```bash
./build.sh
```
The first build take a while.
You'll need to enter you password to enable the sudo access.
If you don't need to change the kernel config choose **exit** in the *menuconfig*.
The builded img is named **bananapi.img**.

***Why...
- I don't use [bananapi-bsp](https://github.com/LeMaker/bananapi-bsp)?
This BSP clone the needed repos at every build and take long time.
- Lot of *sudo* in the script?
I prefere to run this script in user environement to reduce the risque of bad manipulation. Specialy during the build kernel and modules.

***Inspired by :
* [LeMaker Wiki](http://wiki.lemaker.org/).
* [OpenElec create SD script](http://wiki.openelec.tv/index.php?title=Installing_OpenELEC_on_Raspberry_Pi).

**ToDo :
* Add a way to patch the fex file.
* Add a way to patch the KConfig.