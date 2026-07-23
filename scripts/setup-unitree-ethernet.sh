#!/usr/bin/env bash

set -Eeuo pipefail

readonly CONNECTION_NAME="${UNITREE_CONNECTION_NAME:-unitree-go1}"
readonly HOST_ADDRESS="192.168.123.162/24"
readonly ROBOT_ADDRESS="192.168.123.161"

usage() {
    cat <<EOF
Usage: $(basename "$0") <onboard-ethernet-interface>

Creates or updates a persistent NetworkManager profile for a Unitree Go1.

Example:
  sudo $(basename "$0") eth0

Use the Jetson's onboard Ethernet interface, not the USB-to-Ethernet lidar
adapter. List interfaces with:
  nmcli device status
EOF
}

if [[ $# -ne 1 ]]; then
    usage
    exit 2
fi

if [[ ${EUID} -ne 0 ]]; then
    exec sudo -- "$0" "$@"
fi

for command in nmcli ip udevadm grep; do
    if ! command -v "${command}" >/dev/null 2>&1; then
        echo "Error: required command '${command}' was not found." >&2
        exit 1
    fi
done

readonly INTERFACE="$1"
readonly SYSFS_PATH="/sys/class/net/${INTERFACE}"

if [[ ! -e "${SYSFS_PATH}" ]]; then
    echo "Error: network interface '${INTERFACE}' does not exist." >&2
    echo >&2
    nmcli device status >&2 || true
    exit 1
fi

DEVICE_TYPE="$(nmcli -g GENERAL.TYPE device show "${INTERFACE}" 2>/dev/null || true)"
if [[ "${DEVICE_TYPE}" != "ethernet" ]]; then
    echo "Error: '${INTERFACE}' is not reported as an Ethernet interface." >&2
    echo "Detected type: ${DEVICE_TYPE:-unknown}" >&2
    exit 1
fi

# Do not accidentally assign the Unitree subnet to the Velodyne
# USB-to-Ethernet adapter
UDEV_PROPERTIES="$(udevadm info --query=property --path="${SYSFS_PATH}" 2>/dev/null || true)"
if grep -qx 'ID_BUS=usb' <<<"${UDEV_PROPERTIES}"; then
    echo "Error: '${INTERFACE}' appears to be a USB Ethernet adapter." >&2
    echo "Use the Jetson's onboard Ethernet interface for the Unitree Go1." >&2
    exit 1
fi

readonly MAC_ADDRESS="$(cat "${SYSFS_PATH}/address")"

printf 'Configuring persistent Unitree Go1 network profile\n'
printf '  Connection: %s\n' "${CONNECTION_NAME}"
printf '  Interface:  %s\n' "${INTERFACE}"
printf '  MAC address: %s\n' "${MAC_ADDRESS}"
printf '  Jetson IP:   %s\n' "${HOST_ADDRESS}"
printf '  Go1 IP:      %s\n\n' "${ROBOT_ADDRESS}"

if nmcli -t -f NAME connection show | grep -Fxq "${CONNECTION_NAME}"; then
    echo "Updating existing NetworkManager profile '${CONNECTION_NAME}'."
else
    echo "Creating NetworkManager profile '${CONNECTION_NAME}'."
    nmcli connection add \
        type ethernet \
        con-name "${CONNECTION_NAME}" \
        ifname "${INTERFACE}"
fi

nmcli connection modify "${CONNECTION_NAME}" \
    connection.interface-name "${INTERFACE}" \
    connection.autoconnect yes \
    connection.autoconnect-priority 100 \
    802-3-ethernet.mac-address "${MAC_ADDRESS}" \
    ipv4.method manual \
    ipv4.addresses "${HOST_ADDRESS}" \
    ipv4.gateway "" \
    ipv4.dns "" \
    ipv4.never-default yes \
    ipv6.method disabled

nmcli connection up "${CONNECTION_NAME}" ifname "${INTERFACE}"

echo
echo "Applied IPv4 configuration:"
ip -4 address show dev "${INTERFACE}"

echo
echo "Route selected for the Unitree Go1:"
ROUTE_OUTPUT="$(ip route get "${ROBOT_ADDRESS}")"
echo "${ROUTE_OUTPUT}"

if ! grep -Eq "dev ${INTERFACE}( |$)" <<<"${ROUTE_OUTPUT}"; then
    echo "Error: traffic to ${ROBOT_ADDRESS} is not using ${INTERFACE}." >&2
    exit 1
fi

if ! grep -Eq "src 192\\.168\\.123\\.162( |$)" <<<"${ROUTE_OUTPUT}"; then
    echo "Error: traffic to ${ROBOT_ADDRESS} is not using source 192.168.123.162." >&2
    exit 1
fi

echo
if ping -I "${INTERFACE}" -c 1 -W 1 "${ROBOT_ADDRESS}" >/dev/null 2>&1; then
    echo "Unitree Go1 responded at ${ROBOT_ADDRESS}."
else
    echo "Profile applied successfully; the Go1 did not answer one test ping."
    echo "This is expected if the robot is powered off, disconnected, or blocks ICMP."
fi

echo
echo "Persistent Unitree network configuration is complete."