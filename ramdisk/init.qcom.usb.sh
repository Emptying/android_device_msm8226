#!/system/bin/sh
# Copyright (c) 2012, The Linux Foundation. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above
#       copyright notice, this list of conditions and the following
#       disclaimer in the documentation and/or other materials provided
#       with the distribution.
#     * Neither the name of The Linux Foundation nor the names of its
#       contributors may be used to endorse or promote products derived
#      from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED "AS IS" AND ANY EXPRESS OR IMPLIED
# WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT
# ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS
# BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
# BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
# OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
# IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
#
# Update USB serial number from persist storage if present, if not update
# with value passed from kernel command line, if none of these values are
# set then use the default value. This order is needed as for devices which
# do not have unique serial number.
# User needs to set unique usb serial number to persist.usb.serialno
#
serialno=`getprop persist.usb.serialno`
case "$serialno" in
    "")
    serialnum=`getprop ro.serialno`
    case "$serialnum" in
        "");; #Do nothing, use default serial number
        *)
        echo "$serialnum" > /sys/class/android_usb/android0/iSerial
    esac
    ;;
    *)
    echo "$serialno" > /sys/class/android_usb/android0/iSerial
esac

chown -h root.system /sys/devices/platform/msm_hsusb/gadget/wakeup
chmod -h 220 /sys/devices/platform/msm_hsusb/gadget/wakeup

#
# Allow persistent usb charging disabling
# User needs to set usb charging disabled in persist.usb.chgdisabled
#
target=`getprop ro.board.platform`
usbchgdisabled=`getprop persist.usb.chgdisabled`
case "$usbchgdisabled" in
    "") ;; #Do nothing here
    * )
    case $target in
        "msm8660")
        echo "$usbchgdisabled" > /sys/module/pmic8058_charger/parameters/disabled
        echo "$usbchgdisabled" > /sys/module/smb137b/parameters/disabled
	;;
        "msm8960")
        echo "$usbchgdisabled" > /sys/module/pm8921_charger/parameters/disabled
	;;
    esac
esac

usbcurrentlimit=`getprop persist.usb.currentlimit`
case "$usbcurrentlimit" in
    "") ;; #Do nothing here
    * )
    case $target in
        "msm8960")
        echo "$usbcurrentlimit" > /sys/module/pm8921_charger/parameters/usb_max_current
	;;
    esac
esac
#
# Allow USB enumeration with default PID/VID
#
baseband=`getprop ro.baseband`
echo 1  > /sys/class/android_usb/f_mass_storage/lun/nofua
#usb_config=`getprop persist.sys.usb.config`
#case "$usb_config" in
#    "" | "adb") #USB persist config not set, select default configuration
#      case "$baseband" in
#          "mdm")
#               setprop persist.sys.usb.config diag,diag_mdm,serial_hsic,serial_tty,rmnet_hsic,mass_storage,adb
#          ;;
#          "sglte")
#               setprop persist.sys.usb.config diag,diag_qsc,serial_smd,serial_tty,serial_hsuart,rmnet_hsuart,mass_storage,adb
#          ;;
#          "dsda" | "sglte2")
#               setprop persist.sys.usb.config diag,diag_mdm,diag_qsc,serial_hsic,serial_hsuart,rmnet_hsic,rmnet_hsuart,mass_storage,adb
#          ;;
#          "dsda2")
#               setprop persist.sys.usb.config diag,diag_mdm,diag_mdm2,serial_hsic,serial_hsusb,rmnet_hsic,rmnet_hsusb,mass_storage,adb
#          ;;
#          *)
#               setprop persist.sys.usb.config diag,serial_smd,serial_tty,rmnet_bam,mass_storage,adb
#          ;;
#      esac
#    ;;
#    * ) ;; #USB persist config exists, do nothing
#esac

#
# Do target specific things
#
case "$target" in
    "msm8974")
# Select USB BAM - 2.0 or 3.0
        echo ssusb > /sys/bus/platform/devices/usb_bam/enable
    ;;
    "apq8084")
	if [ "$baseband" == "apq" ]; then
		echo "msm_hsic_host" > /sys/bus/platform/drivers/xhci_msm_hsic/unbind
	fi
    ;;
    "msm8226")
         if [ -e /sys/bus/platform/drivers/msm_hsic_host ]; then
             if [ ! -L /sys/bus/usb/devices/1-1 ]; then
                 echo msm_hsic_host > /sys/bus/platform/drivers/msm_hsic_host/unbind
             fi
         fi
    ;;
