#!/bin/sh

ROOTDIR=`pwd`
export ROOTDIR=$ROOTDIR

FAKEROOT='fakeroot'
${FAKEROOT} echo 1 2>&1 >/dev/null
if [ $? -ne 0 ]; then
    FAKEROOT='sudo'
fi
export FAKEROOT=$FAKEROOT

# Set toolchain default dir (may be redifined in ${ROOTDIR}/.config)
export CONFIG_TOOLCHAIN_DIR="${ROOTDIR}/../toolchain/out"

kernel_id="3.4.x"
kernel_cf=""
kernel_tf=""
busybox_id="1.36.1"
busybox_cf="$ROOTDIR/configs/boards/busybox.config"
busybox_tf="$ROOTDIR/user/busybox/busybox-${busybox_id}/.config"
board_h=""
board_mk=""
paragon_hfsplus=0

func_enable_kernel_param()
{
	DEFPARAM="y"
	if [ "$2"  != "" ]; then
		DEFPARAM="$2"
	fi
	if [ -n "`grep \^\"\# $1 is not set\" $kernel_tf`" ]; then
		sed -i "s/\# $1 is not set/$1=$DEFPARAM/" $kernel_tf
	elif [ -n "`grep \^$1=m $kernel_tf`" ]; then
		sed -i "s/$1=m/$1=$DEFPARAM/" $kernel_tf
	elif [ ! -n "`grep \^$1=y $kernel_tf`" ]; then
		echo "$1=$DEFPARAM" >> $kernel_tf
	fi
}

func_enable_kernel_param_as_m()
{
	if [ -n "`grep \^\"\# $1 is not set\" $kernel_tf`" ]; then
		sed -i "s/\# $1 is not set/$1=m/" $kernel_tf
	elif [ -n "`grep \^$1=y $kernel_tf`" ]; then
		sed -i "s/$1=y/$1=m/" $kernel_tf
	elif [ ! -n "`grep \^$1=m $kernel_tf`" ]; then
		echo "$1=m" >> $kernel_tf
	fi
}

func_disable_kernel_param()
{
	if [ -n "`grep \^$1=y $kernel_tf`" ]; then
		sed -i "s/$1=y/\# $1 is not set/" $kernel_tf
	elif [ -n "`grep \^$1=m $kernel_tf`" ]; then
		sed -i "s/$1=m/\# $1 is not set/" $kernel_tf
	fi
}

func_enable_busybox_param()
{
	if [ -n "`grep \^\"\# $1 is not set\" $busybox_tf`" ]; then
		sed -i "s/\# $1 is not set/$1=y/" $busybox_tf
	fi
}

func_disable_busybox_param()
{
	if [ -n "`grep \^$1=y $busybox_tf`" ]; then
		sed -i "s/$1=y/\# $1 is not set/" $busybox_tf
	fi
}

if [ ! -f "$ROOTDIR/.config" ]; then
	echo "Project config file .config not found! Terminate."
	exit 1
fi

# load project root config
. ${ROOTDIR}/.config

# remove this later
if [ ! -f "${CONFIG_TOOLCHAIN_DIR}/mipsel-linux-uclibc/sysroot/lib/libuClibc-1.0.47.so" ]; then
	echo "Toolchain and uClibc are updated! Please recompile toolchain."
	exit 1
fi

if [ ! -d "$ROOTDIR/linux-$kernel_id" ]; then
	echo "Project Linux Kernel dir (linux-$kernel_id) not found! Terminate."
	exit 1
fi

board_h="$ROOTDIR/configs/boards/$CONFIG_VENDOR/$CONFIG_FIRMWARE_PRODUCT_ID/board.h"
board_mk="$ROOTDIR/configs/boards/$CONFIG_VENDOR/$CONFIG_FIRMWARE_PRODUCT_ID/board.mk"
partitions_cf="$ROOTDIR/configs/boards/$CONFIG_VENDOR/$CONFIG_FIRMWARE_PRODUCT_ID/partitions.config"
partitions_tcf="$ROOTDIR/linux-$kernel_id/drivers/mtd/mtdsplitter_parts.h"
kernel_cd="$ROOTDIR/configs/boards/$CONFIG_VENDOR/$CONFIG_FIRMWARE_PRODUCT_ID"
kernel_tf="$ROOTDIR/linux-$kernel_id/.config"
kernel_cf="${kernel_cd}/kernel-${kernel_id}.config"

