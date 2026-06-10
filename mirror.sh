#!/bin/bash

# اسکریپت تنظیم میرور داکر توسط Movti Group
# بهینه‌شده برای دور زدن محدودیت‌های Docker Hub در ایران

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PLAIN='\033[0m'

if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}خطا: لطفا اسکریپت را با دسترسی روت اجرا کنید.${PLAIN}"
    exit 1
fi

PRIMARY_MIRROR="https://docker.ththt.ir"

echo -e "${YELLOW}در حال تنظیم میرورهای داکر برای دور زدن تحریم‌ها...${PLAIN}"
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
    echo -e "${YELLOW}در حال بازنشانی سرویس داکر...${PLAIN}"
    systemctl unmask docker.service docker.socket >/dev/null 2>&1 || true
    systemctl daemon-reload
    systemctl restart docker || true
else
    service docker restart || true
fi

echo -e "${GREEN}میرورهای داکر با موفقیت بروزرسانی شدند.${PLAIN}"
echo -e "${BLUE}میرور فعال: $PRIMARY_MIRROR${PLAIN}"
