#!/bin/bash
set -e

ROM_ROOT=$(cd "$(dirname "$0")/../../../../" && pwd)
cd "$ROM_ROOT"

DEVICE="$1"
ROM_TYPE="${2:-GAPPS}" 

if [ -z "$DEVICE" ]; then
    echo "Usage: $0 <device> [rom_type]"
    exit 1
fi

ROM_NAME="AyakaUI"
ANDROID_VERSION="16.2"
BUILD_VERSION="BP4A"
OUT_DIR="out/target/product/$DEVICE"
BUILD_PROP="$OUT_DIR/system/build.prop"

LAB_BIN="./lab"

REMOTE_REPO="https://github.com/AyakaUI/official_devices.git"
REPO_DIR="official_devices_repo"
TARGET_PATH="API/updater"
TARGET_FILE="${TARGET_PATH}/${DEVICE}.json"

if [ ! -f "$LAB_BIN" ]; then
    echo "🔍 Lab binary not found in ROM root ($ROM_ROOT). Downloading..."
    wget -q https://github.com/whyakari/gitlab_upload/raw/refs/heads/main/lab -O "$LAB_BIN" || \
    curl -sL https://github.com/whyakari/gitlab_upload/raw/refs/heads/main/lab -o "$LAB_BIN"
    
    chmod +x "$LAB_BIN"
    echo "✅ Lab downloaded to $ROM_ROOT"
fi

echo "🚀 Starting upload to GitLab via 'lab'..."

LAB_OUTPUT=$($LAB_BIN "$DEVICE")
echo "$LAB_OUTPUT"

URL=$(echo "$LAB_OUTPUT" | grep "OTA_URL_RESULT:" | cut -d ' ' -f 2)

if [ -z "$URL" ]; then
    echo "❌ Error: Could not retrieve the upload URL from 'lab'."
    exit 1
fi

echo "🔍 Gathering build metadata..."

ZIP=$(ls "$OUT_DIR/${ROM_NAME}_${BUILD_VERSION}-${ROM_TYPE}-${DEVICE}-OFFICIAL-"*.zip 2>/dev/null | sort -r | head -n 1)

if [ ! -f "$ZIP" ]; then
    echo "❌ Error: ZIP file not found in $OUT_DIR"
    exit 1
fi

FILENAME=$(basename "$ZIP")
SIZE=$(stat -c%s "$ZIP")
MD5=$(md5sum "$ZIP" | awk '{print $1}')

if [ -f "$BUILD_PROP" ]; then
    DATETIME=$(grep "ro.build.date.utc=" "$BUILD_PROP" | cut -d'=' -f2)
    echo "✅ Syncing with system datetime: $DATETIME"
else
    echo "⚠️ build.prop not found! Falling back to filename date."
    DATE_RAW=$(echo "$FILENAME" | grep -oE '[0-9]{8}-[0-9]{6}')
    DATE_YMD="${DATE_RAW:0:4}-${DATE_RAW:4:2}-${DATE_RAW:6:2}"
    TIME_HMS="${DATE_RAW:9:2}:${DATE_RAW:11:2}:${DATE_RAW:13:2}"
    DATETIME=$(date -d "$DATE_YMD $TIME_HMS" +%s)
fi

echo "📂 Updating OTA JSON for ${DEVICE}..."

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
    echo "ℹ️ No changes detected. Skipping push."
    exit 0
fi

git commit -m "ota(${DEVICE}): update to ${FILENAME}"

echo "📤 Pushing update to GitHub..."
git push

echo "✅ OTA Update completed successfully!"
