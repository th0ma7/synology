# synology - th0ma7
Synology personnal hack, info, tools &amp; source code

Donnations welcomed at: `0x522d164549E68681dfaC850A2cabdb95686C1fEC`

# Hauppauge WinTV DualHD HWC 955D
The following allows building kernel modules for the Hauppauge WinTV DualHD HWC 955D media adapter allowing to use TVheadEnd (TVH) natively within the NAS.
* https://www.linuxtv.org/wiki/index.php/Hauppauge_WinTV-HVR-955Q

In theory this procedure is also valid to build most supported DVB adaptors available from the Media Tree within the Linux Media Subsystem.
* https://linuxtv.org/wiki/index.php/ATSC_USB_devices
* https://linuxtv.org/wiki/index.php/DVB-C_USB_Devices

Tested on the following hardware:
* model: DS918+
* OS: DSM 6.2.2 build #24922
* kernel: 4.4.59+
* arch: x86_64
* core name: Apollo Lake

Finding your running kernel:
```
$ uname -mvr
4.4.59+ #24922 SMP PREEMPT Thu Mar 28 11:07:03 CST 2019 x86_64
```

Finding your CPU type:
* https://en.wikichip.org/wiki/intel/celeron/j3455
```
$ cat /proc/cpuinfo | grep model.name | head -1
model name	: Intel(R) Celeron(R) CPU J3455 @ 1.50GHz
```

## Current status
I had backported patches to the Synology DSM 6.x 4.4.59+ kernel but there where a few pending issues.  Since then b-rad-NDi ended-up providing a backporting tool that allows rebuilding the media tree over the Synology DSM kernel.  This solution as been playing really nicely on my NAS over the last months.  _Big thanks to b-rad-NDi!!!_

For more details on b-rad-NDi project refer to:
* https://github.com/b-rad-NDi/Embedded-MediaDrivers

Working:
- `em28xx`: both tuners detected & firmware loading OK
- `lgdt3306a`: fully functional

End result:
- `tvheadend`: fully detects both tuners

Instead of building your own I've made available a pre-built module package for Hauppauge 955D USB DVB dongle to work on Synology NAS 6.2.2 kernel 4.4.59+ with Apollolake CPU (e.g. DS918+):
* https://github.com/th0ma7/synology/raw/master/hauppauge/hauppauge955D-SYNOApollolake-DSM622_24922-Kernel_4.4.59-20190520.tar.bz2

## Preparation
Using a Ubuntu 18.04 OS to build the updated modules install a few essential packages:
```
$ sudo apt update
$ sudo apt install build-essential ncurses-dev bc libssl-dev libc6-i386 curl libproc-processtable-perl
```

Clone b-rad-NDi git repository:
```
$ git clone https://github.com/b-rad-NDi/Embedded-MediaDrivers.git
$ cd Embedded-MediaDrivers
~/Embedded-MediaDrivers$
```

Create a `SYNO-Apollolake` download directory:
```
$ mkdir dl/SYNO-Apollolake
```

Download the toolchain
* https://sourceforge.net/projects/dsgpl/files/DSM%206.2%20Tool%20Chains/
```
$ wget --content-disposition https://sourceforge.net/projects/dsgpl/files/DSM%206.2%20Tool%20Chains/Intel%20x86%20Linux%204.4.59%20%28Apollolake%29/apollolake-gcc493_glibc220_linaro_x86_64-GPL.txz/download -P dl/SYNO-Apollolake/
```

Download the Synology DSM kernel sources:
* https://sourceforge.net/projects/dsgpl/files/Synology%20NAS%20GPL%20Source/22259branch/
```
$ wget --content-disposition https://sourceforge.net/projects/dsgpl/files/Synology%20NAS%20GPL%20Source/22259branch/apollolake-source/linux-4.4.x.txz/download -P dl/SYNO-Apollolake/
```

Initialize the repository:
```
$ ./md_builder.sh -i -d SYNO-Apollolake
```

