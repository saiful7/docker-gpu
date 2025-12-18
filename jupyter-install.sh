#!/bin/bash
# XMRig CUDA Native Installation for Jupyter Notebook Environment
# Usage: bash jupyter-install.sh

set -e

INSTALL_DIR="$HOME/xmrig-native"
LOG_FILE="$HOME/xmrig-install.log"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
    exit 1
}

# Start installation
log "Starting XMRig CUDA installation for Jupyter environment..."
log "Installation directory: $INSTALL_DIR"
log "Log file: $LOG_FILE"

# Check if running in container
if [ -f /.dockerenv ] || grep -q docker /proc/1/cgroup 2>/dev/null; then
    log "Detected containerized environment"
fi

# Step 1: Check NVIDIA/CUDA availability
log "Checking NVIDIA GPU and CUDA availability..."
if command -v nvidia-smi &> /dev/null; then
    GPU_INFO=$(nvidia-smi --query-gpu=name,driver_version,memory.total --format=csv,noheader)
    log "GPU detected: $GPU_INFO"
else
    error "nvidia-smi not found. GPU access is required."
fi

if command -v nvcc &> /dev/null; then
    CUDA_VERSION=$(nvcc --version | grep "release" | sed -n 's/.*release \([0-9.]*\).*/\1/p')
    log "CUDA toolkit detected: Version $CUDA_VERSION"
else
    error "nvcc not found. CUDA toolkit is required for compilation."
fi

# Step 2: Check required dependencies
log "Checking required dependencies..."

MISSING_DEPS=()

check_command() {
    if ! command -v $1 &> /dev/null; then
        MISSING_DEPS+=($1)
        warn "$1 is not installed"
        return 1
    else
        log "✓ $1 found"
        return 0
    fi
}

check_command git
check_command cmake
check_command gcc
check_command g++
check_command make

# Check for library headers
check_lib() {
    if [ -f "/usr/include/$1" ] || [ -f "/usr/local/include/$1" ]; then
        log "✓ $1 found"
        return 0
    else
        warn "$1 not found (package: $2)"
        MISSING_DEPS+=($2)
        return 1
    fi
}

check_lib "uv.h" "libuv1-dev"
check_lib "openssl/ssl.h" "libssl-dev"
check_lib "hwloc.h" "libhwloc-dev"

