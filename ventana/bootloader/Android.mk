LOCAL_PATH:= $(call my-dir)

include $(CLEAR_VARS)
LOCAL_C_INCLUDES += external/i2c-tools/tools external/i2c-tools/include
LOCAL_WHOLE_STATIC_LIBRARIES += i2c-tools
LOCAL_SRC_FILES := bootmode.c
LOCAL_MODULE := device_bootmode
include $(BUILD_STATIC_LIBRARY)