if [ ! -f "$kernel_cf" ]; then
	echo "Target kernel config ($kernel_cf) not found! Terminate."
	exit 1
fi

if [ ! -f "$busybox_cf" ]; then
	echo "Target BusyBox config ($busybox_cf) not found! Terminate."
	exit 1
fi

if [ ! -f "$board_h" ]; then
	echo "Target board header ($board_h) not found! Terminate."
	exit 1
fi

if [ ! -f "$board_mk" ]; then
	echo "Target board descriptor ($board_mk) not found! Terminate."
	exit 1
fi

rm -rf $ROOTDIR/romfs
rm -rf $ROOTDIR/images
mkdir -p $ROOTDIR/romfs
mkdir -p $ROOTDIR/images

# load source kernel config
. "$kernel_cf"

echo --------------------------COPY-CONFIG-----------------------------
######################### FOR-ALL-DEVICES #############################
cp -fL "$kernel_cf" "$kernel_tf"
cp -fL "$busybox_cf" "$busybox_tf"
cp -fL "$board_mk" "$ROOTDIR/user/shared/board.mk"
cp -fL "$board_h" "$ROOTDIR/user/shared/include/ralink_board.h"
sed "s/BOARD_PID.*$/BOARD_PID\t\t\"${CONFIG_FIRMWARE_PRODUCT_ID}\"/g" -i "$ROOTDIR/user/shared/include/ralink_board.h"
sed "s/BOARD_NAME.*$/BOARD_NAME\t\t\"${CONFIG_FIRMWARE_PRODUCT_ID}\"/g" -i "$ROOTDIR/user/shared/include/ralink_board.h"
cp -fL "$partitions_cf" "$partitions_tcf"
############################# WI-FI ###################################
dir_wifi_src="$ROOTDIR/proprietary/rt_wifi"
dir_wifi_dst="$ROOTDIR/linux-$kernel_id/drivers/net/wireless/ralink"
dir_wifi_ver="2.7.X.X"
rm -rf "$dir_wifi_dst/rt2860v2"
rm -rf "$dir_wifi_dst/rt3090"
rm -rf "$dir_wifi_dst/rt5392"
rm -rf "$dir_wifi_dst/rt5592"
rm -rf "$dir_wifi_dst/rt3593"
rm -rf "$dir_wifi_dst/mt7610"
rm -rf "$dir_wifi_dst/mt76x2"
rm -rf "$dir_wifi_dst/mt76x3"
rm -rf "$dir_wifi_dst/mt7628"
rm -rf "$dir_wifi_dst/mt7615"
if [ -n "$CONFIG_RT2860V2_AP" ]; then
	dir_wifi_ver="2.7.X.X"
	if [ "$CONFIG_RALINK_RT3883" = "y" ] && [ "$CONFIG_FIRMWARE_WIFI5_DRIVER" = "2.4" ]; then
		dir_wifi_ver="2.4.X.X"
	fi
	if [ "$CONFIG_RALINK_MT7620" = "y" ]; then
		if [ "$CONFIG_FIRMWARE_WIFI2_DRIVER" = "3.0" ] && [ -n "$CONFIG_MT76X2_AP" ]; then
			func_disable_kernel_param "CONFIG_RT_FIRST_IF_RT2860"
			func_enable_kernel_param "CONFIG_RT_FIRST_IF_MT7620"
			CONFIG_RT_FIRST_IF_RT2860=""
		else
			func_enable_kernel_param "CONFIG_RT_FIRST_IF_RT2860"
			func_disable_kernel_param "CONFIG_RT_FIRST_IF_MT7620"
			CONFIG_RT_FIRST_IF_RT2860=y
		fi
	fi
	if [ "$CONFIG_RT_FIRST_IF_RT2860" = "y" ]; then
		cp -rfL "$dir_wifi_src/rtsoc/$dir_wifi_ver/rt2860v2" "$dir_wifi_dst/"
		cp -rfL "$dir_wifi_src/rtsoc/$dir_wifi_ver/rt2860v2_ap" "$dir_wifi_dst/"
	fi
