#!/bin/sh

# Load mandatory modules
sudo insmod /lib/modules/dvb-core.ko
sudo insmod /lib/modules/rc-core.ko
sudo insmod /lib/modules/dvb-usb.ko
sudo insmod /lib/modules/videodev.ko
sudo insmod /lib/modules/v4l2-common.ko
sudo insmod /lib/modules/tveeprom.ko

# Load Hauppauge updated drivers
sudo insmod /usr/local/lib/modules/$(uname -r)/em28xx.ko
sudo insmod /usr/local/lib/modules/$(uname -r)/em28xx-dvb.ko
sudo insmod /usr/local/lib/modules/$(uname -r)/lgdt3306a.ko
sudo insmod /usr/local/lib/modules/$(uname -r)/media.ko
sudo insmod /lib/modules/si2157.ko
