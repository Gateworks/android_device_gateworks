#
# Makefile targets for generating ubifs filesystems
#

RAMDISK_TARGET_UBIFS := $(PRODUCT_OUT)/boot.ubifs
$(RAMDISK_TARGET_UBIFS): $(PRODUCT_OUT)/boot.img
	mkfs.ubifs $(TARGET_MKUBIFS_ARGS) -d $(PRODUCT_OUT)/boot -o $@

RAMDISK_RECOVERY_TARGET_UBIFS := $(PRODUCT_OUT)/recovery.ubifs
$(RAMDISK_RECOVERY_TARGET_UBIFS): $(PRODUCT_OUT)/recovery.img
	mkfs.ubifs $(TARGET_MKUBIFS_ARGS) -d $(PRODUCT_OUT)/recovery -o $@

SYSTEM_TARGET_UBIFS := $(PRODUCT_OUT)/system.ubifs
$(SYSTEM_TARGET_UBIFS): $(PRODUCT_OUT)/system.img
	mkfs.ubifs $(TARGET_MKUBIFS_ARGS) -d $(PRODUCT_OUT)/system -o $@

droidcore: $(RAMDISK_TARGET_UBIFS) $(RAMDISK_RECOVERY_TARGET_UBIFS) $(SYSTEM_TARGET_UBIFS)
