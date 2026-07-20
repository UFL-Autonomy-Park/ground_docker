#!/bin/bash

# udev rule setup for Emlid Reach M+
# This creates a persistent symlink so the device is always at /dev/emlid

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Please run this script as root or use sudo.${NC}"
  exit 1
fi

echo -e "${GREEN}=== Emlid udev Rule Setup ===${NC}"
echo ""

# FTDI device detected on your system
VENDOR_ID="3032"
PRODUCT_ID="0010"
SYMLINK_NAME="emlid"

UDEV_RULES_FILE="/etc/udev/rules.d/99-emlid.rules"

echo "Device Info:"
echo "  Vendor ID:  $VENDOR_ID"
echo "  Product ID: $PRODUCT_ID"
echo "  Symlink:    /dev/$SYMLINK_NAME"
echo ""

# Create the udev rule with serial number for extra specificity
echo -e "${YELLOW}Creating udev rule...${NC}"
cat <<EOF > $UDEV_RULES_FILE
# Emlid Reach M+ GPS Unit
SUBSYSTEMS=="usb", KERNEL=="ttyACM[0-9]*", ACTION=="add", ATTRS{idVendor}=="$VENDOR_ID", ATTRS{idProduct}=="$PRODUCT_ID", MODE="666", SYMLINK+="$SYMLINK_NAME", GROUP+="dialout"
EOF

echo -e "${GREEN}udev rule created: $UDEV_RULES_FILE${NC}"
cat $UDEV_RULES_FILE

# Reload udev rules
echo ""
echo -e "${YELLOW}Reloading udev rules...${NC}"
udevadm control --reload-rules
udevadm trigger

echo ""
echo -e "${GREEN}=== Setup Complete! ===${NC}"
echo ""
echo "Your Emlid will now be available at: /dev/$SYMLINK_NAME"
echo ""
echo -e "${YELLOW}Testing...${NC}"
if [ -e "/dev/$SYMLINK_NAME" ]; then
    echo -e "${GREEN}✓ Symlink /dev/$SYMLINK_NAME exists!${NC}"
    ls -l /dev/$SYMLINK_NAME
else
    echo -e "${YELLOW}Symlink not found yet. Please unplug and replug your device.${NC}"
fi

echo ""
echo "Update your .env file to use:"
echo "  EMLID_DEVICE_PATH=/dev/$SYMLINK_NAME"
