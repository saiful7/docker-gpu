# XMRig CUDA Mining for Jupyter Notebook

Deploy XMRig cryptocurrency mining **natively** in Jupyter Notebook environments without Docker.

## Why This Version?

The standard docker-gpu setup requires Docker, which doesn't work in containerized Jupyter environments due to:
- No systemd support
- Limited container privileges (no NET_ADMIN, no overlayfs)
- No Docker socket access

This version runs **directly** on your Jupyter system with native CUDA support.

---

## Prerequisites

✅ **Required:**
- Jupyter Notebook environment (any provider)
- NVIDIA GPU with CUDA support
- `nvidia-smi` working (driver installed)
- `nvcc` available (CUDA toolkit installed)

✅ **Recommended:**
- Root/sudo access (for installing dependencies if needed)
- At least 2GB free disk space
- Internet connection for building

---

## One-Command Installation

```bash
bash <(curl -s https://raw.githubusercontent.com/saiful7/docker-gpu/master/jupyter-install.sh)
```

Or clone and run locally:

```bash
git clone https://github.com/saiful7/docker-gpu.git
cd docker-gpu
bash jupyter-install.sh
```

**Installation takes 5-10 minutes** (compiling XMRig from source)

---

## Quick Start

### 1. Start Mining
```bash
~/mine.sh pool.supportxmr.com:3333 YOUR_MONERO_WALLET worker1
```

### 2. Check Status
```bash
~/mining-status.sh
```

### 3. Stop Mining
```bash
~/stop-mining.sh
```

---

## What Gets Installed

The script will:
1. ✅ Check GPU and CUDA availability
2. ✅ Verify required dependencies
3. ✅ Clone XMRig from official repo
4. ✅ Compile XMRig with CUDA support
5. ✅ Create mining launcher scripts
6. ✅ Generate quick start guide

**Installation locations:**
- `~/xmrig-native/` - XMRig source and binary
- `~/mine.sh` - Mining launcher
- `~/mining-status.sh` - Status checker
- `~/stop-mining.sh` - Stop script
- `~/xmrig-logs/` - Mining logs
- `~/MINING-QUICKSTART.md` - Detailed guide

---

## Usage Examples

### SupportXMR Pool (Recommended)
```bash
~/mine.sh pool.supportxmr.com:3333 YOUR_MONERO_WALLET_ADDRESS jupyter-miner
```

### MiningRigRentals
```bash
~/mine.sh stratum+tcp://us-east.rentals.nicehash.com:3333 wallet.worker1
```

### MoneroOcean (Auto-switching)
```bash
~/mine.sh gulf.moneroocean.stream:10128 YOUR_WALLET jupyter-worker
```

### Background Mining
```bash
nohup ~/mine.sh pool.supportxmr.com:3333 YOUR_WALLET &
```

---

## Monitoring

### Live GPU Status
```bash
watch -n 1 nvidia-smi
```

### Mining Logs
```bash
tail -f ~/xmrig-logs/*.log
```

### Hashrate Check
```bash
grep "speed" ~/xmrig-logs/*.log | tail -n 5
```

---

## System Requirements

### Minimum
- RTX 2060 or better (6GB VRAM)
- CUDA 10.0+
- 2GB disk space

### Recommended (Your System)
- RTX 3060 (12GB VRAM) ✅
- CUDA 12.4+ ✅
- Ryzen 5 3600 ✅

**Expected Hashrate:** ~1200-1400 H/s (Monero RandomX with RTX 3060)

---

## Troubleshooting

### Installation Issues

**Missing Dependencies:**
```bash
# Check what's installed
which git cmake gcc g++ nvcc

# If dependencies are missing, you may need sudo access or contact admin
```

**Build Fails:**
```bash
# Check installation log
cat ~/xmrig-install.log

# Retry with clean build
rm -rf ~/xmrig-native
bash jupyter-install.sh
```

### Mining Issues

