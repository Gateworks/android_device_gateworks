ifneq (,$(findstring $(TARGET_DEVICE),ventana))

LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE := librecovery_updater_ventana
LOCAL_SRC_FILES := recovery_updater.c
LOCAL_C_INCLUDES += bootable/recovery

include $(BUILD_STATIC_LIBRARY)

endif