esac

#
# set module params for embedded rmnet devices
#
rmnetmux=`getprop persist.rmnet.mux`
case "$baseband" in
    "mdm" | "dsda" | "sglte2")
        case "$rmnetmux" in
            "enabled")
                    echo 1 > /sys/module/rmnet_usb/parameters/mux_enabled
                    echo 8 > /sys/module/rmnet_usb/parameters/no_fwd_rmnet_links
                    echo 17 > /sys/module/rmnet_usb/parameters/no_rmnet_insts_per_dev
            ;;
        esac
        echo 1 > /sys/module/rmnet_usb/parameters/rmnet_data_init
        # Allow QMUX daemon to assign port open wait time
        chown -h radio.radio /sys/devices/virtual/hsicctl/hsicctl0/modem_wait
    ;;
    "dsda2")
          echo 2 > /sys/module/rmnet_usb/parameters/no_rmnet_devs
          echo hsicctl,hsusbctl > /sys/module/rmnet_usb/parameters/rmnet_dev_names
          case "$rmnetmux" in
               "enabled") #mux is neabled on both mdms
                      echo 3 > /sys/module/rmnet_usb/parameters/mux_enabled
                      echo 8 > /sys/module/rmnet_usb/parameters/no_fwd_rmnet_links
                      echo 17 > write /sys/module/rmnet_usb/parameters/no_rmnet_insts_per_dev
               ;;
               "enabled_hsic") #mux is enabled on hsic mdm
                      echo 1 > /sys/module/rmnet_usb/parameters/mux_enabled
                      echo 8 > /sys/module/rmnet_usb/parameters/no_fwd_rmnet_links
                      echo 17 > /sys/module/rmnet_usb/parameters/no_rmnet_insts_per_dev
               ;;
               "enabled_hsusb") #mux is enabled on hsusb mdm
                      echo 2 > /sys/module/rmnet_usb/parameters/mux_enabled
                      echo 8 > /sys/module/rmnet_usb/parameters/no_fwd_rmnet_links
                      echo 17 > /sys/module/rmnet_usb/parameters/no_rmnet_insts_per_dev
               ;;
          esac
          echo 1 > /sys/module/rmnet_usb/parameters/rmnet_data_init
          # Allow QMUX daemon to assign port open wait time
          chown -h radio.radio /sys/devices/virtual/hsicctl/hsicctl0/modem_wait
    ;;
esac

ls_ssn=`ls /data/asusdata/SSN`
case "$ls_ssn" in
	*SSN*)
		ssn_value=`cat /data/asusdata/SSN`
		echo "$ssn_value" > /sys/class/android_usb/android0/iSerial
	;;
	* )
		echo "C4ATAS000000" > /sys/class/android_usb/android0/iSerial
	;;
esac

cdromname=`getprop ro.service.cdrom.path`
per_sysusbconfig=`getprop persist.sys.usb.config`
CMDLINE=`cat /proc/cmdline`
if [ -f $cdromname ]; then
    setprop persist.service.cdrom.enable 1
    echo "mounting usbcdrom lun"
    echo $cdromname > /sys/class/android_usb/android0/f_mass_storage/lun0/file
    case "$per_sysusbconfig" in
	"mtp,adb")
		setprop persist.sys.usb.config mtp,adb,mass_storage
	;;
	"mtp")
		setprop persist.sys.usb.config mtp,mass_storage
	;;
    esac
else
    setprop persist.service.cdrom.enable 0
    echo "" > /sys/class/android_usb/android0/f_mass_storage/lun0/file
    case "$per_sysusbconfig" in
	"mtp,adb,mass_storage")
		setprop persist.sys.usb.config mtp,adb
	;;
	"mtp,mass_storage")
		setprop persist.sys.usb.config mtp
	;;
    esac
fi

CMDLINE=`cat /proc/cmdline`
case "$CMDLINE" in
	*ADB=Y*)
		setprop sys.usb.adbon 1
	;;
esac
