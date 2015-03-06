#
# Product-specific compile-time definitions.
#

include device/fsl/imx6/soc/imx6dq.mk
include device/gateworks/ventana/build_id.mk
include device/fsl/imx6/BoardConfigCommon.mk
# 380MB system image (prune to size needed for system apps)
BOARD_SYSTEMIMAGE_PARTITION_SIZE := 380M
# 100MB data image (prune to size needed for pre-installed/custom data/apps)
BOARD_USERDATAIMAGE_PARTITION_SIZE := 100M

BOARD_SOC_CLASS := IMX6
BOARD_SOC_TYPE := IMX6DQ
PRODUCT_MODEL := Gateworks Ventana

#
# Kernel
#
ifneq ($(DEFCONF),)
TARGET_KERNEL_DEFCONF := $(DEFCONF)
else
TARGET_KERNEL_DEFCONF := gwventana_android_defconfig
endif
TARGET_BOARD_DTS_CONFIG := \
  imx6q:imx6q-gw54xx.dtb \
  imx6q:imx6q-gw53xx.dtb \
  imx6q:imx6q-gw52xx.dtb \
  imx6q:imx6q-gw51xx.dtb \
  imx6q:imx6q-gw552x.dtb \
  imx6q:imx6q-gw551x.dtb \
  imx6dl:imx6dl-gw54xx.dtb \
  imx6dl:imx6dl-gw53xx.dtb \
  imx6dl:imx6dl-gw52xx.dtb \
  imx6dl:imx6dl-gw51xx.dtb \
  imx6dl:imx6dl-gw552x.dtb \
  imx6dl:imx6dl-gw551x.dtb

# these are modules because they require firmware. If these modules are
# needed for your application uncomment and be sure they are insmoded
# (in the proper order with dependencies) in init.rc on fs
#TARGET_KERNEL_MODULES := \
#  kernel_imx/drivers/bluetooth/ath3k.ko:system/lib/modules/ \
#  kernel_imx/drivers/net/wireless/rtlwifi/rtl8723as/8723as.ko:system/lib/modules/ \
#  kernel_imx/drivers/net/wireless/rtlwifi/rtlwifi.ko:system/lib/modules/ \
#  kernel_imx/drivers/net/wireless/ath/ath6kl/ath6kl_core.ko:system/lib/modules/ \
#  kernel_imx/drivers/net/wireless/ath/ath6kl/ath6kl_usb.ko:system/lib/modules/ \
#  kernel_imx/drivers/net/wireless/ath/ar5523/ar5523.ko:system/lib/modules/ \
#  kernel_imx/drivers/net/wireless/ath/carl9170/carl9170.ko:system/lib/modules/ \
#  kernel_imx/drivers/net/wireless/rt2x00/rt2800usb.ko:system/lib/modules/ \
#  kernel_imx/drivers/net/wireless/rt2x00/rt2800lib.ko:system/lib/modules/ \
#  kernel_imx/drivers/net/wireless/rt2x00/rt2x00usb.ko:system/lib/modules/ \
#  kernel_imx/drivers/net/wireless/rt2x00/rt2x00lib.ko:system/lib/modules/

BOARD_SEPOLICY_DIRS := \
  device/fsl/ventana/sepolicy

BOARD_SEPOLICY_UNION := \
  app.te \
  file_contexts \
  fs_use \
  untrusted_app.te \
  genfs_contexts

#
# Bootloader
#
TARGET_BOOTLOADER_BOARD_NAME := ventana
TARGET_BOOTLOADER_CONFIG := gwventana_config

#
# Filesystem
#
BUILD_TARGET_FS ?= ext4
include device/fsl/imx6/imx6_target_fs.mk
TARGET_RECOVERY_FSTAB = device/gateworks/ventana/fstab_nand
PRODUCT_COPY_FILES += device/gateworks/ventana/fstab_nand:root/fstab_nand
PRODUCT_COPY_FILES += device/gateworks/ventana/fstab_block:root/fstab_block

# we don't support sparse image.
TARGET_USERIMAGES_SPARSE_EXT_DISABLED := true

# Generated NAND images
TARGET_USERIMAGES_USE_UBIFS = true

# 2G geometry
ifeq ($(TARGET_USERIMAGES_USE_UBIFS),true)
UBI_ROOT_INI := device/gateworks/ventana/ubi/ubinize.ini
TARGET_MKUBIFS_ARGS := -F -m 4096 -e 248KiB -c 8124 -x zlib
TARGET_UBIRAW_ARGS := -m 4096 -p 256KiB -s 4096 $(UBI_ROOT_INI)
endif


#
# Wireless
#
BOARD_WPA_SUPPLICANT_DRIVER      := NL80211
WPA_SUPPLICANT_VERSION           := VER_0_8_X
BOARD_WLAN_DEVICE                := wl12xx_mac80211
BOARD_WPA_SUPPLICANT_PRIVATE_LIB := lib_driver_cmd_wl12xx
SKIP_WPA_SUPPLICANT_RTL          := y
SKIP_WPA_SUPPLICANT_CONF         := y


#
# Modem
#
BOARD_MODEM_HAVE_DATA_DEVICE := false


#
# GPS
#
USE_ATHR_GPS_HARDWARE := true


#
# Sensors
#
BOARD_HAS_SENSOR := true


#
# Bluetooth
#
BOARD_HAVE_BLUETOOTH := true
BOARD_HAVE_BLUETOOTH_BCM := true
# This requires a patched Bluedroid that supports bt_usb via the broadcom
# vendor lib
BLUETOOTH_HCI_USE_USB := true
# if not defined uses hardware/broadcom/libbt/include/vnd_generic_usb.txt
#BOARD_BLUEDROID_VENDOR_CONF := device/gateworks/ventana/bluetooth/vnd_ventana.
BOARD_BLUETOOTH_BDROID_BUILDCFG_INCLUDE_DIR := device/gateworks/ventana/bluetooth


# GPU
include device/fsl-proprietary/gpu-viv/fsl-gpu.mk


# Memory Allocation
USE_ION_ALLOCATOR := false
USE_GPU_ALLOCATOR := true


# Camera hal v2
IMX_CAMERA_HAL_V2 := true

