# synology
Synology personnal hack, info, tools &amp; source code

DS918+ with Synology 6.2.2:
* CPU: Appollo Lake

Currently only contains patches & modules to get hauppauge WinTV functional.

Working:
- em28xx: 1st tuner detected & loading firmware ok
Not working:
- lgdt3306a: crash probably due to i2c mux calls used for 2nd tuner not yet ported to em28xx.
Testing:
- 2nd tuner

Boot info available in dmesg file: dmesg.20190504-01
