#!/bin/bash
# Complete XMRig CUDA Mining Setup for Ubuntu
# Usage: sudo bash install_complete_setup.sh

set -eo pipefail

echo "🚀 Installing Docker + NVIDIA + XMRig Mining Setup..."

# System updates
apt update && apt install -y ca-certificates curl gnupg lsb-release wget git build-essential cmake

# Docker installation
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt update && apt install -y docker-ce docker-ce-cli containerd.io

# DNS fix for cloud VMs
echo '{"dns": ["8.8.8.8", "8.8.4.4"]}' > /etc/docker/daemon.json

# NVIDIA CUDA Toolkit
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.1-1_all.deb
dpkg -i cuda-keyring_1.1-1_all.deb && rm -f cuda-keyring_1.1-1_all.deb
apt update && apt install -y cuda-toolkit

# NVIDIA Container Toolkit
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
  sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
  tee /etc/apt/sources.list.d/nvidia-container-toolkit.list > /dev/null
apt update && apt install -y nvidia-container-toolkit

# Configure and restart
nvidia-ctk runtime configure --runtime=docker
systemctl restart docker
usermod -aG docker $SUDO_USER

echo "✅ Installation complete. Testing NVIDIA integration..."
docker run --rm --gpus all nvidia/cuda:12.3-base-ubuntu22.04 nvidia-smi

echo "🎯 Ready for mining! Reboot required for full functionality."
