LOCAL_PATH := $(call my-dir)

ifeq ($(PREBUILT_FSL_IMX_CODEC),true)
include device/fsl-proprietary/codec/fsl-codec.mk
endif

include device/gateworks/bootscript.mk
include device/gateworks/ramdisk.mk