fi
if [ -n "$CONFIG_RT3090_AP" ]; then
	dir_wifi_ver="2.7.X.X"
	cp -rfL "$dir_wifi_src/rtpci/$dir_wifi_ver/rt3090" "$dir_wifi_dst/"
	cp -rfL "$dir_wifi_src/rtpci/$dir_wifi_ver/rt3090_ap" "$dir_wifi_dst/"
fi
if [ -n "$CONFIG_RT5392_AP" ]; then
	dir_wifi_ver="2.7.X.X"
	cp -rfL "$dir_wifi_src/rtpci/$dir_wifi_ver/rt5392" "$dir_wifi_dst/"
	cp -rfL "$dir_wifi_src/rtpci/$dir_wifi_ver/rt5392_ap" "$dir_wifi_dst/"
fi
if [ -n "$CONFIG_RT5592_AP" ]; then
	dir_wifi_ver="2.7.X.X"
	cp -rfL "$dir_wifi_src/rtpci/$dir_wifi_ver/rt5592" "$dir_wifi_dst/"
	cp -rfL "$dir_wifi_src/rtpci/$dir_wifi_ver/rt5592_ap" "$dir_wifi_dst/"
fi
if [ -n "$CONFIG_RT3593_AP" ]; then
	dir_wifi_ver="2.7.X.X"
	cp -rfL "$dir_wifi_src/rtpci/$dir_wifi_ver/rt3593" "$dir_wifi_dst/"
	cp -rfL "$dir_wifi_src/rtpci/$dir_wifi_ver/rt3593_ap" "$dir_wifi_dst/"
fi
if [ -n "$CONFIG_MT7610_AP" ]; then
	dir_wifi_ver="3.0.X.X"
	cp -rfL "$dir_wifi_src/rtpci/$dir_wifi_ver/mt7610" "$dir_wifi_dst/"
	cp -rfL "$dir_wifi_src/rtpci/$dir_wifi_ver/mt7610_ap" "$dir_wifi_dst/"
fi
if [ -n "$CONFIG_MT76X2_AP" ]; then
	dir_wifi_ver="3.0.X.X"
	cp -rfL "$dir_wifi_src/rtpci/$dir_wifi_ver/mt76x2" "$dir_wifi_dst/"
	cp -rfL "$dir_wifi_src/rtpci/$dir_wifi_ver/mt76x2_ap" "$dir_wifi_dst/"
fi
if [ -n "$CONFIG_MT76X3_AP" ]; then
	dir_wifi_ver="4.1.X.X"
	cp -rfL "$dir_wifi_src/rtpci/$dir_wifi_ver/mt76x3" "$dir_wifi_dst/"
	cp -rfL "$dir_wifi_src/rtpci/$dir_wifi_ver/mt76x3_ap" "$dir_wifi_dst/"
fi
if [ -n "$CONFIG_MT7628_AP" ]; then
	dir_wifi_ver="4.1.X.X"
	cp -rfL "$dir_wifi_src/rtsoc/$dir_wifi_ver/mt7628" "$dir_wifi_dst/"
	cp -rfL "$dir_wifi_src/rtsoc/$dir_wifi_ver/mt7628_ap" "$dir_wifi_dst/"
fi
if [ -n "$CONFIG_MT7615_AP" ]; then
	dir_wifi_ver="5.1.0.0"
	cp -rfL "$dir_wifi_src/rtpci/$dir_wifi_ver/mt7615" "$dir_wifi_dst/"
	cp -rfL "$dir_wifi_src/rtpci/$dir_wifi_ver/mt7615_ap" "$dir_wifi_dst/"
fi
############################ HWNAT ####################################
dir_ppe_src="$ROOTDIR/proprietary/rt_ppe"
dir_ppe_dst="$ROOTDIR/linux-$kernel_id/net/nat"
rm -rf "$dir_ppe_dst/hw_nat"
cp -rf "$dir_ppe_src/hw_nat" "$dir_ppe_dst/"
############################ EIP93 ####################################
dir_eip_src="$ROOTDIR/proprietary/rt_eip"
dir_eip_dst="$ROOTDIR/linux-$kernel_id/drivers/net"
if [ "$CONFIG_PRODUCT" = "MT7621" ]; then
	if [ -d "$dir_eip_src" ]; then
		rm -rf "$dir_eip_dst/rt_eip"
		cp -rf "$dir_eip_src" "$dir_eip_dst/"
	fi
