FROM nvidia/cuda:12.3-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && apt-get install -y \
    git build-essential cmake libuv1-dev libssl-dev libhwloc-dev \
    && rm -rf /var/lib/apt/lists/*

# Build XMRig with CUDA
WORKDIR /tmp
RUN git clone https://github.com/xmrig/xmrig.git \
    && cd xmrig && mkdir build && cd build \
    && cmake .. -DWITH_CUDA=ON && make -j$(nproc) \
    && cp xmrig /usr/local/bin/ && cd / && rm -rf /tmp/xmrig

WORKDIR /mining

# Create entrypoint
RUN echo '#!/bin/bash\n\
if [ -z "$POOL_URL" ] || [ -z "$WALLET_ADDRESS" ]; then\n\
    echo "❌ Error: POOL_URL and WALLET_ADDRESS required"\n\
    echo "Usage: docker run --gpus all -e POOL_URL=pool -e WALLET_ADDRESS=wallet xmrig-cuda-miner"\n\
    exit 1\n\
fi\n\
WORKER_NAME=${WORKER_NAME:-$(hostname)}\n\
THREADS=${THREADS:-0}\n\
echo "🚀 Starting XMRig CUDA Miner"\n\
echo "Pool: $POOL_URL | Wallet: $WALLET_ADDRESS | Worker: $WORKER_NAME"\n\
exec xmrig --url="$POOL_URL" --user="$WALLET_ADDRESS" --pass="$WORKER_NAME" \\\n\
    --threads="$THREADS" --cuda --no-cpu --donate-level=1 \\\n\
    --log-file=/mining/xmrig.log "$@"' > /usr/local/bin/start-mining.sh \
    && chmod +x /usr/local/bin/start-mining.sh

ENTRYPOINT ["/usr/local/bin/start-mining.sh"]
