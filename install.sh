#!/bin/bash

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

# Robust apt-get update with lock handling
safe_apt_update() {
    local count=0
    while [ $count -lt 20 ]; do
        if apt-get update; then
            return 0
        fi
        warn "APT is locked or update failed, retrying in 10 seconds ($((count+1))/20)..."
        sleep 10
        count=$((count + 1))
    done
    error "APT update failed after multiple retries."
    return 1
}

safe_apt_install() {
    local count=0
    while [ $count -lt 10 ]; do
        if apt-get install -y "$@"; then
            return 0
        fi
        warn "APT is locked or install failed, retrying in 10 seconds ($((count+1))/10)..."
        sleep 10
        count=$((count + 1))
    done
    error "APT install failed: $*"
    return 1
}

# Check root access
if [ "$(id -u)" -ne 0 ]; then
    error "Please run as root (sudo)."
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
    error "Unsupported system: /etc/os-release not found."
    exit 1
fi

info "Detected OS: $OS ($VERSION_CODENAME)"

PRIMARY_MIRROR="https://docker.ththt.ir"

unmask_docker() {
    if command -v systemctl >/dev/null 2>&1; then
        warn "Unmasking Docker service..."
        systemctl unmask docker.service >/dev/null 2>&1 || true
        systemctl unmask docker.socket >/dev/null 2>&1 || true
    fi
}

config_registry_mirror() {
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
}

case "$OS" in
    ubuntu|debian|raspbian|linuxmint)
        info "Installing prerequisites for $OS..."
        safe_apt_update
        safe_apt_install ca-certificates curl gnupg lsb-release

        warn "Removing old versions and conflicting sources..."
        for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
            apt-get remove -y "$pkg" >/dev/null 2>&1
        done

        # Aggressive cleanup of conflicting sources
        rm -f /etc/apt/sources.list.d/docker.list /etc/apt/sources.list.d/archive_uri*.list
        grep -lR "runflare.run\|docker.com" /etc/apt/sources.list.d/ 2>/dev/null | xargs rm -f 2>/dev/null || true
        if [ -f /etc/apt/sources.list ]; then
            sed -i '/runflare.run\|docker.com/d' /etc/apt/sources.list
        fi

        INSTALL_SUCCESS=false

        # 1. Movti Mirror (Priority for Iran)
        info "Trying Movti mirror (Iran priority)..."
        REPO_URL="http://movti.runflare.run/ubuntu"
        [ "$OS" = "debian" ] && REPO_URL="http://movti.runflare.run/debian"
        [ "$OS" = "raspbian" ] && REPO_URL="http://movti.runflare.run/raspbian"

        echo "deb [arch=$(dpkg --print-architecture) trusted=yes] $REPO_URL $VERSION_CODENAME stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
        if safe_apt_update && safe_apt_install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin; then
            INSTALL_SUCCESS=true
        fi

        # 2. Official Docker Repository (Fallback)
        if [ "$INSTALL_SUCCESS" = "false" ]; then
            warn "Movti mirror failed. Trying official Docker repository..."
            REPO_BASE="https://download.docker.com/linux/ubuntu"
            [ "$OS" = "debian" ] && REPO_BASE="https://download.docker.com/linux/debian"
            [ "$OS" = "raspbian" ] && REPO_BASE="https://download.docker.com/linux/raspbian"

            mkdir -p /etc/apt/keyrings
            if curl -fsSL "$REPO_BASE/gpg" -o /etc/apt/keyrings/docker.asc; then
                chmod a+r /etc/apt/keyrings/docker.asc
                echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] $REPO_BASE $VERSION_CODENAME stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
                if safe_apt_update && safe_apt_install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin; then
                    INSTALL_SUCCESS=true
                fi
            fi
        fi

        # 3. Aliyun Mirror (China Fallback)
        if [ "$INSTALL_SUCCESS" = "false" ]; then
            warn "Trying Aliyun mirror..."
            ALIYUN_BASE="https://mirrors.aliyun.com/docker-ce/linux/ubuntu"
            [ "$OS" = "debian" ] && ALIYUN_BASE="https://mirrors.aliyun.com/docker-ce/linux/debian"

            if curl -fsSL "$ALIYUN_BASE/gpg" | gpg --dearmor -o /etc/apt/keyrings/docker-aliyun.gpg --yes; then
                echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker-aliyun.gpg] $ALIYUN_BASE $VERSION_CODENAME stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
                if safe_apt_update && safe_apt_install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin; then
                    INSTALL_SUCCESS=true
                fi
            fi
        fi

        if [ "$INSTALL_SUCCESS" = "false" ]; then
            error "Installation from repositories failed. Trying official install script..."
            rm -f /etc/apt/sources.list.d/docker.list
            safe_apt_update
            curl -fsSL https://get.docker.com | sh
        fi
        ;;
    centos|rhel|fedora|rocky|almalinux)
        info "Preparing for $OS..."
        yum remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine >/dev/null 2>&1
        yum install -y yum-utils
        rm -f /etc/yum.repos.d/*docker-ce.repo

        INSTALL_SUCCESS=false

        # 1. Movti (Priority)
        info "Trying Movti repository..."
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
            warn "Trying official repository..."
            REPO_URL="https://download.docker.com/linux/centos/docker-ce.repo"
            [ "$OS" = "fedora" ] && REPO_URL="https://download.docker.com/linux/fedora/docker-ce.repo"
            if yum-config-manager --add-repo "$REPO_URL"; then
                if yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin; then
                    INSTALL_SUCCESS=true
                fi
            fi
        fi

        if [ "$INSTALL_SUCCESS" = "false" ]; then
            error "Installation failed. Trying generic method..."
            curl -fsSL https://get.docker.com | sh
        fi
        unmask_docker
        systemctl enable --now docker || true
        ;;
    *)
        error "OS $OS is not fully supported. Trying generic installation..."
        curl -fsSL https://get.docker.com | sh
        ;;
esac

config_registry_mirror

success "Docker installation and configuration completed!"
info "Primary Mirror: $PRIMARY_MIRROR"

# Final Status Check
if command -v docker >/dev/null 2>&1; then
    success "Docker version installed:"
    docker --version
    if systemctl is-active --quiet docker; then
        success "Docker service is running."
    else
        warn "Docker service is stopped. Attempting to start..."
        systemctl start docker || true
    fi
else
    error "Error: Docker was not installed correctly."
fi

# Quick Guide
info "--- Docker Quick Guide ---"
info "To run a test container:"
info "  docker run hello-world"
info "To view running containers:"
info "  docker ps"
info "To view all images:"
info "  docker images"
info "------------------------"
