#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Stopping and disabling ground Docker service...${NC}"

sudo systemctl stop ground-docker.service 2>/dev/null || true
sudo systemctl disable ground-docker.service 2>/dev/null || true
sudo rm -f /etc/systemd/system/ground-docker.service
sudo systemctl daemon-reload

echo -e "${GREEN}Auto-start removed successfully!${NC}"
