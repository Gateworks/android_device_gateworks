BOOTSCRIPT_TARGET := $(PRODUCT_OUT)/boot/boot/6x_bootscript-ventana
$(BOOTSCRIPT_TARGET): device/gateworks/ventana/6x_bootscript.txt $(PRODUCT_OUT)/u-boot.img
	mkdir -p $(dir $@)
	$(TOPDIR)bootable/bootloader/uboot-imx/tools/mkimage -A arm -O linux -T script -C none -a 0 -e 0 -n "boot script" -d $< $@

.PHONY: bootscript
bootscript: $(BOOTSCRIPT_TARGET) $(TARGET_BOOTLOADER_IMAGE)

droidcore: bootscript