fi
############################# CPU #####################################
if [ "$CONFIG_FIRMWARE_CPU_SLEEP" = "y" -o "$CONFIG_RALINK_SYSTICK_COUNTER" = "y" ]; then
	func_enable_kernel_param "CONFIG_RALINK_SYSTICK_COUNTER"
	func_enable_kernel_param "CONFIG_RALINK_CPUSLEEP"
	func_enable_kernel_param "CONFIG_HZ_1000"
	func_disable_kernel_param "CONFIG_HZ_250"
	func_disable_kernel_param "CONFIG_HZ_100"
	func_disable_kernel_param "CONFIG_CLKSRC_MIPS_GIC"
	func_disable_kernel_param "CONFIG_HIGH_RES_TIMERS"
fi
if [ "$CONFIG_RALINK_MT7620" = "y" ]; then
	if [ "$CONFIG_FIRMWARE_CPU_600MHZ" = "y" ]; then
		func_enable_kernel_param "CONFIG_RALINK_MT7620_PLL600"
	fi
fi
if [ "$CONFIG_RALINK_MT7621" = "y" ]; then
	if [ "$CONFIG_FIRMWARE_CPU_900MHZ" = "y" ]; then
		func_enable_kernel_param "CONFIG_RALINK_MT7621_PLL900"
	fi
fi
############################# SMP #####################################
if [ -n "$CONFIG_SMP" ]; then
	func_enable_busybox_param "CONFIG_FEATURE_TOP_SMP_CPU"
	func_enable_busybox_param "CONFIG_FEATURE_TOP_SMP_PROCESS"
fi
############################# RTC #####################################
if [ -n "$CONFIG_RTC_CLASS" ]; then
	func_enable_busybox_param "CONFIG_HWCLOCK"
fi
############################# IPV6 ####################################
if [ "$CONFIG_FIRMWARE_ENABLE_IPV6" != "y" ]; then
	func_disable_kernel_param "CONFIG_INET_TUNNEL"
	func_disable_kernel_param "CONFIG_IPV6"
	func_disable_busybox_param "CONFIG_PING6"
	func_disable_busybox_param "CONFIG_FEATURE_IPV6"
	func_disable_busybox_param "CONFIG_FEATURE_PREFER_IPV4_ADDRESS"
	func_disable_busybox_param "CONFIG_TRACEROUTE6"
	func_disable_busybox_param "CONFIG_FEATURE_UDHCP_RFC5969"
	func_disable_busybox_param "CONFIG_DHCP6C"
	func_enable_busybox_param "CONFIG_IP"
	func_enable_busybox_param "CONFIG_FEATURE_IP_ADDRESS"
	func_enable_busybox_param "CONFIG_FEATURE_IP_LINK"
	func_enable_busybox_param "CONFIG_FEATURE_IP_ROUTE"
