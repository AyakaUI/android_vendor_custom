#!/bin/bash
set -e

DEVICE="$1"
ROM_TYPE="${2:-OSS}"

if [ -z "$DEVICE" ]; then
    echo "Uso: $0 <device> [rom_type]"
    exit 1
fi

ROM_NAME=AyakaUI
ANDROID_VERSION=16.2
BUILD_VERSION=BP4A
OUT="out/target/product/$DEVICE"
OTA_REPO="ota"
# OTA_JSON="${OTA_REPO}/${DEVICE}.json"

REMOTE_REPO='https://github.com/AyakaUI/official_devices.git'
REPO_DIR='official_devices_repo'
TARGET_PATH='API/updater'
TARGET_FILE="${TARGET_PATH}/${DEVICE}.json"

ZIP=$(ls "$OUT/${ROM_NAME}_${BUILD_VERSION}-${ROM_TYPE}-${DEVICE}-"*.zip 2>/dev/null | sort -r | head -n 1)

if [ ! -f "$ZIP" ]; then
    echo "❌ ZIP not found in $OUT"
    exit 1
fi

FILENAME=$(basename "$ZIP")
SIZE=$(stat -c%s "$ZIP")
MD5=$(md5sum "$ZIP" | awk '{print $1}')

DATE_RAW=$(echo "$FILENAME" | grep -oE '[0-9]{8}-[0-9]{6}')
DATE_YMD="${DATE_RAW:0:4}-${DATE_RAW:4:2}-${DATE_RAW:6:2}"
TIME_HMS="${DATE_RAW:9:2}:${DATE_RAW:11:2}:${DATE_RAW:13:2}"

DATETIME=$(date -d "$DATE_YMD $TIME_HMS" +%s)

URL="https://drive.serverhive.in/drive/5g9gBfVjgvqJ-iKaY4O6q7MC/$DEVICE/$DATE_YMD/$FILENAME"

echo "📂 Updating OTA for ${DEVICE} in external repo..."

rm -rf "$REPO_DIR"
git clone --depth 1 "$REMOTE_REPO" "$REPO_DIR"

mkdir -p "${REPO_DIR}/${TARGET_PATH}"

cat > "$REPO_DIR/${TARGET_FILE}" <<EOF
{
  "response": [
    {
      "datetime": $DATETIME,
      "filename": "$FILENAME",
      "id": "$MD5",
      "size": $SIZE,
      "url": "$URL",
      "version": "$ANDROID_VERSION"
    }
  ]
}
EOF

cd "$REPO_DIR"

git add "$TARGET_FILE"

if git diff --cached --quiet; then
    echo "ℹ️ No changes to the OTA for $DEVICE"
    exit 0
fi

COMMIT_MSG="ota(${DEVICE}): update to ${FILENAME}"
git commit -m "$COMMIT_MSG"

echo '✅ Successfully pushed to AyakaUI/official_devices'
git push
