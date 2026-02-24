CUSTOM_BUILD_DATE := $(shell date -u +%Y%m%d-%H%M)

CUSTOM_PLATFORM_VERSION := 16.2

CUSTOM_VERSION := $(FLAVOR_BUILD)-$(CUSTOM_PLATFORM_VERSION)-$(CUSTOM_BUILD_DATE)
CUSTOM_VERSION_PROP := sixteen

# FlavorOS Platform Version
PRODUCT_PRODUCT_PROPERTIES += \
    ro.custom.build.date=$(CUSTOM_BUILD_DATE) \
    ro.flavor.device=$(FLAVOR_BUILD) \
    ro.custom.version=Flavor_$(CUSTOM_VERSION)

# Versioning System
FLAVOR_BUILD_DATETIME := $(shell date +%s)
FLAVOR_BUILD_DATE := $(shell date -d @$(FLAVOR_BUILD_DATETIME) +"%Y%m%d-%H%M%S")

TARGET_PRODUCT_SHORT := $(subst flavor_,,$(FLAVOR_BUILD))

FLAVOR_BUILD_TYPE ?= OSS
FLAVOR_BUILD_VERSION := BP3A
FLAVOR_VERSION := $(FLAVOR_BUILD_VERSION)-$(FLAVOR_BUILD_TYPE)-$(TARGET_PRODUCT_SHORT)-$(FLAVOR_BUILD_DATE)

PRODUCT_SYSTEM_DEFAULT_PROPERTIES += \
  ro.flavor.version=$(FLAVOR_VERSION) \

# Updater
PRODUCT_PRODUCT_PROPERTIES += \
    net.flavoros.build_type=ci \
    net.flavoros.version=$(CUSTOM_VERSION_PROP)
