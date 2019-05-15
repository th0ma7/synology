#!/bin/sh

SERVICE="pkgctl-tvheadend"
MODULES="em28xx_dvb em28xx lgdt3306a media si2157 tveeprom v4l2_common videodev dvb-usb rc-core dvb-core"

GetServiceStatus() {
   case $(sudo synoservice --status $SERVICE | grep "\[$SERVICE\].*start") in
      "\[$SERVICE\].*start" ) return "start";;
       "\[$SERVICE\].*stop" ) return "stop";;
	                      * ) return "unknown";;
   esac
}

#echo -ne "Stopping $SERVICE... "
printf '%-33s' "Stopping $SERVICE..."
[ "$GetServiceStatus" = "start" ] \
   && sudo synoservice --pause $SERVICE \
   && echo "OK" \
   || echo "N/A"

# Unload Hauppauge updated drivers
echo "Unloading kernel modules... "
for module in $MODULES
do
   printf '\t%-25s' $module

   status=$(lsmod | grep "^$module ")
   if [ $? -eq 0 -a "status" ]; then
      sudo rmmod $module
	  echo -ne "OK\n"
   else
	  echo -ne "N/A\n"
   fi
done
