#!/bin/bash

# Docker Installation Script by Movti Group
# Improved with multi-distro support, fallback repository logic, and better cleanup.
# Optimized for Iranian users.

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PLAIN='\033[0m'

# بررسی دسترسی روت (Root Access Check)
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}لطفاً این اسکریپت را با دسترسی root اجرا کنید (sudo).${PLAIN}"
    exit 1
fi

# شناسایی سیستم‌عامل (OS Detection)
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    if [ -z "$VERSION_CODENAME" ]; then
        VERSION_CODENAME=$(echo "$VERSION_ID" | cut -d. -f1)
    fi
else
    echo -e "${RED}سیستم‌عامل پشتیبانی نمی‌شود: فایل /etc/os-release یافت نشد.${PLAIN}"
    exit 1
fi

echo -e "${BLUE}سیستم‌عامل شناسایی شده: $OS ($VERSION_CODENAME)${PLAIN}"

PRIMARY_MIRROR="https://docker.ththt.ir"

unmask_docker() {
    if command -v systemctl >/dev/null 2>&1; then
        echo -e "${YELLOW}در حال لغو محدودیت (Unmask) سرویس داکر...${PLAIN}"
        systemctl unmask docker.service >/dev/null 2>&1 || true
        systemctl unmask docker.socket >/dev/null 2>&1 || true
    fi
}

config_registry_mirror() {
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
}