fi
############################# USB #####################################
if [ "$CONFIG_FIRMWARE_ENABLE_USB" != "y" ] || [ -z "$CONFIG_USB_SUPPORT" ]; then
	func_disable_kernel_param "CONFIG_SWAP"
	func_disable_kernel_param "CONFIG_FAT_FS"
	func_disable_kernel_param "CONFIG_MSDOS_FS"
	func_disable_kernel_param "CONFIG_VFAT_FS"
	func_disable_kernel_param "CONFIG_UFSD_FS"
	func_disable_kernel_param "CONFIG_EXFAT_FS"
	func_disable_kernel_param "CONFIG_EXT2_FS"
	func_disable_kernel_param "CONFIG_EXT3_FS"
	func_disable_kernel_param "CONFIG_EXT4_FS"
	func_disable_kernel_param "CONFIG_JBD"
	func_disable_kernel_param "CONFIG_JBD2"
	func_disable_kernel_param "CONFIG_XFS_FS"
	func_disable_kernel_param "CONFIG_FUSE_FS"
	func_disable_kernel_param "CONFIG_FSCACHE"
	func_disable_kernel_param "CONFIG_INOTIFY_USER"
	func_disable_kernel_param "CONFIG_NFSD"
	func_disable_kernel_param "CONFIG_PARTITION_ADVANCED"
	func_disable_kernel_param "CONFIG_NLS_CODEPAGE_866"
	func_disable_kernel_param "CONFIG_NLS_ISO8859_1"
	func_disable_kernel_param "CONFIG_SCSI"
	func_disable_kernel_param "CONFIG_SCSI_MOD"
	func_disable_kernel_param "CONFIG_INPUT"
	func_disable_kernel_param "CONFIG_RC_CORE"
	func_disable_kernel_param "CONFIG_USB_SUPPORT"
	func_disable_kernel_param "CONFIG_HID_SUPPORT"
	func_disable_kernel_param "CONFIG_MEDIA_SUPPORT"
	func_disable_kernel_param "CONFIG_CRC16"
	func_disable_kernel_param "CONFIG_NETFILTER_FP_SMB"
	func_disable_kernel_param "CONFIG_RT3XXX_EHCI_OHCI"
	func_disable_busybox_param "CONFIG_FDISK"
	func_disable_busybox_param "CONFIG_FEATURE_FDISK_WRITABLE"
	func_disable_busybox_param "CONFIG_FEATURE_FDISK_ADVANCED"
	func_disable_busybox_param "CONFIG_MICROCOM"
	func_disable_busybox_param "CONFIG_EJECT"
	func_disable_busybox_param "CONFIG_FEATURE_EJECT_SCSI"
	func_disable_busybox_param "CONFIG_MKSWAP"
	func_disable_busybox_param "CONFIG_SWAPON"
	func_disable_busybox_param "CONFIG_SWAPOFF"
	func_disable_busybox_param "CONFIG_FEATURE_VOLUMEID_FAT"
	func_disable_busybox_param "CONFIG_FEATURE_VOLUMEID_EXFAT"
	func_disable_busybox_param "CONFIG_FEATURE_VOLUMEID_NTFS"
	func_disable_busybox_param "CONFIG_FEATURE_VOLUMEID_HFS"
	func_disable_busybox_param "CONFIG_FEATURE_VOLUMEID_EXT"
	func_disable_busybox_param "CONFIG_FEATURE_VOLUMEID_XFS"
	func_disable_busybox_param "CONFIG_FEATURE_VOLUMEID_LINUXSWAP"
	if [ "$CONFIG_FIRMWARE_INCLUDE_OPENVPN" != "y" ]; then
		func_disable_kernel_param "CONFIG_TUN"
	fi
	CONFIG_FIRMWARE_INCLUDE_NFSD=n
else
############################# UFSD ####################################
if [ "$CONFIG_FIRMWARE_ENABLE_UFSD" != "y" ]; then
	func_disable_kernel_param "CONFIG_UFSD_FS"
fi
if [ "$CONFIG_FIRMWARE_ENABLE_UFSD" != "y" ] || [ $paragon_hfsplus -eq 0 ]; then
	func_disable_kernel_param "CONFIG_MAC_PARTITION"
	func_disable_busybox_param "CONFIG_FEATURE_VOLUMEID_HFS"
fi
############################# HFS #####################################
if [ "$CONFIG_FIRMWARE_ENABLE_HFS" != "y" ]; then
	func_disable_kernel_param "CONFIG_MAC_PARTITION"
	func_disable_kernel_param "CONFIG_HFSPLUS_FS"
	func_disable_busybox_param "CONFIG_FEATURE_VOLUMEID_HFS"
else
	func_enable_kernel_param "CONFIG_MAC_PARTITION"
	func_enable_kernel_param_as_m "CONFIG_HFSPLUS_FS"
	func_enable_busybox_param "CONFIG_FEATURE_VOLUMEID_HFS"
fi
############################# FAT #####################################
if [ "$CONFIG_FIRMWARE_ENABLE_FAT" != "y" ]; then
	func_disable_kernel_param "CONFIG_FAT_FS"
	func_disable_kernel_param "CONFIG_MSDOS_FS"
	func_disable_kernel_param "CONFIG_VFAT_FS"
