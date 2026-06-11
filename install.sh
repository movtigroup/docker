#!/bin/bash

# Docker Installation Script by Movti Group
# Highly robust version with APT lock handling and aggressive conflict resolution.

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

# Function to wait for APT lock
wait_for_apt_lock() {
    local count=0
    while [ $count -lt 60 ]; do
        if ! fuser /var/lib/apt/lists/lock >/dev/null 2>&1 && ! fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 ; then
            return 0
        fi
        warn "APT is locked by another process. Waiting... ($((count+1))/60)"
        sleep 5
        count=$((count + 1))
    done
    warn "APT lock still held after 5 minutes. Proceeding with caution..."
}

# Robust apt-get update with retry logic
safe_apt_update() {
    local count=0
    while [ $count -lt 10 ]; do
        wait_for_apt_lock
        if apt-get update; then
            return 0
        fi
        warn "APT update failed, retrying in 10 seconds ($((count+1))/10)..."
        sleep 10
        count=$((count + 1))
    done
    return 1
}

# Robust apt-get install with retry logic
safe_apt_install() {
    local count=0
    while [ $count -lt 5 ]; do
        wait_for_apt_lock
        if apt-get install -y "$@"; then
            return 0
        fi
        warn "APT install failed, retrying in 10 seconds ($((count+1))/5)..."
        sleep 10
        count=$((count + 1))
    done
    return 1
}

# Help menu
show_help() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -h, --help      Show this help message"
    echo "  -r, --remove    Completely remove Docker and old components"
    echo ""
    echo "Description:"
    echo "This script installs Docker prioritizing Iranian mirrors (Abrha and Movti)."
}

# Remove Docker function
remove_docker() {
    if [ "$(id -u)" -ne 0 ]; then
        error "Please run as root (sudo) to remove packages."
        exit 1
    fi
    info "Removing Docker and related packages..."
    # Detect OS if not already detected
    if [ -z "$OS" ]; then
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            OS=$ID
        fi
    fi
    case "$OS" in
        ubuntu|debian|raspbian|linuxmint)
            local pkgs=$(dpkg --get-selections docker.io docker-compose docker-compose-v2 docker-doc podman-docker containerd runc 2>/dev/null | cut -f1)
            if [ -n "$pkgs" ]; then
                apt-get remove -y $pkgs
                apt-get autoremove -y
            else
                info "No old Docker packages found to remove."
            fi
            ;;
        centos|rhel|fedora|rocky|almalinux)
            yum remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine
            ;;
        *)
            error "Automatic removal not supported for $OS."
            ;;
    esac
    success "Removal process completed."
}

# Argument parsing
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -r|--remove)
            remove_docker
            exit 0
            ;;
        *)
            error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Check root access for installation
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
        info "Cleaning up conflicting APT sources..."
        [ -f /etc/apt/sources.list ] && sed -i '/abrha.net\|runflare.run\|docker.com\|aliyun.com\/docker-ce\|tencent.com\/docker-ce/d' /etc/apt/sources.list

        for f in /etc/apt/sources.list.d/*.list /etc/apt/sources.list.d/*.sources; do
            if [ -f "$f" ]; then
                if grep -qi "abrha.net\|runflare.run\|docker.com\|aliyun.com\|tencent.com" "$f"; then
                    warn "Removing conflicting source file: $f"
                    rm -f "$f"
                fi
            fi
        done

        info "Installing prerequisites for $OS..."
        safe_apt_update
        safe_apt_install ca-certificates curl gnupg lsb-release

        INSTALL_SUCCESS=false

        # 1. Abrha Mirror (Primary Priority for Ubuntu)
        if [ "$OS" = "ubuntu" ]; then
            info "Trying Abrha mirror (Primary Priority for Ubuntu)..."
            install -m 0755 -d /etc/apt/keyrings
            if curl -fsSL https://repo.abrha.net/docker/ubuntu/gpg -o /etc/apt/keyrings/docker.asc; then
                chmod a+r /etc/apt/keyrings/docker.asc
                printf '%s\n' \
                "Types: deb" \
                "URIs: https://repo.abrha.net/docker/ubuntu" \
                "Suites: ${UBUNTU_CODENAME:-$VERSION_CODENAME}" \
                "Components: stable" \
                "Architectures: $(dpkg --print-architecture)" \
                "Signed-By: /etc/apt/keyrings/docker.asc" | tee /etc/apt/sources.list.d/docker.sources > /dev/null

                if safe_apt_update && safe_apt_install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin; then
                    INSTALL_SUCCESS=true
                fi
            fi
        fi

        # 2. Movti Mirror (Fallback or Default for others)
        if [ "$INSTALL_SUCCESS" = "false" ]; then
            info "Trying Movti mirror..."
            REPO_URL="http://movti.runflare.run/ubuntu"
            [ "$OS" = "debian" ] && REPO_URL="http://movti.runflare.run/debian"
            [ "$OS" = "raspbian" ] && REPO_URL="http://movti.runflare.run/raspbian"

            rm -f /etc/apt/sources.list.d/docker.list
            echo "deb [arch=$(dpkg --print-architecture) trusted=yes] $REPO_URL $VERSION_CODENAME stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

            if safe_apt_update && safe_apt_install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin; then
                INSTALL_SUCCESS=true
            fi
        fi

        # 3. Official Docker Repository (Fallback)
        if [ "$INSTALL_SUCCESS" = "false" ]; then
            warn "Mirrors failed. Trying official Docker repository..."
            rm -f /etc/apt/sources.list.d/docker.list
            REPO_BASE="https://download.docker.com/linux/ubuntu"
            [ "$OS" = "debian" ] && REPO_BASE="https://download.docker.com/linux/debian"
            [ "$OS" = "raspbian" ] && REPO_BASE="https://download.docker.com/linux/raspbian"

            install -m 0755 -d /etc/apt/keyrings
            if curl -fsSL "$REPO_BASE/gpg" -o /etc/apt/keyrings/docker.asc; then
                chmod a+r /etc/apt/keyrings/docker.asc
                echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] $REPO_BASE $VERSION_CODENAME stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
                if safe_apt_update && safe_apt_install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin; then
                    INSTALL_SUCCESS=true
                fi
            fi
        fi

        # 4. Aliyun Mirror (Fallback)
        if [ "$INSTALL_SUCCESS" = "false" ]; then
            warn "Trying Aliyun mirror..."
            rm -f /etc/apt/sources.list.d/docker.list
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
