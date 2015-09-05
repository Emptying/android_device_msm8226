#!/system/bin/sh

# No path is set up at this point so we have to do it here.
PATH=/sbin:/system/sbin:/system/bin:/system/xbin
export PATH

mount_needed=false;
if [ ! -f /system/etc/boot_fixup ];then
# This should be the first command
# remount system as read-write.
  mount -o rw,remount,barrier=1 /system
  mount_needed=true;
fi
# change tinymix for factory build
factory_build=`getprop ro.asus.factory`
if [ $factory_build -eq 1 ];then
	chmod 6755 /system/bin/tinymix
fi

# Run audio adsp script
if [ -f /system/etc/init.asus.adsp.sh ]; then
  /system/bin/sh /system/etc/init.asus.adsp.sh
fi

if $mount_needed ;then
# This should be the last command
# remount system as read-only.
  mount -o ro,remount,barrier=1 /system
fi
