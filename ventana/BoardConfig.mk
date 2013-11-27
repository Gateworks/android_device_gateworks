#
# Product-specific compile-time definitions.
#

include device/fsl/imx6/soc/imx6dq.mk
export BUILD_ID=4.3_1.0.0-ga
include device/fsl/imx6/BoardConfigCommon.mk

#
# Kernel
#
ifneq ($(DEFCONF),)
TARGET_KERNEL_DEFCONF := $(DEFCONF)
else
TARGET_KERNEL_DEFCONF := imx6_android_defconfig
endif
TARGET_KERNEL_MODULES :=


#
# Bootloader
#
TARGET_BOOTLOADER_BOARD_NAME := ventana
PRODUCT_MODEL := Gateworks Ventana
TARGET_BOOTLOADER_CONFIG := \
	gw54xx:gwventanaq1g_config \
	gw53xx:gwventanadl1g_config \
	gw52xx:gwventanadl_config \
	gw51xx:gwventanadl_config


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
BOARD_HAVE_WIFI := false
BOARD_WLAN_DEVICE            := ""


#
# Modem
#
BOARD_MODEM_HAVE_DATA_DEVICE := false


#
# GPS
#
BOARD_HAVE_HARDWARE_GPS := false


#
# Sensors
#
BOARD_HAS_SENSOR := false


# GPU
include device/fsl-proprietary/gpu-viv/fsl-gpu.mk


# Memory Allocation
USE_ION_ALLOCATOR := false
USE_GPU_ALLOCATOR := true


# Camera hal v2
IMX_CAMERA_HAL_V2 := true


# define frame buffer count
NUM_FRAMEBUFFER_SURFACE_BUFFERS := 3
