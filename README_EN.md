# 🐳 Docker Mirror Repository by Movti Group

[![Status](https://img.shields.io/badge/status-active-success.svg)](https://github.com/movtigroup/docker)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![English](https://img.shields.io/badge/lang-English-red.svg)](README_EN.md)
[![Persian](https://img.shields.io/badge/lang-Persian-green.svg)](README.md)
[![Chinese](https://img.shields.io/badge/lang-Chinese-yellow.svg)](README_CN.md)

This repository contains scripts and configurations for installing and using Docker **without the need for VPN**, leveraging **internal and up-to-date mirrors** managed by **Movti Group**. All Docker packages and images are downloadable through cached and stable servers.

---

## 🚀 Installation & Setup

### 1. Automatic Installation (Recommended for most distributions)

This script automatically detects your Linux distribution (Ubuntu, Debian, CentOS, Fedora, Arch, etc.) and installs Docker with optimal settings and internal mirrors. It also uses the **Insecure/No-Key** method to bypass key retrieval restrictions.

```bash
curl -fsSL https://raw.githubusercontent.com/movtigroup/docker/main/install.sh | sudo bash
```

### 2. Configure Mirrors for Installed Docker

If you have already installed Docker and just want to add Movti Group mirrors to bypass sanctions, use this command:

```bash
curl -fsSL https://raw.githubusercontent.com/movtigroup/docker/main/mirror.sh | sudo bash
```

This script configures the `daemon.json` file with the mirrors below and restarts the Docker service.

### 3. Docker Desktop (Windows / macOS)

If you are using **Docker Desktop** on Windows or macOS:
1. Go to **Settings**.
2. Select **Docker Engine**.
3. Paste the following text into the `registry-mirrors` array in the `daemon.json` file.
4. Click **Apply & Restart**.

```json
{
  "registry-mirrors": [
    "https://docker.ththt.ir",
    "https://docker.3cn.ir",
    "https://docker.arvancloud.ir",
    "https://mirror2.chabokan.net",
    "https://docker.abrha.net"
  ]
}
```

---

## 📡 List of Available Mirrors

| Mirror Address | Usage | Priority |
|----------------|-------|----------|
| `https://docker.ththt.ir` | Primary Docker Hub mirror (New) | 1️⃣ |
| `https://docker.3cn.ir` | Helper mirror for ththt.ir | 1️⃣.5️⃣ |
| `https://docker.arvancloud.ir` | Backup mirror | 2️⃣ |
| `https://mirror2.chabokan.net` | OS packages & backup mirror | 3️⃣ |
| `https://docker.abrha.net` | Backup mirror | 4️⃣ |

---

## 📚 Features

- **Multi-Distribution Support:** Ubuntu, Debian, CentOS, RHEL, Fedora, Arch Linux.
- **No-Key Installation:** Solves issues with downloading GPG keys for Docker repositories.
- **No DNS/VPN Required:** All steps can be performed within the local network.

---

## 🐧 Alpine Mirror

Movti Group also provides an **up-to-date mirror for Alpine Linux**. You can use it in a Dockerfile or directly on an Alpine system.

### Sample Dockerfile for Installing Nginx from Movti Group Mirror (Alpine-based)

```dockerfile
FROM alpine

# Add Movti Group mirror for Alpine
RUN echo https://mirror.arvancloud.ir/alpine/v\$(echo \$(cat /etc/alpine-release) | awk -F . '{print \$1"."\$2}')/main > /etc/apk/repositories
RUN echo https://mirror.arvancloud.ir/alpine/v\$(echo \$(cat /etc/alpine-release) | awk -F . '{print \$1"."\$2}')/community >> /etc/apk/repositories

# Install Nginx (Example)
RUN apk update && apk add nginx

CMD nginx -g "daemon off;"
```

---

## 🐳 Self-Hosting

If you want to host these scripts on your own private server, you can use Docker:

### 1. Setup with Docker Compose
First clone the repository, then run:

```bash
docker compose up -d --build
```

### 2. Using the Hosted Script
Once running, the script will be available on port **8004** of your server. To install Docker from your own server:

```bash
curl -fsSL http://SERVER_IP:8004/docker.sh | sudo bash
```

*Note: Replace `SERVER_IP` with your server's IP address.*

---

## 🤝 Contributing

If you have suggestions or improvements, we would love to see your Pull Request. You can also open an issue.

---

## 📜 License

This project is released under the MIT License.