**GPU Not Detected:**
```bash
# Verify GPU access
nvidia-smi

# Check XMRig can see CUDA
~/xmrig-native/xmrig/build/xmrig --version
```

**Pool Connection Failed:**
```bash
# Check logs
tail -n 50 ~/xmrig-logs/*.log

# Try different pool
~/mine.sh gulf.moneroocean.stream:10128 YOUR_WALLET
```

**Low Hashrate:**
```bash
# Monitor GPU utilization
nvidia-smi dmon

# Ensure GPU is being used
grep -i "cuda" ~/xmrig-logs/*.log
```

---

## Performance Tuning

### Optimize GPU Settings
```bash
# Add to mine.sh before running xmrig
export CUDA_VISIBLE_DEVICES=0  # Use first GPU only
```

### CPU Threads (if needed)
Edit `~/mine.sh` and remove `--no-cpu` to also use CPU cores.

### Adjust Pool Difficulty
Some pools allow custom difficulty in worker name:
```bash
~/mine.sh pool.supportxmr.com:3333 WALLET+50000 worker1
```

---

## Popular Monero Mining Pools

| Pool | URL | Port | Features |
|------|-----|------|----------|
| **SupportXMR** | pool.supportxmr.com | 3333 | Reliable, low fees (0.6%) |
| **MoneroOcean** | gulf.moneroocean.stream | 10128 | Auto-switching, 0% fee |
| **MineXMR** | pool.minexmr.com | 4444 | Large pool, 1% fee |
| **HashVault** | pool.hashvault.pro | 3333 | PPLNS, 0.9% fee |

---

## Security Notes

⚠️ **Important:**
- Never share your wallet private keys
- Only mine to pools you trust
- Monitor your Jupyter session for unexpected usage
- Some Jupyter providers prohibit mining - check TOS

---

## Uninstallation

```bash
# Stop mining
~/stop-mining.sh

# Remove files
rm -rf ~/xmrig-native ~/xmrig-logs
rm ~/mine.sh ~/mining-status.sh ~/stop-mining.sh
rm ~/MINING-QUICKSTART.md ~/xmrig-install.log
```

---

## Differences from Docker Version

| Feature | Docker Version | Jupyter Native |
|---------|---------------|----------------|
| Installation | `install_complete_setup.sh` | `jupyter-install.sh` |
| Running | Docker container | Native binary |
| Privileges | Requires Docker daemon | User-level only |
| GPU Access | Via NVIDIA Container Runtime | Direct CUDA access |
| Logs | Docker volumes | `~/xmrig-logs/` |
| Portability | Container image | Compiled binary |

---

## Advanced Usage

### Custom XMRig Options
Edit `~/mine.sh` and add options:
```bash
"$XMRIG_BIN" \
    --url="$POOL_URL" \
    --user="$WALLET_ADDRESS" \
    --pass="$WORKER_NAME" \
    --cuda \
    --threads=4 \
    --donate-level=1 \
    --max-cpu-usage=75
```

### Multiple GPUs
```bash
# Use all GPUs (default)
~/mine.sh pool.example.com:3333 WALLET

# Use specific GPU
CUDA_VISIBLE_DEVICES=1 ~/mine.sh pool.example.com:3333 WALLET
```

### Config File
Create `~/xmrig-config.json` and use:
```bash
~/xmrig-native/xmrig/build/xmrig --config=~/xmrig-config.json
```

---

## Resources

- **XMRig Documentation:** https://xmrig.com/docs
- **Monero Official:** https://www.getmonero.org/
- **Mining Calculator:** https://www.cryptocompare.com/mining/calculator/xmr
- **Pool Statistics:** https://miningpoolstats.stream/monero
- **Support:** https://github.com/saiful7/docker-gpu/issues

---

## Contributing

Found an issue or have improvements? Submit a PR or issue at:
https://github.com/saiful7/docker-gpu

---

**Happy Mining! ⛏️**

*🤖 Generated with [Claude Code](https://claude.com/claude-code)*
