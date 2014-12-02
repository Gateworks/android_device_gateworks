#
# Product-specific compile-time definitions.
#

include device/fsl/imx6/soc/imx6dq.mk
include device/gateworks/ventana/build_id.mk
include device/fsl/imx6/BoardConfigCommon.mk
# 380MB system image (prune to size needed for system apps)
BOARD_SYSTEMIMAGE_PARTITION_SIZE := 398458880

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
  imx6dl:imx6dl-gw54xx.dtb \
  imx6dl:imx6dl-gw53xx.dtb \
  imx6dl:imx6dl-gw52xx.dtb \
  imx6dl:imx6dl-gw51xx.dtb \
  imx6dl:imx6dl-gw552x.dtb

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
ifeq ($(BUILD_TARGET_FS),ubifs)
TARGET_RECOVERY_FSTAB = device/gateworks/ventana/fstab_nand.freescale
# build ubifs for nand devices
PRODUCT_COPY_FILES +=	\
	device/gateworks/ventana/fstab_nand.freescale:root/fstab.freescale
else
TARGET_RECOVERY_FSTAB = device/gateworks/ventana/fstab.freescale
# build for ext4
PRODUCT_COPY_FILES +=	\
	device/gateworks/ventana/fstab.freescale:root/fstab.freescale
endif # BUILD_TARGET_FS

# we don't support sparse image.
TARGET_USERIMAGES_SPARSE_EXT_DISABLED := true

# uncomment below lins if use NAND
#TARGET_USERIMAGES_USE_UBIFS = true

# 2G geometry
ifeq ($(TARGET_USERIMAGES_USE_UBIFS),true)
UBI_ROOT_INI := device/gateworks/ventana/ubi/ubinize.ini
TARGET_MKUBIFS_ARGS := -m 4096 -e 516096 -c 4096 -x none
TARGET_UBIRAW_ARGS := -m 4096 -p 512KiB $(UBI_ROOT_INI)
endif

ifeq ($(TARGET_USERIMAGES_USE_UBIFS),true)
ifeq ($(TARGET_USERIMAGES_USE_EXT4),true)
$(error "TARGET_USERIMAGES_USE_UBIFS and TARGET_USERIMAGES_USE_EXT4 config open in same time, please only choose one target file system image")
endif
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


# GPU
include device/fsl-proprietary/gpu-viv/fsl-gpu.mk


# Memory Allocation
USE_ION_ALLOCATOR := false
USE_GPU_ALLOCATOR := true


# Camera hal v2
IMX_CAMERA_HAL_V2 := true


# define frame buffer count
NUM_FRAMEBUFFER_SURFACE_BUFFERS := 3
