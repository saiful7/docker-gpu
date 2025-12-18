#!/bin/bash

echo "🔨 Building XMRig CUDA Mining Docker Image..."

# Check NVIDIA runtime
if ! docker info 2>/dev/null | grep -q nvidia; then
    echo "⚠️  NVIDIA Container Toolkit not detected"
    echo "Run: sudo bash install_complete_setup.sh"
    exit 1
fi

# Build image
docker build -t xmrig-cuda-miner . || {
    echo "❌ Build failed!"
    exit 1
}

echo "✅ Docker image built successfully!"
echo ""
echo "🚀 Ready to mine! Use:"
echo "./mine.sh POOL_URL WALLET_ADDRESS [WORKER_NAME]"
