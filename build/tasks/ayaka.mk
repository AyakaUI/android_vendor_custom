# Copyright (C) 2017 Unlegacy-Android
# Copyright (C) 2017,2020 The LineageOS Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# -----------------------------------------------------------------
# AyakaUI OTA update package

AYAKA_TARGET_PACKAGE := $(PRODUCT_OUT)/AyakaUI_$(AYAKA_VERSION).zip

MD5 := prebuilts/build-tools/path/$(HOST_PREBUILT_TAG)/md5sum

$(AYAKA_TARGET_PACKAGE): $(INTERNAL_OTA_PACKAGE_TARGET)
	$(hide) ln -f $(INTERNAL_OTA_PACKAGE_TARGET) $(AYAKA_TARGET_PACKAGE)
	$(hide) $(MD5) $(AYAKA_TARGET_PACKAGE) | sed "s|$(PRODUCT_OUT)/||" > $(AYAKA_TARGET_PACKAGE).md5sum
	@echo "Package Complete: $(AYAKA_TARGET_PACKAGE)" >&2
	@echo "Generating update JSON for $(TARGET_DEVICE)..."
	$(hide) ./vendor/custom/build/tools/ota.sh $(TARGET_DEVICE)

.PHONY: ayaka
ayaka: $(AYAKA_TARGET_PACKAGE) $(DEFAULT_GOAL)