Build a default Synology DSM kernel build (takes a while):
```
$ export MAKEOPTS="-j`nproc`"
$ ./md_builder.sh -B media -d SYNO-Apollolake
```

Configure the media tree, get the latest media tree patches that applies over the default Synology DSM kernel and build the media drivers:
```
$ ./md_builder.sh -g -d SYNO-Apollolake
$ cd build/SYNOAPOLLOLAKE/media_build
build/SYNOAPOLLOLAKE/media_build$ ./build
```

## Installation

Using SSH login as admin on the synology NAS:
```
$ ssh admin@<my.syno.nas.ip>
```

Create a new local module directory (name will match kernel version):
```
$ sudo mkdir -p /usr/local/lib/modules/$(uname -r)
$ cd /usr/local/lib/modules/$(uname -r)
```

Download the updated media drivers modules over to the NAS (the following downloads not only the mandatory modules for Hauppauge WinTV but rather all the media tree modules):
```
$ cd /usr/local/lib/modules/$(uname -r)
$ sudo scp "username@<my.ubuntu.linux.ip>:~/Embedded-MediaDrivers/build/SYNOAPOLLOLAKE/media_build/v4l/*.ko" .
```

Copy the start/stop/load/reset script to the NAS (and make it executable):
```
$ cd /usr/local/lib/modules/$(uname -r)
$ wget https://raw.githubusercontent.com/th0ma7/synology/master/hauppauge.sh
$ chmod 755 hauppauge.sh
```

Create a symbolic link to `/opt/bin/hauppauge.sh` for ease of use:
```
$ sudo ln -s -T -f /usr/local/lib/modules/$(uname -r)/hauppauge.sh /opt/bin/hauppauge.sh
```

Create a local rc file locate at `/usr/local/etc/rc.d/media.sh` that will be executed at boot time:
```
$ cat << EOF | sudo tee /usr/local/etc/rc.d/media.sh
#!/bin/sh
/usr/local/lib/modules/$(uname -r)/hauppauge.sh load
EOF
$ sudo chmod 755 /usr/local/etc/rc.d/media.sh
```

Execute manually the rc script to confirm there is no error:
```
$ sudo /usr/local/etc/rc.d/media.sh
```

Validate the status:
```
$ sudo /opt/bin/hauppauge.sh status
Status pkgctl-tvheadend...            N/A
kernel module status... 
	em28xx_dvb                    OK
	em28xx                        OK
	lgdt3306a                     OK
	si2157                        OK
	tveeprom                      OK
	v4l2_common                   OK
	dvb_usb                       OK
	rc_core                       OK
	dvb_core                      OK
	videobuf2_vmalloc             OK
	videobuf2_memops              OK
	videobuf2_v4l2                OK
	videobuf2_common              OK
	videodev                      OK
	media                         OK
kernel USB (1-3) autosuspend values...
	(1-3)autosuspend_delay_ms     [-1000] -> OK
	(1-3)autosuspend              [   -1] -> OK
kernel sysctl values... 
	vm.dirty_expire_centisecs     [  300] -> OK
	vm.swappiness                 [    1] -> OK
```

