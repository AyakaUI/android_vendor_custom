#!/bin/bash
set -e

DEVICE="$1"
ROM_TYPE="${2:-OSS}"

if [ -z "$DEVICE" ]; then
    echo "Uso: $0 <device> [rom_type]"
    exit 1
fi

# -------- CONFIG --------
ROM_NAME=AyakaUI
ANDROID_VERSION=16.2
BUILD_VERSION=BP4A
OUT="out/target/product/$DEVICE"
OTA_REPO="ota"
OTA_JSON="${OTA_REPO}/${DEVICE}.json"

# -------- FIND ZIP --------
ZIP=$(ls -t "$OUT/${ROM_NAME}_${BUILD_VERSION}-${ROM_TYPE}-${DEVICE}-"*.zip | head -n 1)

if [ ! -f "$ZIP" ]; then
    echo "❌ ZIP não encontrado"
    exit 1
fi

# -------- METADATA --------
FILENAME=$(basename "$ZIP")
SIZE=$(stat -c%s "$ZIP")
MD5=$(md5sum "$ZIP" | awk '{print $1}')

DATE_PART=$(echo "$FILENAME" | grep -o '[0-9]\{8\}-[0-9]\{6\}')
BUILD_DATE="${DATE_PART:0:4}-${DATE_PART:4:2}-${DATE_PART:6:2} ${DATE_PART:9:2}:${DATE_PART:11:2}:${DATE_PART:13:2}"
DATETIME=$(date -d "$BUILD_DATE" +%s)

URL="https://drive.serverhive.in/drive/5g9gBfVjgvqJ-iKaY4O6q7MC/$DEVICE/$(date +%Y-%m-%d)/$FILENAME"

cat > "$OTA_JSON" <<EOF
{
  "response": [
    {
      "datetime": $DATETIME,
      "filename": "$FILENAME",
      "id": "$MD5",
      "romtype": "$ROM_TYPE",
      "size": $SIZE,
      "url": "$URL",
      "version": "$ANDROID_VERSION"
    }
  ]
}
EOF

cd "$OTA_REPO"

git add "${DEVICE}.json"

if git diff --cached --quiet; then
    echo "ℹ️ None change on OTA"
    exit 0
fi

git commit -m "ota(${DEVICE}): update to ${FILENAME}"
git push
