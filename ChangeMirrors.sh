#!/bin/bash
## Author: Movti Group
## License: MIT
## GitHub: https://github.com/movtigroup/docker
## Description: اسکریپت جامع تغییر میرورهای توزیع‌های لینوکس برای ایران

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PLAIN='\033[0m'

# بررسی دسترسی روت
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}خطا: لطفا اسکریپت را با دسترسی روت اجرا کنید.${PLAIN}"
    exit 1
fi

# تشخیص توزیع
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo -e "${RED}خطا: سیستم‌عامل شناسایی نشد.${PLAIN}"
    exit 1
fi

echo -e "${BLUE}به اسکریپت تغییر میرور لینوکس خوش آمدید (نسخه ایران)${PLAIN}"
echo -e "${YELLOW}سیستم‌عامل شما: $OS${PLAIN}"

# نمایش منوی انتخاب میرور
echo -e "\n${GREEN}لطفا یک میرور را انتخاب کنید:${PLAIN}"
echo -e "1) ابر آروان (ArvanCloud)"
echo -e "2) ایران سرور (IranServer)"
echo -e "3) هوست ایران (HostIran)"
echo -e "4) دانشگاه صنعتی اصفهان (IUT)"
echo -e "5) پارس پک (ParsPack)"
echo -e "6) مخازن رسمی (Official)"

read -p "انتخاب شما [1-6]: " choice

case $choice in
    1) SOURCE="mirror.arvancloud.ir" ;;
    2) SOURCE="mirrors.iranserver.com" ;;
    3) SOURCE="mirrors.hostiran.ir" ;;
    4) SOURCE="repo.iut.ac.ir" ;;
    5) SOURCE="mirrors.parspack.com" ;;
    6) SOURCE="official" ;;
    *) echo "انتخاب نامعتبر"; exit 1 ;;
esac

# پشتیبان‌گیری
backup_file() {
    local file=$1
    if [ -f "$file" ]; then
        echo -e "${YELLOW}در حال پشتیبان‌گیری از $file...${PLAIN}"
        cp "$file" "${file}.bak_movti"
    fi
}

if [ "$SOURCE" == "official" ]; then
    echo -e "${YELLOW}در حال بازگردانی به مخازن رسمی...${PLAIN}"
    case "$OS" in
        ubuntu)
            backup_file "/etc/apt/sources.list"
            cat > /etc/apt/sources.list <<OFFICIAL
deb http://archive.ubuntu.com/ubuntu/ $VERSION_CODENAME main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ $VERSION_CODENAME-updates main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ $VERSION_CODENAME-backports main restricted universe multiverse
deb http://security.ubuntu.com/ubuntu/ $VERSION_CODENAME-security main restricted universe multiverse
OFFICIAL
            apt-get update
            ;;
        debian)
            backup_file "/etc/apt/sources.list"
            cat > /etc/apt/sources.list <<OFFICIAL
deb http://deb.debian.org/debian/ $VERSION_CODENAME main contrib non-free
deb http://deb.debian.org/debian/ $VERSION_CODENAME-updates main contrib non-free
deb http://security.debian.org/debian-security $VERSION_CODENAME-security main contrib non-free
OFFICIAL
            apt-get update
            ;;
        *)
            echo "بازگردانی خودکار برای این توزیع هنوز فعال نشده است."
            ;;
    esac
else
    echo -e "${YELLOW}در حال تغییر میرور به $SOURCE...${PLAIN}"
    case "$OS" in
        ubuntu|debian|raspbian|linuxmint)
            backup_file "/etc/apt/sources.list"
            # جایگزینی با روش امن‌تر
            sed -i "s|http://.*.ubuntu.com/ubuntu/|http://$SOURCE/ubuntu/|g" /etc/apt/sources.list
            sed -i "s|http://deb.debian.org/debian/|http://$SOURCE/debian/|g" /etc/apt/sources.list
            sed -i "s|http://security.debian.org/debian-security|http://$SOURCE/debian-security|g" /etc/apt/sources.list
            apt-get update
            ;;
        centos|rhel|fedora|rocky|almalinux)
            echo "پشتیبانی از سیستم‌های بر پایه RedHat در نسخه‌های بعدی اضافه خواهد شد."
            ;;
        *)
            echo "توزیع شما در حال حاضر پشتیبانی نمی‌شود."
            ;;
    esac
fi

echo -e "\n${GREEN}عملیات با موفقیت انجام شد.${PLAIN}"
echo -e "${BLUE}Movti Group - Linux Mirrors Iran${PLAIN}"