Normally should see something similar in kernel `dmesg`:
```
[  557.806644] em28xx: New device HCW 955D @ 480 Mbps (2040:026d, interface 0, class 0)
[  557.815308] em28xx: DVB interface 0 found: isoc
[  557.820423] em28xx: chip ID is em28174
[  558.939915] em28174 #0: EEPROM ID = 26 00 01 00, EEPROM hash = 0x3d790eca
[  558.947531] em28174 #0: EEPROM info:
[  558.951857] em28174 #0: 	microcode start address = 0x0004, boot configuration = 0x01
[  558.966683] em28174 #0: 	AC97 audio (5 sample rates)
[  558.972234] em28174 #0: 	500mA max power
[  558.976620] em28174 #0: 	Table at offset 0x27, strings=0x0a72, 0x187c, 0x086a
[  558.984753] em28174 #0: Identified as Hauppauge WinTV-dualHD 01595 ATSC/QAM (card=100)
[  558.994647] tveeprom 8-0050: Hauppauge model 204101, rev B2I6, serial# 11584195
[  559.002824] tveeprom 8-0050: tuner model is SiLabs Si2157 (idx 186, type 4)
[  559.010649] tveeprom 8-0050: TV standards PAL(B/G) NTSC(M) PAL(I) SECAM(L/L') PAL(D/D1/K) ATSC/DVB Digital (eeprom 0xfc)
[  559.023133] tveeprom 8-0050: audio processor is None (idx 0)
[  559.029491] tveeprom 8-0050: has no radio, has IR receiver, has no IR transmitter
[  559.038167] em28174 #0: dvb set to isoc mode.
[  559.043177] em28xx: chip ID is em28174
[  560.162726] em28174 #1: EEPROM ID = 26 00 01 00, EEPROM hash = 0x3d790eca
[  560.170323] em28174 #1: EEPROM info:
[  560.174326] em28174 #1: 	microcode start address = 0x0004, boot configuration = 0x01
[  560.189064] em28174 #1: 	AC97 audio (5 sample rates)
[  560.194613] em28174 #1: 	500mA max power
[  560.199009] em28174 #1: 	Table at offset 0x27, strings=0x0a72, 0x187c, 0x086a
[  560.207139] em28174 #1: Identified as Hauppauge WinTV-dualHD 01595 ATSC/QAM (card=100)
[  560.216915] tveeprom 10-0050: Hauppauge model 204101, rev B2I6, serial# 11584195
[  560.225192] tveeprom 10-0050: tuner model is SiLabs Si2157 (idx 186, type 4)
[  560.233070] tveeprom 10-0050: TV standards PAL(B/G) NTSC(M) PAL(I) SECAM(L/L') PAL(D/D1/K) ATSC/DVB Digital (eeprom 0xfc)
[  560.245327] tveeprom 10-0050: audio processor is None (idx 0)
[  560.251757] tveeprom 10-0050: has no radio, has IR receiver, has no IR transmitter
[  560.260220] em28xx: dvb ts2 set to isoc mode.
[  560.465298] em28174 #0: Binding DVB extension
[  560.476140] i2c i2c-8: Added multiplexed i2c bus 11
[  560.501921] lgdt3306a 8-0059: LG Electronics LGDT3306A successfully identified
[  560.509994] DEBUG: Passed lgdt3306a_probe 2360 
[  560.517015] si2157 11-0060: Silicon Labs Si2147/2148/2157/2158 successfully attached
[  560.525695] DVB: registering new adapter (em28174 #0)
[  560.531352] usb 1-3: DVB: registering adapter 0 frontend 0 (LG Electronics LGDT3306A VSB/QAM Frontend)...
[  560.544142] em28174 #0: DVB extension successfully initialized
[  560.550672] em28174 #1: Binding DVB extension
[  560.560027] i2c i2c-10: Added multiplexed i2c bus 12
[  560.585962] lgdt3306a 10-000e: LG Electronics LGDT3306A successfully identified
[  560.601410] si2157 12-0062: Silicon Labs Si2147/2148/2157/2158 successfully attached
[  560.610075] DVB: registering new adapter (em28174 #1)
[  560.615721] usb 1-3: DVB: registering adapter 1 frontend 0 (LG Electronics LGDT3306A VSB/QAM Frontend)...
[  560.627161] em28174 #1: DVB extension successfully initialized
[  562.882976] si2157 12-0062: found a 'Silicon Labs Si2157-A30'
[  562.939717] si2157 12-0062: firmware version: 3.0.5
[  562.945214] usb 1-3: DVB: adapter 1 frontend 0 frequency 0 out of range (55000000..858000000)
```

