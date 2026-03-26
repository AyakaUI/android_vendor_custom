# Common PixelOS stuff.

# Bootanimation
ifeq ($(strip $(TARGET_SCREEN_WIDTH)),)
    $(warning "TARGET_SCREEN_WIDTH is undefined, assuming 1080p")
else
    $(call soong_config_set,vendor_custom,bootanimation_res,$(TARGET_SCREEN_WIDTH))
endif

PRODUCT_PACKAGES += \
    bootanimation_pixelos

# Charger
WITH_LINEAGE_CHARGER := false
PRODUCT_PACKAGES += \
    custom_charger_animation \
    custom_charger_animation_vendor

# Enable Material Design 3 Expressive
PRODUCT_PRODUCT_PROPERTIES += is_expressive_design_enabled=true

# Face Unlock
TARGET_FACE_UNLOCK_SUPPORTED ?= $(TARGET_SUPPORTS_64_BIT_APPS)

ifeq ($(TARGET_FACE_UNLOCK_SUPPORTED),true)
PRODUCT_PACKAGES += \
    ParanoidSense

PRODUCT_SYSTEM_EXT_PROPERTIES += \
    ro.face.sense_service=true

PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.biometrics.face.xml:$(TARGET_COPY_OUT_SYSTEM)/etc/permissions/android.hardware.biometrics.face.xml
endif

# GMS
include vendor/custom/config/pixel.mk

# EPPE
ifneq ($(TARGET_DISABLE_EPPE),true)
# Require all requested packages to exist
$(call enforce-product-packages-exist-internal,$(wildcard device/*/$(AYAKA_BUILD)/$(TARGET_PRODUCT).mk),product_manifest.xml rild Calendar android.hidl.memory@1.0-impl.vendor vndk_apex_snapshot_package)
endif

# Lineage-specific file
PRODUCT_COPY_FILES += \
    vendor/custom/config/permissions/privapp-permissions-lineagehw.xml:$(TARGET_COPY_OUT_SYSTEM_EXT)/etc/permissions/privapp-permissions-lineagehw.xml

# LMOFreeForm
PRODUCT_PACKAGES += \
    LMOFreeform \
    LMOFreeformSidebar

# Overlay
PRODUCT_PACKAGES += \
    FrameworkOverlayCustom \
    SettingsOverlayCustom

# TouchGesture
PRODUCT_PACKAGES += \
    TouchGestures

# Updater
include vendor/custom/config/ota.mk

# Version
include vendor/custom/config/version.mk

-include vendor/certification/config.mk
