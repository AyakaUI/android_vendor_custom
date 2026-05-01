#!/bin/bash
set -e

# ========================================================
# Environment Configuration
# ========================================================
ROM_ROOT=$(cd "$(dirname "$0")/../../../../" && pwd)
cd "$ROM_ROOT"

if [ -f .env ]; then
    set -a
    source .env
    set +a
fi

# Arguments (Device and Build Type)
RAW_DEVICE="${1:-$TARGET_PRODUCT}"
DEVICE=${RAW_DEVICE#*_}
ROM_TYPE="${2:-GAPPS}"

ROM_NAME="AyakaUI"
BUILD_VERSION="BP4A"
OUT_DIR="out/target/product/$DEVICE"

ZIP=$(ls ${OUT_DIR}/${ROM_NAME}*OFFICIAL*.zip 2>/dev/null | sort -r | head -n 1)

if [ -z "$ZIP" ]; then
    ZIP=$(ls "${OUT_DIR}/${ROM_NAME}"*.zip 2>/dev/null | sort -r | head -n 1)
fi

if [ -z "$ZIP" ] || [ ! -f "$ZIP" ]; then
    echo "❌ Error: ZIP file not found in $OUT_DIR"
    exit 1
fi

echo "🚀 Target file: $(basename "$ZIP")"
FILENAME=$(basename "$ZIP")

if [[ "$FILENAME" =~ (^|-)OFFICIAL(-|\.) ]] || [[ "$FORCE_JSON" == "1" ]]; then
    
    echo "🚀 Starting process for: $FILENAME"

    # 1. Environment Safety Check
    if [ -z "$GITLAB_TOKEN" ] || [ -z "$PROJECTID_GITLAB" ]; then
        echo "❌ Error: GITLAB_TOKEN or PROJECTID_GITLAB is not defined."
        echo "Official builds require these variables for the upload process."
        exit 1
    fi

    # 2. Upload to GitLab via 'lab' binary
    LAB_BIN="$ROM_ROOT/vendor/custom/build/soong/bin/lab"
    echo "📤 Uploading to GitLab..."
    LAB_OUTPUT=$($LAB_BIN "$DEVICE")
    
    # Extract the URL from lab output
    URL=$(echo "$LAB_OUTPUT" | grep "OTA_URL_RESULT:" | cut -d ' ' -f 2)

    if [ -z "$URL" ]; then
        echo "❌ Error: Could not retrieve the upload URL from 'lab'."
        exit 1
    fi

    # 3. Metadata Collection for JSON
    # Try to get timestamp from build.prop, fallback to current time
    DATETIME=$(grep "ro.build.date.utc=" "$OUT_DIR/system/build.prop" | cut -d'=' -f2 || true)
    if [ -z "$DATETIME" ]; then
        DATETIME=$(date +%s)
    fi

    MD5SUM=$(cat "${ZIP}.md5sum" | cut -d' ' -f1)
    SIZE=$(stat -c%s "$ZIP")

    # 4. Clone and Update OTA Repository (GitHub)
    OTA_REPO_DIR="/tmp/ayaka_ota"
    rm -rf "$OTA_REPO_DIR"
    
    echo "git cloning ota repo..."
    git clone https://github.com/AyakaUI/official_devices.git "$OTA_REPO_DIR" --depth 1
    
    JSON_FILE="$OTA_REPO_DIR/${DEVICE}.json"

    # Generate JSON file
    cat <<EOF > "$JSON_FILE"
{
  "response": [
    {
      "datetime": $DATETIME,
      "filename": "$FILENAME",
      "id": "$MD5SUM",
      "size": $SIZE,
      "url": "$URL",
      "version": "$BUILD_VERSION"
    }
  ]
}
EOF

    # 5. Push changes
    cd "$OTA_REPO_DIR"
    mv "${DEVICE}.json" API/updater
    git add "API/updater/${DEVICE}.json"
    git commit -m "OTA: Update $DEVICE - $(date +'%Y%m%d')"
    git push origin sixteen
    
    echo "✅ OTA Update completed successfully!"

elif [[ "$FILENAME" == *"UNOFFICIAL"* ]]; then
    # ========================================================
    # UNOFFICIAL Case: Skip upload but exit with SUCCESS (0)
    # ========================================================
    echo "------------------------------------------------------------"
    echo "ℹ️  SKIP: Build identified as UNOFFICIAL."
    echo "ℹ️  OTA JSON update is not required for this build type."
    echo "ℹ️  Filename: $FILENAME"
    echo "------------------------------------------------------------"
    exit 0
else
    # Fallback for unexpected naming conventions
    echo "⚠️  Warning: Unknown build type. Exiting safely."
    exit 0
fi
