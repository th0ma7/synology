#!/bin/sh

#-------------------------------------------
# hauppauge.sh
#
# by: Vincent Fortier
# email: th0ma7_AT_gmail.com
#
# Simplify the status, start, stop, reset
# of tvheadend service along with loading
# and unloading of all necessary modules
#-------------------------------------------

SERVICE="pkgctl-tvheadend"
MODULE_PATH=/usr/local/lib/modules/$(uname -r)
MODULES="em28xx_dvb em28xx lgdt3306a si2157 tveeprom v4l2_common dvb_usb rc_core dvb_core videobuf2_vmalloc videobuf2_memops videobuf2_v4l2 videobuf2_common videodev media"
RESET=em28xx_dvb
#
declare -a SYSCTL_VAR=('vm.dirty_expire_centisecs' 'vm.swappiness')
declare -a SYSCTL_VALUE=('300' '1')
#
NOAUTOSUSPEND=em28xx
declare -a AUTOSUSPEND_VAR=('autosuspend_delay_ms' 'autosuspend')
declare -a AUTOSUSPEND_VALUE=('-1000' '-1')

USBAutoSuspend() {
   usbID=$(lsusb -i | grep $NOAUTOSUSPEND | awk '{print $1}' | cut -f1 -d:)
   if [ ! "$usbID" ]; then
      echo "kernel USB (none) autosuspend values  N/A"
   else
      echo "kernel USB ($usbID) autosuspend values..."
      for index in "${!AUTOSUSPEND_VAR[@]}"
      do
         declare sys=/sys/bus/usb/devices/$usbID/power/${AUTOSUSPEND_VAR[$index]}
         declare -i current=$(cat $sys)
         declare -i new=${AUTOSUSPEND_VALUE[$index]}

 	     printf '\t(%s)%-25s' $usbID ${AUTOSUSPEND_VAR[$index]}

         if [ $current -eq $new ]; then
            printf '[%5s] -> OK\n' "$current"
         else
	        [ "$1" = "check" ] || echo ${AUTOSUSPEND_VALUE[$index]} | sudo tee $sys 1>/dev/null
            printf '[%5s] -> [%5s]\n' "$current" "$new"
         fi
     done
   fi
}

Sysctl() {
   echo "kernel sysctl values... "
   for index in "${!SYSCTL_VAR[@]}"
   do
      declare -i current=$(sysctl -n ${SYSCTL_VAR[$index]})
      declare -i new=${SYSCTL_VALUE[$index]}

      printf '\t%-30s' ${SYSCTL_VAR[$index]}
      if [ $current -eq $new ]; then
         printf '[%5s] -> OK\n' "$current"
      else
	     [ "$1" = "check" ] || sysctl -w ${SYSCTL_VAR[$index]}=$new 2>/dev/null 1>&2
         printf '[%5s] -> [%5s]\n' "$current" "$new"
      fi
   done
}

ModuleLOAD() {
   echo "Loading kernel modules... "
   for item in $MODULES; do echo $item; done | tac | while read module
   do
	  module_load=$(echo "${module}.ko" | sed 's/_/-/g')
      printf '\t%-30s' $module_load
	  status=$(lsmod | grep "^$module ")

	  if [ $? -eq 0 -a "status" ]; then
		 echo "Loaded"
      else
         insmod $MODULE_PATH/$module_load
	     [ $? -eq 0 ] && echo "OK" || echo "ERROR"
      fi
   done
}

ModuleUNLOAD() {
   # Unload Hauppauge updated drivers
   echo "Unloading kernel modules... "
   for module in $MODULES
   do
      printf '\t%-30s' $module

      status=$(lsmod | grep "^$module ")
      if [ $? -eq 0 -a "status" ]; then
         rmmod $module
	     echo -ne "OK\n"
      else
	     echo -ne "N/A\n"
      fi
   done
}

ModuleSTATUS() {
   # Unload Hauppauge updated drivers
   echo "kernel module status... "
   for module in $MODULES
   do
      printf '\t%-30s' $module

      status=$(lsmod | grep "^$module ")
      if [ $? -eq 0 -a "status" ]; then
	     echo -ne "OK\n"
      else
	     echo -ne "N/A\n"
      fi
   done
}

ModuleRESET() {
   reset=$1
   module=$(echo "${reset}.ko" | sed 's/_/-/g')
   rmmod $reset
   sleep 1
   insmod $MODULE_PATH/$module
}

ServiceSTATUS() {
   status=$(synoservice --status $SERVICE | grep "\[$SERVICE\] status" | awk -F"status=" '{print $2}' | sed -e 's/\[//g' -e 's/\]//g')
   running=$(synoservice --status $SERVICE | grep "\[$SERVICE\] is" | awk -F"is " '{print $2}' | sed -e 's/\.//g' -e 's/ //g')
   pid=$(pidof tvheadend)
   [ ! "$pid" ] && pid="---"

   case "$1" in
      "full" ) printf '%-38s' "Status $SERVICE..."
			   echo $status,$running,$pid;;
           * ) echo $running;;
   esac
}

ServiceSTART() {
   status=$(ServiceSTATUS)
   #echo $status 1>&2
   printf '%-38s' "Starting $SERVICE..."

   module=$(lsmod | grep "^$RESET ")
   if [ $? -ne 0 -a ! "module" ]; then
      echo "ERROR module $RESET not found!"
	  return
   fi

   if [ "$status" = "stop" ]; then
      synoservice --start $SERVICE
   echo "OK"
   elif [ "$status" = "start" ]; then
      # Check if sevice isn't already started!
      if [ "$(pidof tvheadend)" ]; then
         echo "Started"
      else
         synoservice --restart $SERVICE 2>/dev/null 1>&2
         echo "Restart"
      fi
   else
      echo "N/A"
   fi
}

ServiceSTOP() {
   status=$(ServiceSTATUS)
   #echo $status 1>&2
   printf '%-38s' "Stopping $SERVICE..."
   if [ "$status" = "start" ]; then
      #synoservice --disable $SERVICE
      synoservice --stop $SERVICE 2>/dev/null 1>&2
      echo "OK"
   else
      echo "N/A"
   fi

   # Is it really off?
   if [ "`pidof tvheadend`" ]; then
      printf '%-33s' "Killing $SERVICE..."
      kill -9 $(pidof tvheadend)
      echo "killed"
   fi
}

Usage() {
      echo "$0 - Usage: start, stop, status, reset, restart, load"
}

case $1 in
   start ) ModuleLOAD
           USBAutoSuspend
           Sysctl
           ServiceSTART
		   ;;
    stop ) ServiceSTOP
	       ModuleUNLOAD
		   ;;
  status ) ServiceSTATUS full
	       ModuleSTATUS
           USBAutoSuspend check
           Sysctl check
		   ;;
 restart ) ServiceSTOP
           ModuleUNLOAD
		   sleep 1
		   ModuleLOAD
           USBAutoSuspend
           Sysctl
		   ServiceSTART
		   ;;
   reset ) ServiceSTOP
           ModuleRESET $RESET
           ServiceSTART
		   ServiceSTATUS full
		   ModuleSTATUS
		   ;;
    load ) ModuleLOAD
		   USBAutoSuspend
	       Sysctl
	       ;;
       * ) Usage
	       ;;
esac

exit 0
