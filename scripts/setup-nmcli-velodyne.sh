#!/usr/bin/env bash

set -euo pipefail

PROFILE_NAME="velodyne"
HOST_ADDRESS="192.168.2.100/24"
LIDAR_ADDRESS="192.168.2.201"

if [[ $# -ne 1 ]]; then
    echo "Usage: sudo $0 <USB-Ethernet-interface>"
    echo "Example: sudo $0 enx001122334455"
    exit 1
fi

INTERFACE="$1"

# Check if interface exists
if ! ip link show "$INTERFACE" >/dev/null 2>&1; then
    echo "Error: network interface '$INTERFACE' does not exist."
    exit 1
fi

# Get USB->Ethernet adapter MAC address
ADAPTER_MAC="$(
    cat "/sys/class/net/${INTERFACE}/address" | 
        tr '[:lower:]' '[:upper:]'
)"

echo "Configuring Velodyne network:"
echo "  Interface:   $INTERFACE"
echo "  Adapter MAC: $ADAPTER_MAC"
echo "  Host IP:     $HOST_ADDRESS"
echo "  LiDAR IP:    $LIDAR_ADDRESS"

# Check if nmcli rule exists already
if nmcli --terse --fields NAME connection show |
    grep --fixed-strings --quiet "$PROFILE_NAME"; then

    echo "Updating existing NetworkManager profile: $PROFILE_NAME"
else
    echo "Creating NetworkManager profile: $PROFILE_NAME"

    nmcli connection add \
        type ethernet \
        con-name "$PROFILE_NAME" \
        ifname "$INTERFACE"
fi

# Modify either the newly created connection or the existing one
nmcli connection modify "$PROFILE_NAME" \
    802-3-ethernet.mac-address "$ADAPTER_MAC" \
    ipv4.method manual \
    ipv4.addresses "$HOST_ADDRESS" \
    ipv4.gateway "" \
    ipv4.never-default yes \
    ipv4.ignore-auto-dns yes \
    ipv6.method disabled \
    connection.autoconnect yes

nmcli connection up "$PROFILE_NAME"

echo
echo "Current interface configuration:"
ip -brief address show "$INTERFACE"

echo
echo "Route to Velodyne:"
ip route get "$LIDAR_ADDRESS"

echo
if ping -c 3 -W 1 "$LIDAR_ADDRESS"; then
    echo "Velodyne is reachable at $LIDAR_ADDRESS."
else
    echo "Velodyne did not respond."
    echo "Check power, Ethernet link, and the sensor's configured IP address."
fi