case "$OS" in
    ubuntu|debian|raspbian|linuxmint)
        echo -e "${YELLOW}در حال نصب پیش‌نیازها برای $OS...${PLAIN}"
        apt-get update
        apt-get install -y ca-certificates curl gnupg lsb-release

        echo -e "${YELLOW}پاکسازی نسخه‌های قدیمی و تداخل‌ها...${PLAIN}"
        for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
            apt-get remove -y "$pkg" >/dev/null 2>&1
        done
        # حذف فایل‌های مخزن قدیمی برای جلوگیری از تداخل
        rm -f /etc/apt/sources.list.d/docker.list /etc/apt/sources.list.d/archive_uri*.list

        INSTALL_SUCCESS=false

        # 1. Movti Mirror (Priority for Iran)
        echo -e "${YELLOW}تلاش برای نصب از طریق آینه‌ی Movti (اولویت ایران)...${PLAIN}"
        REPO_URL="http://movti.runflare.run/ubuntu"
        [ "$OS" = "debian" ] && REPO_URL="http://movti.runflare.run/debian"
        [ "$OS" = "raspbian" ] && REPO_URL="http://movti.runflare.run/raspbian"

        echo "deb [arch=$(dpkg --print-architecture) trusted=yes] $REPO_URL $VERSION_CODENAME stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
        if apt-get update && apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin; then
            INSTALL_SUCCESS=true
        fi

        # 2. Official Docker Repository (Fallback)
        if [ "$INSTALL_SUCCESS" = "false" ]; then
            echo -e "${YELLOW}آینه‌ی Movti ناموفق بود. تلاش برای مخزن رسمی داکر...${PLAIN}"
            REPO_BASE="https://download.docker.com/linux/ubuntu"
            [ "$OS" = "debian" ] && REPO_BASE="https://download.docker.com/linux/debian"
            [ "$OS" = "raspbian" ] && REPO_BASE="https://download.docker.com/linux/raspbian"

            mkdir -p /etc/apt/keyrings
            if curl -fsSL "$REPO_BASE/gpg" -o /etc/apt/keyrings/docker.asc; then
                chmod a+r /etc/apt/keyrings/docker.asc
                echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] $REPO_BASE $VERSION_CODENAME stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
                if apt-get update && apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin; then
                    INSTALL_SUCCESS=true
                fi
            fi
        fi

        # 3. Aliyun Mirror (China Fallback)
        if [ "$INSTALL_SUCCESS" = "false" ]; then
            echo -e "${YELLOW}تلاش برای استفاده از آینه‌ی Aliyun...${PLAIN}"
            ALIYUN_BASE="https://mirrors.aliyun.com/docker-ce/linux/ubuntu"
            [ "$OS" = "debian" ] && ALIYUN_BASE="https://mirrors.aliyun.com/docker-ce/linux/debian"

            if curl -fsSL "$ALIYUN_BASE/gpg" | gpg --dearmor -o /etc/apt/keyrings/docker-aliyun.gpg --yes; then
                echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker-aliyun.gpg] $ALIYUN_BASE $VERSION_CODENAME stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
                if apt-get update && apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin; then
                    INSTALL_SUCCESS=true
                fi
            fi
        fi

        if [ "$INSTALL_SUCCESS" = "false" ]; then
            echo -e "${RED}نصب از مخازن با خطا مواجه شد. در حال تلاش برای نصب از طریق اسکریپت رسمی...${PLAIN}"
            rm -f /etc/apt/sources.list.d/docker.list
            apt-get update
            curl -fsSL https://get.docker.com | sh
        fi
        ;;
    centos|rhel|fedora|rocky|almalinux)
        echo -e "${YELLOW}در حال آماده‌سازی برای $OS...${PLAIN}"
        yum remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine >/dev/null 2>&1
        yum install -y yum-utils
        rm -f /etc/yum.repos.d/*docker-ce.repo

        INSTALL_SUCCESS=false

        # 1. Movti (Priority)
        echo -e "${YELLOW}تلاش برای مخزن Movti...${PLAIN}"
        MIRROR_REPO="http://movti.runflare.run/centos/docker-ce.repo"
        [ "$OS" = "fedora" ] && MIRROR_REPO="http://movti.runflare.run/fedora/docker-ce.repo"

        if yum-config-manager --add-repo "$MIRROR_REPO"; then
            find /etc/yum.repos.d/ -name "*docker-ce.repo" -exec sed -i 's/gpgcheck=1/gpgcheck=0/g' {} +
            if yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin; then
                INSTALL_SUCCESS=true
            fi
        fi

        # 2. Official
        if [ "$INSTALL_SUCCESS" = "false" ]; then
            echo -e "${YELLOW}تلاش برای مخزن رسمی...${PLAIN}"
            REPO_URL="https://download.docker.com/linux/centos/docker-ce.repo"
            [ "$OS" = "fedora" ] && REPO_URL="https://download.docker.com/linux/fedora/docker-ce.repo"
            if yum-config-manager --add-repo "$REPO_URL"; then
                if yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin; then
                    INSTALL_SUCCESS=true
                fi
            fi
        fi

        if [ "$INSTALL_SUCCESS" = "false" ]; then
            echo -e "${RED}نصب ناموفق بود. در حال تلاش برای روش عمومی...${PLAIN}"
            curl -fsSL https://get.docker.com | sh
        fi
        unmask_docker
        systemctl enable --now docker || true
        ;;
    *)
        echo -e "${RED}سیستم‌عامل $OS به طور کامل پشتیبانی نمی‌شود. تلاش برای نصب عمومی...${PLAIN}"
        curl -fsSL https://get.docker.com | sh
        ;;
esac

config_registry_mirror

echo -e "${GREEN}نصب و تنظیمات داکر با موفقیت انجام شد!${PLAIN}"
echo -e "${BLUE}آینه‌ی اصلی: $PRIMARY_MIRROR${PLAIN}"

# بررسی وضعیت نهایی (Final Status Check)
if command -v docker >/dev/null 2>&1; then
    echo -e "${GREEN}نسخه داکر نصب شده:${PLAIN}"
    docker --version
    if systemctl is-active --quiet docker; then
        echo -e "${GREEN}سرویس داکر در حال اجرا است.${PLAIN}"
    else
        echo -e "${RED}سرویس داکر متوقف است. در حال تلاش برای شروع...${PLAIN}"
        systemctl start docker || true
    fi
else
    echo -e "${RED}خطا: داکر به درستی نصب نشده است.${PLAIN}"
fi

# راهنمای سریع داکر (Quick Guide)
echo -e "${BLUE}--- راهنمای سریع داکر ---${PLAIN}"
echo -e "برای اجرای یک کانتینر تست:"
echo -e "  ${YELLOW}docker run hello-world${PLAIN}"
echo -e "برای مشاهده کانتینرهای در حال اجرا:"
echo -e "  ${YELLOW}docker ps${PLAIN}"
echo -e "برای مشاهده تمام ایمیج‌ها:"
echo -e "  ${YELLOW}docker images${PLAIN}"
echo -e "------------------------"
