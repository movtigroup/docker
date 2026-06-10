#!/bin/bash

# Docker Installation Script by Movti Group
# Optimized for Iranian users and bypassing restrictions
# Inspired by SuperManito/LinuxMirrors

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PLAIN='\033[0m'

# Check for root
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}خطا: لطفا اسکریپت را با دسترسی روت (sudo) اجرا کنید.${PLAIN}"
    exit 1
fi

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    V_CODENAME=$VERSION_CODENAME
    if [ -z "$V_CODENAME" ]; then
        V_CODENAME=$(echo "$VERSION_ID" | cut -d. -f1)
    fi
else
    echo -e "${RED}خطا: سیستم‌عامل شناسایی نشد.${PLAIN}"
    exit 1
fi

echo -e "${BLUE}سیستم‌عامل شناسایی شده: $OS ($V_CODENAME)${PLAIN}"

PRIMARY_MIRROR="https://docker.ththt.ir"
MOVTI_REPO="http://movti.runflare.run"

cleanup() {
    echo -e "${YELLOW}در حال پاکسازی تنظیمات قبلی برای جلوگیری از تداخل...${PLAIN}"
    rm -f /etc/apt/sources.list.d/docker.list
    rm -f /etc/apt/sources.list.d/archive_uri*.list
    rm -f /etc/apt/keyrings/docker.asc
    rm -f /etc/apt/keyrings/docker-*.gpg
    rm -f /etc/yum.repos.d/*docker-ce.repo
}

configure_mirrors() {
    echo -e "${YELLOW}در حال تنظیم میرورهای داکر...${PLAIN}"
    mkdir -p /etc/docker
    cat > /etc/docker/daemon.json <<JSON
{
  "registry-mirrors": [
    "$PRIMARY_MIRROR",
    "https://docker.arvancloud.ir",
    "https://mirror2.chabokan.net",
    "https://docker.abrha.net",
    "https://docker.1ms.run",
    "https://registry.hub.docker.com"
  ]
}
JSON
    if command -v systemctl >/dev/null 2>&1; then
        systemctl unmask docker.service >/dev/null 2>&1 || true
        systemctl unmask docker.socket >/dev/null 2>&1 || true
        systemctl daemon-reload
        systemctl restart docker || true
    else
        service docker restart || true
    fi
}

cleanup

case "$OS" in
    ubuntu|debian|raspbian|linuxmint)
        echo -e "${YELLOW}در حال آماده‌سازی پکیج‌های مورد نیاز...${PLAIN}"
        apt-get update
        apt-get install -y ca-certificates curl gnupg lsb-release

        echo -e "${YELLOW}حذف نسخه‌های قدیمی داکر...${PLAIN}"
        for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
            apt-get remove -y "$pkg" >/dev/null 2>&1
        done

        SUCCESS=false

        # Try Movti Repo
        echo -e "${YELLOW}در حال نصب داکر از مخزن اختصاصی Movti...${PLAIN}"
        R_PATH="ubuntu"
        [[ "$OS" == "debian" ]] && R_PATH="debian"
        [[ "$OS" == "raspbian" ]] && R_PATH="raspbian"

        echo "deb [arch=$(dpkg --print-architecture) trusted=yes] $MOVTI_REPO/$R_PATH $V_CODENAME stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

        if apt-get update && apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin; then
            SUCCESS=true
        fi

        if [ "$SUCCESS" = "false" ]; then
            echo -e "${RED}نصب از مخزن Movti با شکست مواجه شد. در حال تلاش برای نصب عمومی...${PLAIN}"
            rm -f /etc/apt/sources.list.d/docker.list
            apt-get update
            curl -fsSL https://get.docker.com | bash
        fi
        ;;
    centos|rhel|fedora|rocky|almalinux)
        echo -e "${YELLOW}حذف نسخه‌های قدیمی داکر...${PLAIN}"
        yum remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine >/dev/null 2>&1
        yum install -y yum-utils

        SUCCESS=false
        R_PATH="centos"
        [[ "$OS" == "fedora" ]] && R_PATH="fedora"

        echo -e "${YELLOW}در حال اضافه کردن مخزن داکر...${PLAIN}"
        if yum-config-manager --add-repo "$MOVTI_REPO/$R_PATH/docker-ce.repo"; then
            find /etc/yum.repos.d/ -name "*docker-ce.repo" -exec sed -i "s/gpgcheck=1/gpgcheck=0/g" {} +
            if yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin; then
                SUCCESS=true
            fi
        fi

        if [ "$SUCCESS" = "false" ]; then
            echo -e "${RED}نصب با شکست مواجه شد. در حال تلاش برای نصب عمومی...${PLAIN}"
            curl -fsSL https://get.docker.com | bash
        fi
        systemctl enable --now docker || true
        ;;
    arch)
        echo -e "${YELLOW}در حال نصب داکر برای آرچ لینوکس...${PLAIN}"
        pacman -Syu --noconfirm docker docker-compose
        systemctl enable --now docker || true
        ;;
    *)
        echo -e "${YELLOW}در حال تلاش برای نصب عمومی روی سیستم‌عامل $OS...${PLAIN}"
        curl -fsSL https://get.docker.com | bash
        ;;
esac

configure_mirrors

echo -e "${GREEN}نصب و پیکربندی داکر با موفقیت انجام شد.${PLAIN}"
echo -e "${BLUE}Movti Group - Docker Mirror${PLAIN}"
