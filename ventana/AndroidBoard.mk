LOCAL_PATH := $(call my-dir)

ifneq ($(wildcard device/fsl-codec),)
ifeq ($(PREBUILT_FSL_IMX_CODEC),true)
include device/fsl-codec/fsl-codec.mk
endif
endif

include device/fsl-proprietary/media-profile/media-profile.mk
include device/gateworks/bootscript.mk
include device/gateworks/ramdisk.mk
include device/gateworks/ubi.mk