And the following USB devices with associated modules (ID may vary depending if connected using the front or back USB ports):
```
$ lsusb -Ic
|__usb1          1d6b:0002:0404 09  2.00  480MBit/s 0mA 1IF  (Linux 4.4.59+ xhci-hcd xHCI Host Controller 0000:00:15.0)
 1-0:1.0          (IF) 09:00:00 1EP  () hub 
  |__1-1         2040:026d:0100 00  2.00  480MBit/s 500mA 1IF  (HCW 955D 0011584195)
  1-1:1.0         (IF) ff:00:00 2EPs () em28xx 
  |__1-4         f400:f400:0100 00  2.00  480MBit/s 200mA 1IF  (Synology DiskStation 6500794064E41636)
  1-4:1.0         (IF) 08:06:50 2EPs () usb-storage host5 (synoboot)
|__usb2          1d6b:0003:0404 09  3.00 5000MBit/s 0mA 1IF  (Linux 4.4.59+ xhci-hcd xHCI Host Controller 0000:00:15.0)
 2-0:1.0          (IF) 09:00:00 1EP  () hub
```

Now reboot the NAS using the admin web page and confirm after reboot that the dmesg output and lsusb are still ok.

In case you run into issue where your NAS refuses to fully shutdown (and thus reboot) with the power button led blinking, it is most probably due to tainted modules still in memory.  Running `hauppauge.sh stop` prior to shutdown/reboot will remove all the tainted modules from memory thus allowing the NAS to properly shutdown/reboot.

---

# hauppauge.sh
This script is intended to provide a simple method to start|stop|restart the various perequesites into getting media modules loaded onto the Synology NAS.

Basicaly what the script does:
1. Load all the necessary modules
2. Disable USB autosuspend over the Hauppauge USB ID
3. Injects a few kernel `sysctl` for optmizations
4. Starts TVH (service name `pkgctl-tvheadend`)

## Modules
The script uses `insmod` to load|unload the modules into the appropriate order.  The `MODULES` parameter in the script can be adapted as needed for other DVB dongles than the Hauppauge WinTV 955D.

|Order | Module                 | `rmmod`             |
|:----:|:----------------------:|:-------------------:|
| 1    | `media.ko`             | `media`             |
| 2    | `videodev.ko`          | `videodev`          |
| 3    | `videobuf2-common.ko`  | `videobuf2_common`  |
| 4    | `videobuf2-v4l2.ko`    | `videobuf2_v4l2`    |
| 5    | `videobuf2-memops.ko`  | `videobuf2_memops`  |
| 6    | `videobuf2-vmalloc.ko` | `videobuf2_vmalloc` |
| 7    | `dvb-core.ko`          | `dvb_core`          |
| 8    | `rc-core.ko`           | `rc_core`           |
| 9    | `dvb-usb.ko`           | `dvb_usb`           |
| 10   | `v4l2-common.ko`       | `v4l2_common`       |
| 11   | `tveeprom.ko`          | `tveeprom`          |
| 12   | `si2157.ko`            | `si2157`            |
| 13   | `lgdt3306a.ko`         | `lgdt3306a`         |
| 14   | `em28xx.ko`            | `em28xx`            |
| 15   | `em28xx-dvb.ko`        | `em28xx_dvb`        |

## Options
**start:** Does a full start including:
1. loading all the modules
2. disabling USB autosuspend
3. `sysctl` adjustments
4. TVH startup

**stop:** Does a stop which basicaly is:
1. TVH shutdown
2. Unloading all the modules

**restart:** Basically performs a `stop` then `start`.

**reset:** This is usefull when hitting BUGS with TVH such as OOM killer where the tvheadend service is being killed by the system.  The `reset` option reduces to the minimal the impact over the already loaded modules by resetting only the DVB frontend module such as:
1. TVH shutdown (forces it if needed)
2. unload `em28xx_dvb`
3. load of `em28xx-dvb.ko`
4. TVH startup

**load:** This is the option to be used at NAS startup.  It basically does all the same things as the `start` option without the TVH startup as it's being managed by the Synology DSM stack automatically.

**status:** This provides a view on all things namely modules loaded into memory, USB autosuspend, `sysctl` adjustments and TVH service status including it's PID.
