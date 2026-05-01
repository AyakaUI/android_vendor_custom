#!/bin/bash

if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
fi

VERSION="sixteen-qpr2"
cd "$(dirname "$0")/../../"
ROOT_DIR=$(pwd)
DEVICES_DIR="$ROOT_DIR/devices"
DEVICE=$1

if [ -z "$DEVICE" ]; then
    echo "Error: Please provide the device name.. E.g: ./monitor.sh fogos"
    exit 1
fi

mkdir -p "$DEVICES_DIR"
COUNT_FILE="$DEVICES_DIR/${DEVICE}_counts.txt"

if [ ! -f "$COUNT_FILE" ]; then
    echo 0 > "$COUNT_FILE"
fi

BUILD_NUM=$(($(cat "$COUNT_FILE") + 1))
echo "$BUILD_NUM" > "$COUNT_FILE"

echo "Device: $DEVICE | Build: #$BUILD_NUM"
echo "Starting build process..."

START_TIME=$(date +%s)

#source build/envsetup.sh
#breakfast "$DEVICE"
m ayaka 

if [ $? -ne 0 ]; then
    echo "------------------------------------------------"
    echo "ERROR: The build failed! Message not sent to CI.."
    echo "------------------------------------------------"
    exit 1
fi

echo "Generating JSON and uploading the OTA..."
./build/tools/ota.sh "$DEVICE"

END_TIME=$(date +%s)
DIFF=$((END_TIME - START_TIME))

H=$((DIFF / 3600))
M=$(((DIFF % 3600) / 60))
S=$((DIFF % 60))

TAG_DATE=$(date +%Y%m%d_%H%M)

MESSAGE="<b>${DEVICE}</b> #${BUILD_NUM} finished

<b>version</b>: ${VERSION}
<b>tag</b>: ${DEVICE}_${TAG_DATE}
<b>duration</b>: ${H}h ${M}m ${S}s

#${DEVICE}"

echo -e "\n--------------------------------------"
echo -e "$MESSAGE"
echo "--------------------------------------"

echo "Sending to Telegram..."
curl -s -X POST "https://api.telegram.org/bot${TOKEN}/sendMessage" \
    -d chat_id="${CHAT_ID}" \
    -d text="${MESSAGE}" \
    -d parse_mode="HTML" > /dev/null

echo "Completed successfully!"
