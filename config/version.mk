CUSTOM_BUILD_DATE := $(shell date -u +%Y%m%d-%H%M)

CUSTOM_PLATFORM_VERSION := 17.0

CUSTOM_VERSION := $(AYAKA_BUILD)-$(CUSTOM_PLATFORM_VERSION)-$(CUSTOM_BUILD_DATE)
CUSTOM_VERSION_PROP := seventeen

# AyakaUI Platform Version
PRODUCT_PRODUCT_PROPERTIES += \
    ro.custom.build.date=$(CUSTOM_BUILD_DATE) \
    ro.ayaka.device=$(AYAKA_BUILD) \
    ro.ayaka.maintainer=$(AYAKA_MAINTAINER) \
    ro.custom.version=Ayaka_$(CUSTOM_VERSION)

# Versioning System
AYAKA_BUILD_DATETIME := $(shell date +%s)
AYAKA_BUILD_DATE := $(shell date -d @$(AYAKA_BUILD_DATETIME) +"%Y%m%d-%H%M%S")

TARGET_PRODUCT_SHORT := $(subst ayaka_,,$(AYAKA_BUILD))

ifeq ($(WITH_GMS),true)
    AYAKA_BUILD_TYPE ?= GAPPS
else
    AYAKA_BUILD_TYPE ?= VANILLA
endif

# Updater
ifeq ($(IS_OFFICIAL),true)
    BUILD_TYPE ?= OFFICIAL
    PRODUCT_PRODUCT_PROPERTIES += \
        net.ayaka.build_type=official \
        net.ayaka.version=$(CUSTOM_VERSION_PROP)
else
    BUILD_TYPE ?= UNOFFICIAL
endif

AYAKA_VERSION := $(TARGET_PRODUCT_SHORT)-$(AYAKA_BUILD_TYPE)-$(CUSTOM_PLATFORM_VERSION)-$(CUSTOM_BUILD_DATE)

PRODUCT_SYSTEM_DEFAULT_PROPERTIES += \
  ro.ayaka.version=$(AYAKA_VERSION)
