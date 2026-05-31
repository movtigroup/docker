#!/bin/bash

# Docker Installation Script by Movti Group
# Improved with multi-distro support and insecure (no-key) repository support.

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PLAIN='\033[0m'

# Check if root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Please run as root${PLAIN}"
    exit 1
fi

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    if [ -z "$VERSION_CODENAME" ]; then
        VERSION_CODENAME=$(echo $VERSION_ID | cut -d. -f1)
    fi
else
    echo -e "${RED}Unsupported system: /etc/os-release not found.${PLAIN}"
    exit 1
fi

echo -e "${BLUE}Detected OS: $OS ($VERSION_CODENAME)${PLAIN}"

PRIMARY_MIRROR="https://docker.ththt.ir"

config_registry_mirror() {
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
    if command -v systemctl >/dev/null 2>&1; then
        systemctl daemon-reload
        systemctl restart docker || true
    else
        service docker restart || true
    fi
}

case $OS in
    ubuntu|debian|raspbian|linuxmint)
        echo -e "${YELLOW}Installing Docker for $OS...${PLAIN}"
        apt-get update
        apt-get install -y ca-certificates curl gnupg lsb-release
        echo -e "${YELLOW}Removing old versions if any...${PLAIN}"
        for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do apt-get remove -y $pkg >/dev/null 2>&1; done
        REPO_URL="https://mirror2.chabokan.net/ubuntu/docker"
        [[ "$OS" == "debian" ]] && REPO_URL="https://mirror2.chabokan.net/debian/docker"
        [[ "$OS" == "raspbian" ]] && REPO_URL="https://mirror2.chabokan.net/raspbian/docker"
        echo -e "${YELLOW}Adding Docker repository (Insecure/No-Key mode)...${PLAIN}"
        echo "deb [arch=$(dpkg --print-architecture) trusted=yes] $REPO_URL $VERSION_CODENAME stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
        apt-get update
        apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        ;;
    centos|rhel|fedora|rocky|almalinux)
        echo -e "${YELLOW}Installing Docker for $OS...${PLAIN}"
        yum remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine >/dev/null 2>&1
        yum install -y yum-utils
        echo -e "${YELLOW}Adding Docker repository and disabling GPG check...${PLAIN}"
        if [[ "$OS" == "fedora" ]]; then
            yum-config-manager --add-repo https://mirror2.chabokan.net/fedora/docker-ce.repo
        else
            yum-config-manager --add-repo https://mirror2.chabokan.net/centos/docker-ce.repo
        fi
        find /etc/yum.repos.d/ -name "*docker-ce.repo" -exec sed -i 's/gpgcheck=1/gpgcheck=0/g' {} +
        yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        systemctl enable --now docker
        ;;
    arch)
        echo -e "${YELLOW}Installing Docker for Arch Linux...${PLAIN}"
        pacman -Syu --noconfirm docker docker-compose
        systemctl enable --now docker
        ;;
    *)
        echo -e "${RED}Unsupported OS: $OS. Attempting generic installation...${PLAIN}"
        curl -fsSL https://get.docker.com | sh
        ;;
esac

config_registry_mirror

echo -e "${GREEN}Docker installation and configuration completed!${PLAIN}"
echo -e "${BLUE}Primary Mirror: $PRIMARY_MIRROR${PLAIN}"
