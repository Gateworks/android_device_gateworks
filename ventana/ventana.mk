# This is a FSL Android Reference Design platform based on i.MX6Q ARD board
# It will inherit from FSL core product which in turn inherit from Google generic

$(call inherit-product, device/gateworks/ventana/imx6.mk)
$(call inherit-product-if-exists,vendor/google/products/gms.mk)

ifneq ($(wildcard device/gateworks/ventana/fstab_nand.freescale),)
$(shell touch device/gateworks/ventana/fstab_nand.freescale)
endif

ifneq ($(wildcard device/gateworks/ventana/fstab.freescale),)
$(shell touch device/gateworks/ventana/fstab.freescale)
endif

# Overrides
PRODUCT_NAME := ventana
PRODUCT_DEVICE := ventana

PRODUCT_COPY_FILES += \
	device/gateworks/ventana/required_hardware.xml:system/etc/permissions/required_hardware.xml \
	device/gateworks/ventana/init.rc:root/init.freescale.rc \
	device/gateworks/ventana/audio_policy.conf:system/etc/audio_policy.conf \
	device/gateworks/ventana/audio_effects.conf:system/vendor/etc/audio_effects.conf

# GPU files

DEVICE_PACKAGE_OVERLAYS := device/gateworks/ventana/overlay

PRODUCT_CHARACTERISTICS := tablet

PRODUCT_AAPT_CONFIG += xlarge large tvdpi hdpi

PRODUCT_COPY_FILES += \
	frameworks/native/data/etc/android.hardware.location.gps.xml:system/etc/permissions/android.hardware.location.gps.xml \
	frameworks/native/data/etc/android.hardware.wifi.xml:system/etc/permissions/android.hardware.wifi.xml \
	frameworks/native/data/etc/android.hardware.wifi.direct.xml:system/etc/permissions/android.hardware.wifi.direct.xml \
	frameworks/native/data/etc/android.hardware.sensor.light.xml:system/etc/permissions/android.hardware.sensor.light.xml \
	frameworks/native/data/etc/android.hardware.sensor.accelerometer.xml:system/etc/permissions/android.hardware.sensor.accelerometer.xml \
	frameworks/native/data/etc/android.hardware.faketouch.xml:system/etc/permissions/android.hardware.faketouch.xml \
	frameworks/native/data/etc/android.hardware.touchscreen.multitouch.jazzhand.xml:system/etc/permissions/android.hardware.touchscreen.multitouch.jazzhand.xml \
	frameworks/native/data/etc/android.software.sip.voip.xml:system/etc/permissions/android.software.sip.voip.xml \
	frameworks/native/data/etc/android.hardware.usb.host.xml:system/etc/permissions/android.hardware.usb.host.xml \
	frameworks/native/data/etc/android.hardware.usb.accessory.xml:system/etc/permissions/android.hardware.usb.accessory.xml \
	frameworks/native/data/etc/android.hardware.bluetooth_le.xml:system/etc/permissions/android.hardware.bluetooth_le.xml

# for PDK build, include only when the dir exists
# too early to use $(TARGET_BUILD_PDK)
ifneq ($(wildcard packages/wallpapers/LivePicker),)
PRODUCT_COPY_FILES += \
	packages/wallpapers/LivePicker/android.software.live_wallpaper.xml:system/etc/permissions/android.software.live_wallpaper.xml
endif
