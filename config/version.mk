CUSTOM_BUILD_DATE := $(shell date -u +%Y%m%d-%H%M)

CUSTOM_PLATFORM_VERSION := 16.1

CUSTOM_VERSION := $(CUSTOM_BUILD)-$(CUSTOM_PLATFORM_VERSION)-$(CUSTOM_BUILD_DATE)
CUSTOM_VERSION_PROP := sixteen

# PixelOS Platform Version
PRODUCT_PRODUCT_PROPERTIES += \
    ro.custom.build.date=$(CUSTOM_BUILD_DATE) \
    ro.custom.device=$(CUSTOM_BUILD) \
    ro.custom.version=Flavor_$(CUSTOM_VERSION)

# Versioning System
FLAVOR_BUILD_DATETIME := $(shell date +%s)
FLAVOR_BUILD_DATE := $(shell date -d @$(FLAVOR_BUILD_DATETIME) +"%Y%m%d-%H%M%S")

TARGET_PRODUCT_SHORT := $(subst custom_,,$(CUSTOM_BUILD))

FLAVOR_BUILD_TYPE ?= OSS
FLAVOR_BUILD_VERSION := BP3A
FLAVOR_VERSION := $(FLAVOR_BUILD_VERSION)-$(FLAVOR_BUILD_TYPE)-$(TARGET_PRODUCT_SHORT)-$(FLAVOR_BUILD_DATE)

PRODUCT_SYSTEM_DEFAULT_PROPERTIES += \
  ro.flavor.version=$(FLAVOR_VERSION) \

# Updater
ifeq ($(IS_OFFICIAL),true)
    PRODUCT_PRODUCT_PROPERTIES += \
        net.pixelos.build_type=ci \
        net.pixelos.version=$(CUSTOM_VERSION_PROP)
endif
