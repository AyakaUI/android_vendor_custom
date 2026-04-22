#!/bin/bash
set -e

# ========================================================
# Environment Configuration
# ========================================================
ROM_ROOT=$(cd "$(dirname "$0")/../../../../" && pwd)
cd "$ROM_ROOT"

# Device Detection: 1st argument or $TARGET_PRODUCT
# Cleans prefix (e.g., ayaka_fogos -> fogos)
RAW_DEVICE="${1:-$TARGET_PRODUCT}"
if [ -z "$RAW_DEVICE" ]; then
    echo "❌ Error: No device detected. Please run 'lunch' or pass device as an argument."
    exit 1
fi

DEVICE=${RAW_DEVICE#*_}
ROM_TYPE="${2:-GAPPS}"

# ROM Variables
ROM_NAME="AyakaUI"
ANDROID_VERSION="16.2"
BUILD_VERSION="BP4A"
OUT_DIR="out/target/product/$DEVICE"
BUILD_PROP="$OUT_DIR/system/build.prop"
LAB_BIN="./lab"

# OTA Repository
REMOTE_REPO="https://github.com/AyakaUI/official_devices.git"
REPO_DIR="official_devices_repo"
TARGET_PATH="API/updater"
TARGET_FILE="${TARGET_PATH}/${DEVICE}.json"

# ========================================================
# ZIP File Localization
# ========================================================
# Find the ZIP based on the naming pattern
ZIP=$(ls "$OUT_DIR/${ROM_NAME}_${BUILD_VERSION}-${ROM_TYPE}-${DEVICE}-"*.zip 2>/dev/null | sort -r | head -n 1)

if [ ! -f "$ZIP" ]; then
    echo "❌ Error: ZIP file not found in $OUT_DIR"
    exit 1
fi

FILENAME=$(basename "$ZIP")

# ========================================================
# Upload Condition (OFFICIAL or FORCE_JSON=1)
# ========================================================
if [[ "$FILENAME" =~ "OFFICIAL" ]] || [[ "$FORCE_JSON" == "1" ]]; then
    
    echo "🚀 Starting process for: $FILENAME"

    # Ensure 'lab' binary exists
    if [ ! -f "$LAB_BIN" ]; then
        echo "🔍 Lab binary not found. Downloading..."
        wget -q https://github.com/whyakari/gitlab_upload/raw/refs/heads/main/lab -O "$LAB_BIN" || \
        curl -sL https://github.com/whyakari/gitlab_upload/raw/refs/heads/main/lab -o "$LAB_BIN"
        chmod +x "$LAB_BIN"
    fi

    echo "📤 Uploading to GitLab via 'lab'..."
    LAB_OUTPUT=$($LAB_BIN "$DEVICE")
    URL=$(echo "$LAB_OUTPUT" | grep "OTA_URL_RESULT:" | cut -d ' ' -f 2)

    if [ -z "$URL" ]; then
        echo "❌ Error: Could not retrieve the upload URL."
        exit 1
    fi

    # Metadata Extraction
    echo "📊 Gathering metadata..."
    SIZE=$(stat -c%s "$ZIP")
    MD5=$(md5sum "$ZIP" | awk '{print $1}')

    if [ -f "$BUILD_PROP" ]; then
        DATETIME=$(grep "ro.build.date.utc=" "$BUILD_PROP" | cut -d'=' -f2)
        echo "✅ Timestamp synced from build.prop: $DATETIME"
    else
        echo "⚠️ build.prop not found! Falling back to filename date."
        DATE_RAW=$(echo "$FILENAME" | grep -oE '[0-9]{8}-[0-9]{6}')
        DATE_YMD="${DATE_RAW:0:4}-${DATE_RAW:4:2}-${DATE_RAW:6:2}"
        TIME_HMS="${DATE_RAW:9:2}:${DATE_RAW:11:2}:${DATE_RAW:13:2}"
        DATETIME=$(date -d "$DATE_YMD $TIME_HMS" +%s)
    fi

    # ========================================================
    # OTA JSON Repository Update
    # ========================================================
    echo "📂 Updating OTA repository..."
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
        echo "ℹ️ No changes detected in JSON. Skipping push."
    else
        git commit -m "ota(${DEVICE}): update to ${FILENAME}"
        echo "📤 Pushing to GitHub..."
        git push
        echo "✅ OTA Update completed successfully!"
    fi

else
    echo "------------------------------------------------------------"
    echo "ℹ️  SKIP: Build identified as UNOFFICIAL."
    echo "ℹ️  OTA JSON will not be updated."
    echo "ℹ️  To force this process, use: FORCE_JSON=1 $0"
    echo "------------------------------------------------------------"
    exit 0
fi