# Install missing dependencies if possible
if [ ${#MISSING_DEPS[@]} -gt 0 ]; then
    warn "Missing dependencies detected: ${MISSING_DEPS[*]}"

    # Check if we can use apt (Debian/Ubuntu)
    if command -v apt-get &> /dev/null; then
        log "Attempting to install missing dependencies..."

        # Check if running as root or can use sudo
        if [ "$EUID" -eq 0 ]; then
            log "Running as root, installing packages..."
            apt-get update -qq
            apt-get install -y ${MISSING_DEPS[*]} 2>&1 | tee -a "$LOG_FILE"
            log "✓ Dependencies installed successfully"
        elif command -v sudo &> /dev/null && sudo -n true 2>/dev/null; then
            log "Using sudo to install packages..."
            sudo apt-get update -qq
            sudo apt-get install -y ${MISSING_DEPS[*]} 2>&1 | tee -a "$LOG_FILE"
            log "✓ Dependencies installed successfully"
        else
            warn "Cannot install automatically (no root/sudo access)"
            warn "Please install manually:"
            echo "  apt-get install ${MISSING_DEPS[*]}"
            log "Attempting to continue anyway..."
        fi
    else
        warn "apt-get not found. Please install dependencies manually:"
        echo "  ${MISSING_DEPS[*]}"
        log "Attempting to continue anyway..."
    fi
fi

# Step 3: Create installation directory
log "Creating installation directory..."
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

# Step 4: Clone XMRig
if [ -d "$INSTALL_DIR/xmrig" ]; then
    log "XMRig directory already exists. Pulling latest changes..."
    cd "$INSTALL_DIR/xmrig"
    git pull || warn "Could not update XMRig repository"
else
    log "Cloning XMRig repository..."
    git clone https://github.com/xmrig/xmrig.git
    cd "$INSTALL_DIR/xmrig"
fi

# Step 5: Build XMRig with CUDA
log "Building XMRig with CUDA support..."
log "This may take 5-10 minutes depending on your CPU..."

mkdir -p build
cd build

log "Running cmake with CUDA support..."
if cmake .. -DWITH_CUDA=ON 2>&1 | tee -a "$LOG_FILE"; then
    log "✓ CMake configuration successful"
else
    error "CMake configuration failed. Check $LOG_FILE for details."
fi

log "Compiling XMRig (using all CPU cores)..."
if make -j$(nproc) 2>&1 | tee -a "$LOG_FILE"; then
    log "✓ Build successful!"
else
    error "Build failed. Check $LOG_FILE for details."
fi

# Verify binary
if [ -f "$INSTALL_DIR/xmrig/build/xmrig" ]; then
    log "✓ XMRig binary created: $INSTALL_DIR/xmrig/build/xmrig"

    # Test the binary
    log "Testing XMRig binary..."
    if "$INSTALL_DIR/xmrig/build/xmrig" --version | head -n 1; then
        log "✓ XMRig binary works correctly"
    else
        warn "XMRig binary created but version check failed"
    fi
else
    error "Build completed but binary not found at expected location"
fi

# Step 6: Create mining launcher script
log "Creating mining launcher script..."

cat > "$HOME/mine.sh" << 'EOFMINER'
#!/bin/bash
# Native XMRig CUDA Miner Launcher
# Usage: ./mine.sh POOL_URL WALLET_ADDRESS [WORKER_NAME]

XMRIG_BIN="$HOME/xmrig-native/xmrig/build/xmrig"
LOG_DIR="$HOME/xmrig-logs"
LOG_FILE="$LOG_DIR/xmrig-$(date +%Y%m%d-%H%M%S).log"

# Check arguments
if [ $# -lt 2 ]; then
    echo "❌ Missing required parameters!"
    echo ""
    echo "Usage: ./mine.sh POOL_URL WALLET_ADDRESS [WORKER_NAME]"
    echo ""
    echo "Examples:"
    echo "  MiningRigRentals: ./mine.sh stratum+tcp://us-east.rentals.nicehash.com:3333 wallet.worker1"
    echo "  Standard pool:    ./mine.sh pool.supportxmr.com:443 wallet_address worker1"
    echo "  SupportXMR:       ./mine.sh pool.supportxmr.com:3333 YOUR_WALLET worker1"
    exit 1
fi

POOL_URL="$1"
WALLET_ADDRESS="$2"
WORKER_NAME="${3:-jupyter-$(hostname)}"

echo "🚀 Starting XMRig CUDA Miner (Native Mode)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Pool:   $POOL_URL"
echo "Wallet: $WALLET_ADDRESS"
echo "Worker: $WORKER_NAME"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check if binary exists
if [ ! -f "$XMRIG_BIN" ]; then
    echo "❌ XMRig binary not found at: $XMRIG_BIN"
    echo "Run: bash ~/jupyter-install.sh"
    exit 1
fi

# Check GPU
if command -v nvidia-smi &> /dev/null; then
    echo "✓ GPU: $(nvidia-smi --query-gpu=name --format=csv,noheader | head -n1)"
else
    echo "⚠️  WARNING: nvidia-smi not found. GPU mining may not work."
fi

# Create log directory
mkdir -p "$LOG_DIR"

echo ""
echo "📊 Mining output:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Run XMRig
"$XMRIG_BIN" \
    --url="$POOL_URL" \
    --user="$WALLET_ADDRESS" \
    --pass="$WORKER_NAME" \
    --cuda \
    --no-cpu \
    --donate-level=1 \
    --log-file="$LOG_FILE" \
    --verbose

echo ""
echo "Mining stopped. Log saved to: $LOG_FILE"
EOFMINER

chmod +x "$HOME/mine.sh"
log "✓ Mining script created: $HOME/mine.sh"

# Step 7: Create helper scripts
log "Creating helper scripts..."

# Status checker
cat > "$HOME/mining-status.sh" << 'EOFSTATUS'
#!/bin/bash
# Check mining status and GPU utilization

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "XMRig Mining Status"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check if mining process is running
if pgrep -x xmrig > /dev/null; then
    echo "✓ XMRig is running (PID: $(pgrep -x xmrig))"
    echo ""

    # Show GPU status
    if command -v nvidia-smi &> /dev/null; then
        echo "GPU Status:"
        nvidia-smi --query-gpu=index,name,utilization.gpu,memory.used,memory.total,temperature.gpu --format=csv,noheader
    fi

    echo ""
    echo "Latest log entries:"
    tail -n 20 ~/xmrig-logs/*.log 2>/dev/null | tail -n 10
else
    echo "✗ XMRig is not running"
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
EOFSTATUS

chmod +x "$HOME/mining-status.sh"
log "✓ Status checker created: $HOME/mining-status.sh"

# Stop script
cat > "$HOME/stop-mining.sh" << 'EOFSTOP'
#!/bin/bash
# Stop XMRig mining

if pgrep -x xmrig > /dev/null; then
    echo "Stopping XMRig..."
    pkill -x xmrig
    sleep 2
    if pgrep -x xmrig > /dev/null; then
        echo "Force stopping..."
        pkill -9 -x xmrig
    fi
    echo "✓ XMRig stopped"
else
    echo "XMRig is not running"
fi
EOFSTOP

chmod +x "$HOME/stop-mining.sh"
log "✓ Stop script created: $HOME/stop-mining.sh"

# Step 8: Create quick start guide
cat > "$HOME/MINING-QUICKSTART.md" << 'EOFGUIDE'
# XMRig CUDA Mining - Quick Start Guide

## Installation Complete! 🎉

Your XMRig CUDA miner is ready to use in your Jupyter environment.

## Quick Start

### Start Mining
```bash
~/mine.sh POOL_URL WALLET_ADDRESS [WORKER_NAME]
```

**Examples:**
```bash
# SupportXMR pool
~/mine.sh pool.supportxmr.com:3333 YOUR_MONERO_WALLET_ADDRESS jupyter-miner

# MiningRigRentals
~/mine.sh stratum+tcp://us-east.rentals.nicehash.com:3333 wallet.worker1

# With custom worker name
~/mine.sh pool.supportxmr.com:3333 YOUR_WALLET my-jupyter-worker
```

### Check Status
```bash
~/mining-status.sh
```

### Stop Mining
```bash
~/stop-mining.sh
```

### View Logs
```bash
# Latest log
tail -f ~/xmrig-logs/*.log

# All logs
ls -lh ~/xmrig-logs/
```

## File Locations

- **XMRig Binary:** `~/xmrig-native/xmrig/build/xmrig`
- **Mining Script:** `~/mine.sh`
- **Logs Directory:** `~/xmrig-logs/`
- **Installation Log:** `~/xmrig-install.log`

## GPU Check

Verify GPU access:
```bash
nvidia-smi
```

## Troubleshooting

### Mining won't start
1. Check GPU access: `nvidia-smi`
2. Verify binary exists: `ls -lh ~/xmrig-native/xmrig/build/xmrig`
3. Check logs: `tail ~/xmrig-logs/*.log`

### Low hashrate
1. Ensure GPU is being used (check with `nvidia-smi`)
2. Check pool connection in logs
3. Verify CUDA support: `~/xmrig-native/xmrig/build/xmrig --version`

### Rebuild XMRig
```bash
cd ~/xmrig-native/xmrig/build
make clean
cmake .. -DWITH_CUDA=ON
make -j$(nproc)
```

## Popular Monero Pools

- **SupportXMR:** pool.supportxmr.com:3333
- **MoneroOcean:** gulf.moneroocean.stream:10128
- **MineXMR:** pool.minexmr.com:4444
- **HashVault:** pool.hashvault.pro:3333

## Resources

- XMRig GitHub: https://github.com/xmrig/xmrig
- Monero Official: https://www.getmonero.org/
- Pool List: https://miningpoolstats.stream/monero

---
*Generated with Claude Code - https://claude.com/claude-code*
EOFGUIDE

log "✓ Quick start guide created: $HOME/MINING-QUICKSTART.md"

# Final summary
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log "✅ Installation Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
log "📁 Files created:"
log "   Mining launcher: $HOME/mine.sh"
log "   Status checker:  $HOME/mining-status.sh"
log "   Stop script:     $HOME/stop-mining.sh"
log "   Quick guide:     $HOME/MINING-QUICKSTART.md"
log "   XMRig binary:    $INSTALL_DIR/xmrig/build/xmrig"
echo ""
log "🚀 Start mining with:"
echo "   ~/mine.sh pool.supportxmr.com:3333 YOUR_WALLET_ADDRESS"
echo ""
log "📚 Read the quick start guide:"
echo "   cat ~/MINING-QUICKSTART.md"
echo ""
log "Full installation log saved to: $LOG_FILE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
