# Common PixelOS stuff.

# Bootanimation
ifeq ($(strip $(TARGET_SCREEN_WIDTH)),)
    $(warning "TARGET_SCREEN_WIDTH is undefined, assuming 1080p")
else
    $(call soong_config_set,vendor_custom,bootanimation_res,$(TARGET_SCREEN_WIDTH))
endif

PRODUCT_PACKAGES += \
    bootanimation_pixelos

# GMS
include vendor/custom/config/pixel.mk

# EPPE
ifneq ($(TARGET_DISABLE_EPPE),true)
# Require all requested packages to exist
$(call enforce-product-packages-exist-internal,$(wildcard device/*/$(CUSTOM_BUILD)/$(TARGET_PRODUCT).mk),product_manifest.xml rild Calendar android.hidl.memory@1.0-impl.vendor vndk_apex_snapshot_package)
endif

# Overlay
PRODUCT_PACKAGES += \
    FrameworkOverlayCustom \
    SettingsOverlayCustom

# Updater
include vendor/custom/config/ota.mk

# Version
include vendor/custom/config/version.mk
