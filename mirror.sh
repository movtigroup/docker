#!/bin/bash

# Docker Mirror Configuration Script by Movti Group

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PLAIN='\033[0m'

# Portable color echoing
info() { printf "${BLUE}%b${PLAIN}\n" "$*"; }
success() { printf "${GREEN}%b${PLAIN}\n" "$*"; }
warn() { printf "${YELLOW}%b${PLAIN}\n" "$*"; }
error() { printf "${RED}%b${PLAIN}\n" "$*"; }

if [ "$(id -u)" -ne 0 ]; then
    error "Please run as root (sudo)."
    exit 1
fi

PRIMARY_MIRROR="https://docker.ththt.ir"

unmask_docker() {
    if command -v systemctl >/dev/null 2>&1; then
        warn "Unmasking Docker service..."
        systemctl unmask docker.service >/dev/null 2>&1 || true
        systemctl unmask docker.socket >/dev/null 2>&1 || true
    fi
}

info "Configuring Docker registry mirrors..."
mkdir -p /etc/docker
cat > /etc/docker/daemon.json <<JSON
{
  "registry-mirrors": [
    "$PRIMARY_MIRROR",
    "https://docker.arvancloud.ir",
    "https://mirror2.chabokan.net",
    "https://docker.abrha.net",
    "https://docker.1ms.run",
    "https://docker.m.daocloud.io",
    "https://dockerproxy.net",
    "https://docker.1panel.live",
    "https://mirrors.ustc.edu.cn",
    "https://hub-mirror.c.163.com",
    "https://registry.hub.docker.com"
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

success "Docker registry mirrors have been updated!"
info "Primary Mirror: $PRIMARY_MIRROR"
