#!/bin/bash

# Docker Mirror Configuration Script by Movti Group
# Updated with broader registry mirror support for international and Chinese nodes.
# Optimized for Iranian users.

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PLAIN='\033[0m'

if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}لطفاً این اسکریپت را با دسترسی root اجرا کنید (sudo).${PLAIN}"
    exit 1
fi

PRIMARY_MIRROR="https://docker.ththt.ir"

unmask_docker() {
    if command -v systemctl >/dev/null 2>&1; then
        echo -e "${YELLOW}در حال لغو محدودیت (Unmask) سرویس داکر...${PLAIN}"
        systemctl unmask docker.service >/dev/null 2>&1 || true
        systemctl unmask docker.socket >/dev/null 2>&1 || true
    fi
}

echo -e "${YELLOW}در حال تنظیم آینه‌های ریجستری داکر (Registry Mirrors)...${PLAIN}"
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

echo -e "${GREEN}آینه‌های ریجستری داکر با موفقیت بروزرسانی شدند!${PLAIN}"
echo -e "${BLUE}آینه‌ی اصلی: $PRIMARY_MIRROR${PLAIN}"
