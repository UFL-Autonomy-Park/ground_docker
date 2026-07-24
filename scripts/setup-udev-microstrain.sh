#!/usr/bin/env bash

# Install the official MicroStrain udev rules on the host.

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}Please run this script using sudo.${NC}"
    exit 1
fi

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_RULE="${SCRIPT_DIR}/udev/97-microstrain.rules"
DESTINATION_RULE="/etc/udev/rules.d/97-microstrain.rules"

if [[ ! -f "$SOURCE_RULE" ]]; then
    echo -e "${RED}Rules file not found: ${SOURCE_RULE}${NC}"
    exit 1
fi

echo -e "${YELLOW}Installing MicroStrain udev rules...${NC}"

install -m 0644 "$SOURCE_RULE" "$DESTINATION_RULE"

udevadm control --reload-rules
udevadm trigger --subsystem-match=tty
udevadm settle

echo -e "${GREEN}Installed: ${DESTINATION_RULE}${NC}"

echo
echo "Detected MicroStrain device links:"
find /dev -maxdepth 1 -type l -name 'microstrain*' -ls 2>/dev/null || true

if [[ ! -e /dev/microstrain_main ]]; then
    echo
    echo -e "${YELLOW}/dev/microstrain_main was not found.${NC}"
    echo "Unplug and reconnect the MicroStrain USB cable, then run:"
    echo "  ls -l /dev/microstrain*"
fi