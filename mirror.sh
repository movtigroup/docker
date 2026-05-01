# Add manageit.ir docker mirror
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
EOF

docker logout
sudo systemctl restart docker
