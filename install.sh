#!/bin/bash

# حذف بسته‌های قدیمی
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove -y $pkg; done

sudo apt-get update
sudo apt-get install ca-certificates curl

sudo install -m 0755 -d /etc/apt/keyrings

# دریافت کلید از mirror اول (قابل استفاده برای همه‌ی مخازن)
sudo curl -fsSL https://mirror2.chabokan.net/ubuntu/docker/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# اضافه کردن مخزن اول (mirror2.chabokan.net)
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://mirror2.chabokan.net/ubuntu/docker \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# (اختیاری) اضافه کردن مخزن دوم (docker.abrha.net) - اگر وجود داشته باشد
# sudo tee /etc/apt/sources.list.d/docker2.list <<EOF
# deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://docker.abrha.net/ubuntu/docker $(. /etc/os-release && echo "$VERSION_CODENAME") stable
# EOF

sudo apt-get update

# نصب Docker
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# پیکربندی mirrorهای registry
cat > /etc/docker/daemon.json <<EOF
{
  "insecure-registries": [
    "https://docker.arvancloud.ir",
    "https://docker.abrha.net"
  ],
  "registry-mirrors": [
    "https://docker.arvancloud.ir",
    "https://mirror2.chabokan.net",
    "https://docker.abrha.net"
  ]
}
EOF

docker logout
sudo systemctl restart docker