fi
############################ exFAT ####################################
if [ "$CONFIG_FIRMWARE_ENABLE_EXFAT" != "y" ]; then
	func_disable_kernel_param "CONFIG_EXFAT_FS"
	func_disable_busybox_param "CONFIG_FEATURE_VOLUMEID_EXFAT"
fi
############################# EXT2 ####################################
if [ "$CONFIG_FIRMWARE_ENABLE_EXT2" != "y" ]; then
	func_disable_kernel_param "CONFIG_EXT2_FS"
fi
############################# EXT3 ####################################
if [ "$CONFIG_FIRMWARE_ENABLE_EXT3" != "y" ]; then
	func_disable_kernel_param "CONFIG_EXT3_FS"
fi
############################# EXT4 ####################################
if [ "$CONFIG_FIRMWARE_ENABLE_EXT4" != "y" ]; then
	func_disable_kernel_param "CONFIG_EXT4_FS"
fi
############################# XFS #####################################
if [ "$CONFIG_FIRMWARE_ENABLE_XFS" != "y" ]; then
	func_disable_kernel_param "CONFIG_XFS_FS"
	func_disable_busybox_param "CONFIG_FEATURE_VOLUMEID_XFS"
fi
############################# FUSE ####################################
if [ "$CONFIG_FIRMWARE_ENABLE_FUSE" != "y" ]; then
	func_disable_kernel_param "CONFIG_FUSE_FS"
fi
############################# SWAP ####################################
if [ "$CONFIG_FIRMWARE_ENABLE_SWAP" != "y" ]; then
	func_disable_kernel_param "CONFIG_SWAP"
	func_disable_busybox_param "CONFIG_MKSWAP"
	func_disable_busybox_param "CONFIG_SWAPON"
	func_disable_busybox_param "CONFIG_SWAPOFF"
fi
############################# NFSD ####################################
if [ "$CONFIG_FIRMWARE_INCLUDE_NFSD" != "y" ]; then
	func_disable_kernel_param "CONFIG_NFSD"
fi
############################# UVC #####################################
if [ "$CONFIG_FIRMWARE_INCLUDE_UVC" != "y" ]&&[ "$CONFIG_FIRMWARE_ENABLE_BACKPORTED" != "y" ]&&[ "$CONFIG_FIRMWARE_INCLUDE_BACKPORTED" != "y" ]; then
	func_disable_kernel_param "CONFIG_MEDIA_SUPPORT"
fi
if [ "$CONFIG_FIRMWARE_ENABLE_BACKPORTED" = "y" ]||[ "$CONFIG_FIRMWARE_INCLUDE_BACKPORTED" = "y" ]; then
	func_disable_kernel_param "CONFIG_VIDEO_DEV"
fi
############################# HID #####################################
if [ "$CONFIG_FIRMWARE_INCLUDE_HID" != "y" ]&&[ "$CONFIG_FIRMWARE_ENABLE_BACKPORTED" != "y" ]&&[ "$CONFIG_FIRMWARE_INCLUDE_BACKPORTED" != "y" ]; then
	func_disable_kernel_param "CONFIG_INPUT"
fi
if [ "$CONFIG_FIRMWARE_INCLUDE_HID" != "y" ]; then
	func_disable_kernel_param "CONFIG_HID_SUPPORT"
	func_disable_kernel_param "CONFIG_USB_HID"
fi
if [ "$CONFIG_FIRMWARE_ENABLE_BACKPORTED" != "y" ]&&[ "$CONFIG_FIRMWARE_INCLUDE_BACKPORTED" != "y" ]; then
	func_disable_kernel_param "CONFIG_RC_CORE"
fi
############################# UART ####################################
if [ "$CONFIG_FIRMWARE_INCLUDE_SERIAL" != "y" ]; then
	func_disable_kernel_param "CONFIG_USB_SERIAL_CH341"
	func_disable_kernel_param "CONFIG_USB_SERIAL_PL2303"
fi
fi
############################# XFRM ####################################
if [ "$CONFIG_FIRMWARE_INCLUDE_SSWAN" = "y" ]; then
	CONFIG_FIRMWARE_INCLUDE_XFRM=y
