#!/bin/bash

# XMRig CUDA Mining - One Command Setup
# Usage: ./mine.sh POOL_URL WALLET_ADDRESS [WORKER_NAME]

if [ $# -lt 2 ]; then
    echo "❌ Missing required parameters!"
    echo ""
    echo "Usage: ./mine.sh POOL_URL WALLET_ADDRESS [WORKER_NAME]"
    echo ""
    echo "Examples:"
    echo "  MiningRigRentals: ./mine.sh stratum+tcp://us-east.rentals.nicehash.com:3333 wallet.worker1"
    echo "  Standard pool:    ./mine.sh pool.supportxmr.com:443 wallet_address worker1"
    exit 1
fi

POOL_URL="$1"
WALLET_ADDRESS="$2"
WORKER_NAME="${3:-$(hostname)}"

echo "🚀 Starting XMRig CUDA Miner..."
echo "Pool: $POOL_URL"
echo "Wallet: $WALLET_ADDRESS"
echo "Worker: $WORKER_NAME"
echo ""

# Check NVIDIA runtime
if docker info 2>/dev/null | grep -q nvidia; then
    GPU_ARGS="--gpus all"
    echo "✅ NVIDIA GPU support detected"
else
    GPU_ARGS=""
    echo "⚠️  No GPU support - CPU mining only"
fi

# Check if image exists
if ! docker image inspect xmrig-cuda-miner >/dev/null 2>&1; then
    echo "📦 Building Docker image..."
    ./build.sh || exit 1
fi

# Create logs directory
mkdir -p logs

# Run mining container
docker run --rm $GPU_ARGS \
    -e POOL_URL="$POOL_URL" \
    -e WALLET_ADDRESS="$WALLET_ADDRESS" \
    -e WORKER_NAME="$WORKER_NAME" \
    -v "$(pwd)/logs:/mining" \
    --name xmrig-miner \
    xmrig-cuda-miner
