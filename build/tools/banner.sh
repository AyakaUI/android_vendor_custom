#!/bin/bash

PURPLE="\033[38;5;141m"
PINK="\033[38;5;177m"
WHITE="\033[97m"
RESET="\033[0m"

clear

echo -e "${PURPLE}"
cat <<'EOF'

              █████╗ ██╗   ██╗ █████╗ ██╗  ██╗ █████╗
             ██╔══██╗╚██╗ ██╔╝██╔══██╗██║ ██╔╝██╔══██╗
             ███████║ ╚████╔╝ ███████║█████╔╝ ███████║
             ██╔══██║  ╚██╔╝  ██╔══██║██╔═██╗  ██╔══██║
             ██║  ██║   ██║   ██║  ██║██║  ██╗ ██║  ██║
             ╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═╝  ╚═╝

EOF

echo -e "${PINK}"
cat <<'EOF'

                     ✦  A Y A K A U I  ✦

EOF

echo -e "${WHITE}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "        Thank you for building AyakaUI 💜"
echo ""
echo "        Crafted with passion and dedication"
echo "        by the AyakaUI Team"
echo ""
echo "        We appreciate every contributor,"
echo "        tester and supporter."
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${RESET}"

echo -e "${PURPLE}Build Information${RESET}"
echo "-----------------"
echo "Device : ${TARGET_PRODUCT:-unknown}"
echo "Version: ${CUSTOM_PLATFORM_VERSION:-unknown}"
echo "Build  : ${AYAKA_VERSION:-unknown}"
echo ""