fi
#if [ "$CONFIG_PRODUCT" = "MT7621" ]; then
if [ "$CONFIG_FIRMWARE_INCLUDE_XFRM" != "y" ]; then
	func_disable_kernel_param "CONFIG_XFRM"
	func_disable_kernel_param "CONFIG_XFRM_USER"
	func_disable_kernel_param "CONFIG_XFRM_IPCOMP"
	func_disable_kernel_param "CONFIG_NET_KEY"
	func_disable_kernel_param "CONFIG_INET_AH"
	func_disable_kernel_param "CONFIG_INET_ESP"
	func_disable_kernel_param "CONFIG_INET_IPCOMP"
	func_disable_kernel_param "CONFIG_INET_XFRM_TUNNEL"
	func_disable_kernel_param "CONFIG_INET_XFRM_MODE_TRANSPORT"
	func_disable_kernel_param "CONFIG_INET_XFRM_MODE_TUNNEL"
	func_disable_kernel_param "CONFIG_INET_XFRM_MODE_BEET"
	func_disable_kernel_param "CONFIG_INET6_AH"
	func_disable_kernel_param "CONFIG_INET6_ESP"
	func_disable_kernel_param "CONFIG_INET6_IPCOMP"
	func_disable_kernel_param "CONFIG_INET6_XFRM_TUNNEL"
	func_disable_kernel_param "CONFIG_INET6_XFRM_MODE_TRANSPORT"
	func_disable_kernel_param "CONFIG_INET6_XFRM_MODE_TUNNEL"
	func_disable_kernel_param "CONFIG_INET6_XFRM_MODE_BEET"
	func_disable_kernel_param "CONFIG_NETFILTER_XT_MATCH_ESP"
	func_disable_kernel_param "CONFIG_NETFILTER_XT_MATCH_POLICY"
	func_disable_kernel_param "CONFIG_IP_NF_MATCH_AH"
	func_disable_kernel_param "CONFIG_IP6_NF_MATCH_AH"
	func_disable_kernel_param "CONFIG_IPV6_MULTIPLE_TABLES"
	func_disable_kernel_param "CONFIG_CRYPTO_AEAD"
	func_disable_kernel_param "CONFIG_CRYPTO_AEAD2"
	func_disable_kernel_param "CONFIG_CRYPTO_AUTHENC"
	func_disable_kernel_param "CONFIG_CRYPTO_CBC"
	func_disable_kernel_param "CONFIG_CRYPTO_HMAC"
	func_disable_kernel_param "CONFIG_CRYPTO_MD5"
	func_disable_kernel_param "CONFIG_CRYPTO_SHA256"
	func_disable_kernel_param "CONFIG_CRYPTO_AES"
	func_disable_kernel_param "CONFIG_CRYPTO_DES"
	func_disable_kernel_param "CONFIG_CRYPTO_DEFLATE"
fi
#fi
############################ IPSET ####################################
if [ "$CONFIG_FIRMWARE_INCLUDE_IPSET" != "y" ]; then
	func_disable_kernel_param "CONFIG_NETFILTER_NETLINK"
fi
############################# QOS #####################################
if [ "$CONFIG_FIRMWARE_INCLUDE_QOS" != "y" ]; then
	func_disable_kernel_param "CONFIG_NET_SCHED"
	func_disable_kernel_param "CONFIG_NET_CLS"
	func_disable_kernel_param "CONFIG_NETFILTER_XT_TARGET_CLASSIFY"
	func_disable_kernel_param "CONFIG_NETFILTER_XT_TARGET_IMQ"
	func_disable_kernel_param "CONFIG_IMQ"
fi
############################# IMQ #####################################
if [ "$CONFIG_FIRMWARE_INCLUDE_IMQ" != "y" ]; then
	func_disable_kernel_param "CONFIG_NETFILTER_XT_TARGET_IMQ"
	func_disable_kernel_param "CONFIG_IMQ"
fi
############################# IFB #####################################
if [ "$CONFIG_FIRMWARE_INCLUDE_IFB" != "y" ]; then
	func_disable_kernel_param "CONFIG_NET_SCH_INGRESS"
	func_disable_kernel_param "CONFIG_NET_CLS_ACT"
	func_disable_kernel_param "CONFIG_IFB"
fi
############################# NFSC ####################################
if [ "$CONFIG_FIRMWARE_INCLUDE_NFSC" != "y" ]; then
	func_disable_kernel_param "CONFIG_FSCACHE"
	func_disable_kernel_param "CONFIG_NFS_FS"
