#!/bin/bash
set -eo pipefail

# ========================================================
# AyakaUI OTA Generator
# ========================================================

# Global Variables
ROM_NAME="AyakaUI"
BUILD_VERSION="17.0"
OTA_REPO_URL="https://github.com/AyakaUI/official_devices.git"
OTA_REPO_BRANCH="seventeen"
OTA_REPO_DIR="/tmp/ayaka_ota"

# --------------------------------------------------------
# Helper Functions & Logging
# --------------------------------------------------------
log_info() {
    echo -e "ℹ️  $1"
}

log_success() {
    echo -e "✅ $1"
}

log_error() {
    echo -e "❌ $1" >&2
}

log_step() {
    echo -e "\n========================================="
    echo -e "$1"
    echo -e "========================================="
}

# --------------------------------------------------------
# Core Operations
# --------------------------------------------------------
setup_environment() {
    ROM_ROOT=$(cd "$(dirname "$0")/../../../../" && pwd)
    cd "$ROM_ROOT"

    if [[ -f .env ]]; then
        set -a
        source .env
        set +a
    fi
}

parse_arguments() {
    local raw_device="${1:-$TARGET_PRODUCT}"
    DEVICE="${raw_device#*_}"

    if [[ -z "$DEVICE" ]]; then
        log_error "Device target is not defined."
        exit 1
    fi
    OUT_DIR="out/target/product/$DEVICE"
}

find_ota_zip() {
    log_info "Searching for OTA zip file in ${OUT_DIR}..."

    # Check for OFFICIAL zip first
    ZIP=$(ls ${OUT_DIR}/${ROM_NAME}*OFFICIAL*.zip 2>/dev/null | sort -r | head -n1 || true)

    # Fallback to any ZIP matching pattern
    if [[ -z "$ZIP" ]]; then
        ZIP=$(ls ${OUT_DIR}/${ROM_NAME}*.zip 2>/dev/null | sort -r | head -n1 || true)
    fi

    if [[ -z "$ZIP" || ! -f "$ZIP" ]]; then
        log_error "OTA zip not found in ${OUT_DIR}"
        exit 1
    fi

    FILENAME=$(basename "$ZIP")
    log_info "Found Build ZIP: ${FILENAME}"

    # Check if UNOFFICIAL build
    if [[ "$FILENAME" == *"UNOFFICIAL"* ]]; then
        log_step "Skipping OTA Generation\n\nReason: UNOFFICIAL build detected"
        exit 0
    fi
}

check_credentials() {
    if [[ -z "$GITLAB_TOKEN" || -z "$PROJECTID_GITLAB" ]]; then
        log_error "Missing required GitLab variables (GITLAB_TOKEN, PROJECTID_GITLAB)"
        exit 1
    fi
}

upload_artifact() {
    local lab_bin="$ROM_ROOT/vendor/custom/build/soong/bin/lab"

    if [[ ! -x "$lab_bin" ]]; then
        log_error "Lab binary not found or not executable at: $lab_bin"
        exit 1
    fi

    log_info "Uploading build via Lab binary..."
    local lab_output
    lab_output=$("$lab_bin" "$DEVICE")

    URL=$(echo "$lab_output" | grep "OTA_URL_RESULT:" | cut -d' ' -f2)

    if [[ -z "$URL" ]]; then
        log_error "Upload failed or URL not returned in output"
        exit 1
    fi

    log_info "Artifact Uploaded URL: $URL"
}

extract_metadata() {
    log_info "Extracting OTA metadata..."
    local metadata
    metadata=$(unzip -p "$ZIP" META-INF/com/android/metadata)

    POST_TIMESTAMP=$(echo "$metadata" | grep "^post-timestamp=" | cut -d= -f2 || true)
    OS_PATCH_LEVEL=$(echo "$metadata" | grep "^post-security-patch-level=" | cut -d= -f2 || true)
    OS_SDK_LEVEL=$(echo "$metadata" | grep "^post-sdk-level=" | cut -d= -f2 || true)
    OTA_PROPERTY_FILES=$(echo "$metadata" | grep "^ota-property-files=" | cut -d= -f2 || true)

    if [[ -z "$POST_TIMESTAMP" ]]; then
        POST_TIMESTAMP=$(date +%s)
    fi

    SHA256=$(sha256sum "$ZIP" | cut -d' ' -f1)
    SIZE=$(stat -c%s "$ZIP")

    log_info "SHA256: $SHA256"
    log_info "Size: $SIZE bytes"
}

check_additional_images() {
    log_info "Checking for additional images..."
    local build_dir
    build_dir=$(dirname "$URL")

    IMAGES_JSON=""
    for image in boot.img vendor_boot.img; do
        local image_url="${build_dir}/${image}"

        if curl -fsI "$image_url" >/dev/null 2>&1; then
            log_info "Found additional image: ${image}"
            if [[ -z "$IMAGES_JSON" ]]; then
                IMAGES_JSON="      {\n        \"name\": \"$image\",\n        \"url\": \"$image_url\"\n      }"
            else
                IMAGES_JSON="${IMAGES_JSON},\n      {\n        \"name\": \"$image\",\n        \"url\": \"$image_url\"\n      }"
            fi
        fi
    done
}

generate_json_and_push() {
    log_info "Cloning OTA repository..."
    rm -rf "$OTA_REPO_DIR"
    git clone "$OTA_REPO_URL" "$OTA_REPO_DIR" --depth 1

    local json_file="$OTA_REPO_DIR/API/updater/${DEVICE}.json"
    mkdir -p "$(dirname "$json_file")"

    log_info "Generating OTA JSON configuration..."
    cat <<EOF > "$json_file"
[
  {
    "datetime": $POST_TIMESTAMP,
    "files": [
      {
        "filename": "$FILENAME",
        "os_patch_level": "$OS_PATCH_LEVEL",
        "os_sdk_level": $OS_SDK_LEVEL,
        "ota_property_files": "$OTA_PROPERTY_FILES",
        "sha256": "$SHA256",
        "size": $SIZE,
        "url": "$URL"
      }
    ],
    "type": "ci",
    "version": "$BUILD_VERSION"
EOF

    if [[ -n "$IMAGES_JSON" ]]; then
        cat <<EOF >> "$json_file"
,
    "additional_images": [
$(echo -e "$IMAGES_JSON")
    ]
EOF
    fi

    cat <<EOF >> "$json_file"

  }
]
EOF

    log_info "Generated JSON Output:"
    cat "$json_file"

    cd "$OTA_REPO_DIR"
    git add "API/updater/${DEVICE}.json"
    git commit -m "OTA: Update ${DEVICE} $(date +%Y%m%d)"
    git push origin "$OTA_REPO_BRANCH"
}

# --------------------------------------------------------
# Main Execution
# --------------------------------------------------------
main() {
    setup_environment
    parse_arguments "$@"
    find_ota_zip
    check_credentials
    upload_artifact
    extract_metadata
    check_additional_images
    generate_json_and_push

    log_step "✅ OTA Updated Successfully\n\nDevice: $DEVICE\nFile:   $FILENAME"
}

main "$@"
