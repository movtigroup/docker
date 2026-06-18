# 🐳 Docker 镜像仓库 - Movti Group

[![Status](https://img.shields.io/badge/status-active-success.svg)](https://github.com/movtigroup/docker)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![English](https://img.shields.io/badge/lang-English-red.svg)](README_EN.md)
[![Persian](https://img.shields.io/badge/lang-Persian-green.svg)](README.md)
[![Chinese](https://img.shields.io/badge/lang-Chinese-yellow.svg)](README_CN.md)

本仓库包含由 **Movti Group** 管理的**内部且及时更新的镜像**。旨在帮助用户在**无需 VPN** 的情况下安装和使用 Docker。所有 Docker 包和镜像均可通过缓存且稳定的服务器下载。

---

## 🚀 安装与设置

### 1. 自动安装（推荐大多数发行版使用）

此脚本会自动检测您的 Linux 发行版（Ubuntu, Debian, CentOS, Fedora, Arch 等），并使用最佳设置和内部镜像安装 Docker。它还使用 **Insecure/No-Key** 方法来绕过 GPG 密钥下载限制。

```bash
curl -fsSL https://raw.githubusercontent.com/movtigroup/docker/main/install.sh | sudo bash
```

### 2. 为已安装的 Docker 配置镜像

如果您已经安装了 Docker，只想添加 Movti Group 镜像以绕过限制，请使用此命令：

```bash
curl -fsSL https://raw.githubusercontent.com/movtigroup/docker/main/mirror.sh | sudo bash
```

此脚本会配置 `daemon.json` 文件并重启 Docker 服务。

### 3. Docker Desktop (Windows / macOS)

如果您在 Windows 或 macOS 上使用 **Docker Desktop**：
1. 打开 **Settings** (设置)。
2. 选择 **Docker Engine**。
3. 将以下文本粘贴到 `daemon.json` 文件的 `registry-mirrors` 数组中。
4. 点击 **Apply & Restart** (应用并重启)。

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

## 📡 可用镜像列表

| 镜像地址 | 用途 | 优先级 |
|----------|------|--------|
| `https://docker.ththt.ir` | 主要 Docker Hub 镜像 (新) | 1️⃣ |
| `https://docker.3cn.ir` | ththt.ir 的辅助镜像 | 1️⃣.5️⃣ |
| `https://docker.arvancloud.ir` | 备用镜像 | 2️⃣ |
| `https://mirror2.chabokan.net` | OS 包和备用镜像 | 3️⃣ |
| `https://docker.abrha.net` | 备用镜像 | 4️⃣ |

---

## 📚 功能特性

- **多发行版支持：** Ubuntu, Debian, CentOS, RHEL, Fedora, Arch Linux。
- **免密钥安装：** 解决 Docker 仓库 GPG 密钥下载失败的问题。
- **无需 DNS/VPN：** 所有步骤均可在内网环境下完成。

---

## 🐧 Alpine 镜像

Movti Group 还提供 **Alpine Linux 的最新镜像**。您可以在 Dockerfile 中或直接在 Alpine 系统上使用它。

### 从 Movti Group 镜像安装 Nginx 的 Dockerfile 示例（基于 Alpine）

```dockerfile
FROM alpine

# 添加 Movti Group 的 Alpine 镜像
RUN echo https://mirror.arvancloud.ir/alpine/v\$(echo \$(cat /etc/alpine-release) | awk -F . '{print \$1"."\$2}')/main > /etc/apk/repositories
RUN echo https://mirror.arvancloud.ir/alpine/v\$(echo \$(cat /etc/alpine-release) | awk -F . '{print \$1"."\$2}')/community >> /etc/apk/repositories

# 安装 Nginx (示例)
RUN apk update && apk add nginx

CMD nginx -g "daemon off;"
```

---

## 🐳 私有化部署 (Self-Hosting)

### 1. 使用 Docker Compose 启动
首先克隆仓库，然后运行：

```bash
docker compose up -d --build
```

### 2. 使用托管脚本
启动后，所有脚本将在您服务器的 **8004** 端口上可用：

- **自动安装：**
  ```bash
  curl -fsSL http://SERVER_IP:8004/docker.sh | sudo bash
  ```
  *(或 `install.sh`)*

- **配置镜像：**
  ```bash
  curl -fsSL http://SERVER_IP:8004/mirror.sh | sudo bash
  ```

- **其他脚本：**
  `ChangeMirrors.sh`, `DockerInstallation.sh`

*注意：请将 `SERVER_IP` 替换为您服务器s的 IP 地址。*

---

## 🤝 参与贡献

如果您有任何建议或改进，欢迎提交 Pull Request 或 Issue。

---

## 📜 许可证

本项目采用 MIT 许可证。