fi
############################# CIFS ####################################
if [ "$CONFIG_FIRMWARE_INCLUDE_CIFS" != "y" ]; then
	func_disable_kernel_param "CONFIG_CIFS"
	func_disable_busybox_param "CONFIG_FEATURE_MOUNT_CIFS"
fi
if [ "$CONFIG_FIRMWARE_INCLUDE_SMBD" != "y" ]; then
	func_disable_kernel_param "CONFIG_NETFILTER_FP_SMB"
fi
if [ "$CONFIG_FIRMWARE_INCLUDE_NFSD" != "y" -a "$CONFIG_FIRMWARE_INCLUDE_NFSC" != "y" -a "$CONFIG_FIRMWARE_INCLUDE_CIFS" != "y" ]; then
	func_disable_kernel_param "CONFIG_NETWORK_FILESYSTEMS"
	if [ "$CONFIG_FIRMWARE_ENABLE_USB" != "y" ] || [ -z "$CONFIG_USB_SUPPORT" ]; then
		func_disable_kernel_param "CONFIG_NLS"
		func_disable_kernel_param "CONFIG_LBDAF"
	fi
fi
############################# USB AUDIO ###############################
if [ "$CONFIG_FIRMWARE_INCLUDE_AUDIO" != "y" ] || [ "$CONFIG_FIRMWARE_ENABLE_USB" != "y" ] || [ -z "$CONFIG_USB_SUPPORT" ]; then
	func_disable_kernel_param "CONFIG_FW_LOADER"
	func_disable_kernel_param "CONFIG_SOUND"
fi
############################# ZRAM SUPPORT ############################
if [ "$CONFIG_FIRMWARE_INCLUDE_ZRAM" = "y" ]; then
	func_enable_kernel_param "CONFIG_SWAP"
	func_enable_kernel_param "CONFIG_ZSMALLOC"
	func_enable_kernel_param "CONFIG_MAX_SWAPFILES_SHIFT" "2"
	func_enable_kernel_param "CONFIG_ZRAM_LZ4_COMPRESS"
	func_enable_kernel_param_as_m "CONFIG_ZRAM"
	func_enable_kernel_param_as_m "CONFIG_LZO_COMPRESS"
	func_enable_kernel_param_as_m "CONFIG_LZO_DECOMPRESS"
	func_enable_kernel_param_as_m "CONFIG_LZ4_COMPRESS"
	func_enable_kernel_param_as_m "CONFIG_LZ4_DECOMPRESS"
	func_enable_busybox_param "CONFIG_MKSWAP"
	func_enable_busybox_param "CONFIG_SWAPON"
	func_enable_busybox_param "CONFIG_SWAPOFF"
	func_enable_busybox_param "CONFIG_FEATURE_SWAPON_DISCARD"
	func_enable_busybox_param "CONFIG_FEATURE_VOLUMEID_LINUXSWAP"
	func_enable_busybox_param "CONFIG_FEATURE_SWAPONOFF_LABEL"
	func_enable_busybox_param "CONFIG_FEATURE_SWAPON_PRI"
fi
############################## EOIP SUPPORT ###########################
if [ "$CONFIG_FIRMWARE_INCLUDE_EOIP" = "y" ]; then
	func_enable_kernel_param "CONFIG_NET_EOIP"
fi

if [ "$CONFIG_FIRMWARE_INCLUDE_WIREGUARD" = "y" ]; then
	func_enable_kernel_param_as_m "CONFIG_WIREGUARD"
	func_enable_kernel_param "CONFIG_WIREGUARD_DEBUG"
fi

if [ "$CONFIG_FIRMWARE_INCLUDE_SHORTCUT_FE" = "y" ]; then
	func_enable_kernel_param "CONFIG_SHORTCUT_FE"
	func_enable_kernel_param "CONFIG_NF_CONNTRACK_EVENTS"
	func_enable_kernel_param "CONFIG_NF_CONNTRACK_CHAIN_EVENTS"
fi

#######################################################################
echo --------------------------MAKE-DEP--------------------------------
make dep
echo --------------------------MAKE-ALL--------------------------------
make
