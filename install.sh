#!/bin/bash

# Docker Installation Script by Movti Group
# Improved with multi-distro support and fallback repository logic.

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
        VERSION_CODENAME=$(echo "$VERSION_ID" | cut -d. -f1)
    fi
else
    echo -e "${RED}Unsupported system: /etc/os-release not found.${PLAIN}"
    exit 1
fi

echo -e "${BLUE}Detected OS: $OS ($VERSION_CODENAME)${PLAIN}"

PRIMARY_MIRROR="https://docker.ththt.ir"

unmask_docker() {
    if command -v systemctl >/dev/null 2>&1; then
        echo -e "${YELLOW}Unmasking Docker service...${PLAIN}"
        systemctl unmask docker.service >/dev/null 2>&1 || true
        systemctl unmask docker.socket >/dev/null 2>&1 || true
    fi
}

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
        echo -e "${YELLOW}Installing Docker for $OS...${PLAIN}"
        apt-get update
        apt-get install -y ca-certificates curl gnupg lsb-release
        echo -e "${YELLOW}Removing old versions if any...${PLAIN}"
        for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
            apt-get remove -y "$pkg" >/dev/null 2>&1
        done

        INSTALL_SUCCESS=false

        # 1. Official Docker Repository
        echo -e "${YELLOW}Trying official Docker repository...${PLAIN}"
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

        if [ "$INSTALL_SUCCESS" = "false" ]; then
            # 2. Movti Mirror
            echo -e "${YELLOW}Official repo failed. Trying Movti mirror...${PLAIN}"
            REPO_URL="http://movti.runflare.run/ubuntu"
            [ "$OS" = "debian" ] && REPO_URL="http://movti.runflare.run/debian"
            [ "$OS" = "raspbian" ] && REPO_URL="http://movti.runflare.run/raspbian"

            echo "deb [arch=$(dpkg --print-architecture) trusted=yes] $REPO_URL $VERSION_CODENAME stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
            if apt-get update && apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin; then
                INSTALL_SUCCESS=true
            fi
        fi

        if [ "$INSTALL_SUCCESS" = "false" ]; then
            echo -e "${RED}Repository installation failed. Attempting generic installation...${PLAIN}"
            curl -fsSL https://get.docker.com | sh
        fi
        ;;
    centos|rhel|fedora|rocky|almalinux)
        echo -e "${YELLOW}Installing Docker for $OS...${PLAIN}"
        yum remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine >/dev/null 2>&1
        yum install -y yum-utils

        INSTALL_SUCCESS=false

        # 1. Official
        echo -e "${YELLOW}Adding official Docker repository...${PLAIN}"
        REPO_URL="https://download.docker.com/linux/centos/docker-ce.repo"
        [ "$OS" = "fedora" ] && REPO_URL="https://download.docker.com/linux/fedora/docker-ce.repo"

        if yum-config-manager --add-repo "$REPO_URL"; then
            if yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin; then
                INSTALL_SUCCESS=true
            fi
        fi

        if [ "$INSTALL_SUCCESS" = "false" ]; then
            # 2. Movti
            echo -e "${YELLOW}Official repo failed. Trying Movti mirror...${PLAIN}"
            MIRROR_REPO="http://movti.runflare.run/centos/docker-ce.repo"
            [ "$OS" = "fedora" ] && MIRROR_REPO="http://movti.runflare.run/fedora/docker-ce.repo"

            if yum-config-manager --add-repo "$MIRROR_REPO"; then
                find /etc/yum.repos.d/ -name "*docker-ce.repo" -exec sed -i 's/gpgcheck=1/gpgcheck=0/g' {} +
                if yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin; then
                    INSTALL_SUCCESS=true
                fi
            fi
        fi

        if [ "$INSTALL_SUCCESS" = "false" ]; then
            echo -e "${RED}Repository installation failed. Attempting generic installation...${PLAIN}"
            curl -fsSL https://get.docker.com | sh
        fi
        unmask_docker
        systemctl enable --now docker || true
        ;;
    arch)
        echo -e "${YELLOW}Installing Docker for Arch Linux...${PLAIN}"
        pacman -Syu --noconfirm docker docker-compose
        unmask_docker
        systemctl enable --now docker || true
        ;;
    *)
        echo -e "${RED}Unsupported OS: $OS. Attempting generic installation...${PLAIN}"
        curl -fsSL https://get.docker.com | sh
        ;;
esac

config_registry_mirror

echo -e "${GREEN}Docker installation and configuration completed!${PLAIN}"
echo -e "${BLUE}Primary Mirror: $PRIMARY_MIRROR${PLAIN}"
