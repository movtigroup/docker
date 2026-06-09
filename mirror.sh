#!/bin/bash

# Docker Mirror Configuration Script by Movti Group

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PLAIN='\033[0m'

if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Please run as root${PLAIN}"
    exit 1
fi

PRIMARY_MIRROR="https://docker.ththt.ir"

unmask_docker() {
    if command -v systemctl >/dev/null 2>&1; then
        echo -e "${YELLOW}Unmasking Docker service...${PLAIN}"
        systemctl unmask docker.service >/dev/null 2>&1 || true
        systemctl unmask docker.socket >/dev/null 2>&1 || true
    fi
}

echo -e "${YELLOW}Configuring Docker registry mirrors...${PLAIN}"
mkdir -p /etc/docker
cat > /etc/docker/daemon.json <<JSON
{
  "registry-mirrors": [
    "$PRIMARY_MIRROR",
    "https://docker.arvancloud.ir",
    "https://mirror2.chabokan.net",
    "https://docker.abrha.net"
  ]
}
JSON

unmask_docker

if command -v systemctl >/dev/null 2>&1; then
    systemctl daemon-reload
    systemctl restart docker || true
else
    service docker restart || true
fi

echo -e "${GREEN}Docker registry mirrors have been updated!${PLAIN}"
echo -e "${BLUE}Primary Mirror: $PRIMARY_MIRROR${PLAIN}"
