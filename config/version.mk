CUSTOM_BUILD_DATE := $(shell date -u +%Y%m%d-%H%M)

CUSTOM_PLATFORM_VERSION := 16.1

CUSTOM_VERSION := $(CUSTOM_BUILD)-$(CUSTOM_PLATFORM_VERSION)-$(CUSTOM_BUILD_DATE)
CUSTOM_VERSION_PROP := sixteen

# PixelOS Platform Version
PRODUCT_PRODUCT_PROPERTIES += \
    ro.custom.build.date=$(CUSTOM_BUILD_DATE) \
    ro.custom.device=$(CUSTOM_BUILD) \
    ro.custom.version=PixelOS_$(CUSTOM_VERSION)

# Updater
ifeq ($(IS_OFFICIAL),true)
    PRODUCT_PRODUCT_PROPERTIES += \
        net.pixelos.build_type=ci \
        net.pixelos.version=$(CUSTOM_VERSION_PROP)
endif
