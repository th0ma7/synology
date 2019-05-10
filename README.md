# synology - th0ma7
Synology personnal hack, info, tools &amp; source code

Donnations welcomed at: `0x522d164549E68681dfaC850A2cabdb95686C1fEC`

# Hauppauge WinTV DualHD HWC 955D
The following allows building kernel modules for the Hauppauge WinTV DualHD HWC 955D media adapter.
* https://www.linuxtv.org/wiki/index.php/Hauppauge_WinTV-HVR-955Q

It was tested on the following hardware:
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
Available patches makes both tuner detected by the kernel using the em28xx.ko updated driver.  Although the lgdt3306 demodulator driver providing the dvb-frontend devices currently fails to execute properly.

Working:
- em28xx: both tuners detected & firmware loading OK

Not working:
- lgdt3306a: crash

Kernel messages:
```
[  111.303360] em28xx: module verification failed: signature and/or required key missing - tainting kernel
[  111.329661] em28xx: New device HCW 955D @ 480 Mbps (2040:026d, interface 0, class 0)
[  111.349662] em28xx: DVB interface 0 found: isoc
[  111.363480] em28xx: chip ID is em28174
[  111.442270] init: pkg-WebStation-userdir main process (16673) terminated with status 1
[  111.813617] init: synoscheduler-vmtouch main process (16731) killed by TERM signal
[  112.111405] init: synoscheduler-vmtouch main process (17190) killed by TERM signal
[  112.491132] em28174 #0: EEPROM ID = 26 00 01 00, EEPROM hash = 0x3d790eca
[  112.498773] em28174 #0: EEPROM info:
[  112.502803] em28174 #0: 	microcode start address = 0x0004, boot configuration = 0x01
[  112.546960] em28174 #0: 	AC97 audio (5 sample rates)
[  112.552533] em28174 #0: 	500mA max power
[  112.567381] em28174 #0: 	Table at offset 0x27, strings=0x0a72, 0x187c, 0x086a
[  112.585131] em28174 #0: Identified as Hauppauge WinTV-dualHD 01595 ATSC/QAM (card=100)
[  112.642097] tveeprom 8-0050: Hauppauge model 204101, rev B2I6, serial# 11584195
[  112.653265] tveeprom 8-0050: tuner model is SiLabs Si2157 (idx 186, type 4)
[  112.678918] tveeprom 8-0050: TV standards PAL(B/G) NTSC(M) PAL(I) SECAM(L/L') PAL(D/D1/K) ATSC/DVB Digital (eeprom 0xfc)
[  112.704929] tveeprom 8-0050: audio processor is None (idx 0)
[  112.711337] tveeprom 8-0050: has no radio, has IR receiver, has no IR transmitter
[  112.740915] em28174 #0: dvb set to isoc mode.

[  114.300952] usbcore: registered new interface driver em28xx
[  114.464030] usb 1-3: ep 0x81 - rounding interval to 512 microframes, ep desc says 800 microframes
[  114.487954] em28174 #0: Binding DVB extension
[  114.494299] em28174 #1: Binding DVB extension
[  114.500420] em28xx: Registered (Em28xx dvb Extension) extension
```
Work is based on the backporting of the following upstream kernel patches:

Demodulator (lgdt3306a):
* https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/commit/?id=4f75189024f4186a7ff9d56f4a8cb690774412ec

Adaptor (em28xx):
* https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/commit/?id=11a2a949d05e9d2d9823f0c45fa476743d9e462b
* https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/commit/?id=1586342e428d80e53f9a926b2e238d2175b9f5b5
* https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/commit/?id=be7fd3c3a8c5e9acbc69f887ca961df5e68cf6f0

## Preparation
Using a Ubuntu 18.04 OS VM in order to build the updated modules.

Install a few essential packages:
```
$ sudo apt update
$ sudo apt install build-essential ncurses-dev bc libssl-dev libc6-i386 curl
```

