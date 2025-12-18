# XMRig CUDA Mining Docker Solution

Complete Docker solution for XMRig CUDA mining on Ubuntu with automatic setup.

## 🚀 One-Command Setup & Mining

```bash
# 1. Install everything (requires sudo)
sudo bash install_complete_setup.sh

# 2. Reboot system  
sudo reboot

# 3. Start mining immediately
./mine.sh POOL_URL WALLET_ADDRESS [WORKER_NAME]
```

## 📋 Quick Examples

```bash
# MiningRigRentals.com
./mine.sh stratum+tcp://us-east.rentals.nicehash.com:3333 wallet.worker1

# Standard Monero pool
./mine.sh pool.supportxmr.com:443 your_wallet_address worker1
```

## 🔧 What's Included

- **NVIDIA CUDA 12.3** - Latest CUDA support with working base image
- **Docker Engine** - Latest version with GPU support
- **NVIDIA Container Toolkit** - GPU access for containers
- **XMRig CUDA** - Compiled with CUDA support
- **Auto-detection** - GPU/CPU fallback, automatic builds
- **Cloud VM fixes** - DNS configuration for reliable connections

## 📁 Complete File Set

- `install_complete_setup.sh` - Full system installation
- `Dockerfile` - Optimized CUDA mining container
- `build.sh` - Smart build with GPU detection
- `mine.sh` - Enhanced mining script with fallbacks
- `SETUP.md` - Detailed setup guide
- `logs/` - Mining logs directory (auto-created)

## ⚙️ Advanced Usage

### Environment Variables
- `POOL_URL` - Mining pool URL (required)
- `WALLET_ADDRESS` - Your wallet address (required)  
- `WORKER_NAME` - Worker identifier (optional, defaults to hostname)
- `THREADS` - Number of threads (optional, defaults to auto)

### Manual Docker Run
```bash
docker run --gpus all \
    -e POOL_URL="your_pool_url" \
    -e WALLET_ADDRESS="your_wallet" \
    -e WORKER_NAME="your_worker" \
    xmrig-cuda-miner
```

### View Logs
```bash
tail -f logs/xmrig.log
```

## 🛠️ System Requirements

- Ubuntu 20.04/22.04/24.04
- NVIDIA GPU with CUDA support
- Internet connection
- Sudo access for installation

## 🔍 Verification

```bash
# Check NVIDIA driver
nvidia-smi

# Test GPU Docker support
docker run --rm --gpus all nvidia/cuda:12.3-base-ubuntu22.04 nvidia-smi

# Verify mining setup
./build.sh
```

## 🎯 Features

✅ **Fixed CUDA base image** - Uses working nvidia/cuda:12.3-devel-ubuntu22.04  
✅ **Automatic GPU detection** - Falls back to CPU if no GPU  
✅ **Smart error handling** - Clear error messages and validation  
✅ **Cloud VM optimized** - DNS fixes for reliable connections  
✅ **One-command setup** - Complete installation automation  
✅ **MiningRigRentals compatible** - Supports all major pools  
✅ **Minimal dependencies** - Optimized Docker image size  
✅ **Comprehensive logging** - Full mining activity logs

## 🚨 Important Notes

- **Reboot required** after installation for GPU access
- **Sudo required** for initial setup only
- **Internet needed** for Docker image downloads
- **GPU optional** - Works with CPU-only systems

Ready to mine! 🎯
