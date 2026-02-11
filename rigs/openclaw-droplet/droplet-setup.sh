#!/usr/bin/env bash
#
# OpenClaw Droplet Setup Script
# This script runs ON the DigitalOcean droplet to install OpenClaw
#
# Usage: curl -fsSL https://raw.githubusercontent.com/.../droplet-setup.sh | bash
#
set -euo pipefail

SCRIPT_VERSION="1.0.0"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

step() {
    echo -e "\n${CYAN}--- $1${NC}"
}

ok() {
    echo -e "${GREEN}    OK: $1${NC}"
}

warn() {
    echo -e "${YELLOW}    WARN: $1${NC}"
}

fail() {
    echo -e "${RED}    FAIL: $1${NC}"
}

echo ""
echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}  OpenClaw Droplet Setup v${SCRIPT_VERSION}${NC}"
echo -e "${CYAN}========================================${NC}"

# -------------------------------------------------------
# Step 1: Check prerequisites
# -------------------------------------------------------
step "Checking prerequisites"

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    fail "This script must be run as root"
    echo "    Run: sudo bash $0"
    exit 1
fi
ok "Running as root"

# Check Ubuntu
if grep -q "Ubuntu" /etc/os-release 2>/dev/null; then
    UBUNTU_VERSION=$(grep VERSION_ID /etc/os-release | cut -d'"' -f2)
    ok "Ubuntu $UBUNTU_VERSION detected"
    if [[ "$UBUNTU_VERSION" != "24.04" ]]; then
        warn "Ubuntu 24.04 LTS is recommended. You have $UBUNTU_VERSION"
        read -p "    Continue anyway? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
else
    fail "This script is designed for Ubuntu"
    exit 1
fi

# Check curl
if ! command -v curl &> /dev/null; then
    warn "curl not found, installing..."
    apt-get update && apt-get install -y curl
fi
ok "curl available"

# -------------------------------------------------------
# Step 2: Update system
# -------------------------------------------------------
step "Updating system packages"

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
ok "System updated"

# -------------------------------------------------------
# Step 3: Add swap (for 1GB droplets)
# -------------------------------------------------------
step "Checking swap configuration"

TOTAL_MEM=$(free -m | awk '/^Mem:/{print $2}')
SWAP_EXISTS=$(swapon --show | wc -l)

if [[ $SWAP_EXISTS -eq 0 ]]; then
    if [[ $TOTAL_MEM -lt 2048 ]]; then
        echo "    Your droplet has ${TOTAL_MEM}MB RAM"
        echo "    Adding 2GB swap is recommended for stability"
        read -p "    Add 2GB swap? (Y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            fallocate -l 2G /swapfile
            chmod 600 /swapfile
            mkswap /swapfile
            swapon /swapfile
            echo '/swapfile none swap sw 0 0' >> /etc/fstab
            ok "2GB swap added"
        else
            warn "Skipped swap (may cause out-of-memory issues)"
        fi
    else
        ok "Sufficient RAM (${TOTAL_MEM}MB), swap not needed"
    fi
else
    ok "Swap already configured"
fi

# -------------------------------------------------------
# Step 4: Install Node.js 22
# -------------------------------------------------------
step "Installing Node.js 22"

if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    if [[ "$NODE_VERSION" == v22* ]]; then
        ok "Node.js $NODE_VERSION already installed"
    else
        warn "Node.js $NODE_VERSION found, upgrading to v22..."
        curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
        apt-get install -y nodejs
        ok "Node.js $(node --version) installed"
    fi
else
    curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
    apt-get install -y nodejs
    ok "Node.js $(node --version) installed"
fi

# -------------------------------------------------------
# Step 5: Install Tailscale (for Gmail Pub/Sub webhook)
# -------------------------------------------------------
step "Installing Tailscale"

if command -v tailscale &> /dev/null; then
    ok "Tailscale already installed"
else
    curl -fsSL https://tailscale.com/install.sh | sh
    ok "Tailscale installed"
fi

echo ""
echo -e "${YELLOW}    NOTE: Run 'tailscale up' later to connect to your tailnet${NC}"
echo -e "${YELLOW}    This is needed for Gmail Pub/Sub webhook endpoint${NC}"

# -------------------------------------------------------
# Step 6: Install gcloud CLI (for Gmail Pub/Sub)
# -------------------------------------------------------
step "Installing Google Cloud CLI"

if command -v gcloud &> /dev/null; then
    ok "gcloud CLI already installed"
else
    # Install gcloud CLI
    apt-get install -y apt-transport-https ca-certificates gnupg
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
    apt-get update && apt-get install -y google-cloud-cli
    ok "gcloud CLI installed"
fi

# -------------------------------------------------------
# Step 7: Install OpenClaw
# -------------------------------------------------------
step "Installing OpenClaw"

if command -v openclaw &> /dev/null; then
    OPENCLAW_VERSION=$(openclaw --version 2>/dev/null || echo "unknown")
    ok "OpenClaw already installed ($OPENCLAW_VERSION)"
    read -p "    Reinstall/upgrade? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        curl -fsSL https://openclaw.ai/install.sh | bash
        ok "OpenClaw reinstalled"
    fi
else
    curl -fsSL https://openclaw.ai/install.sh | bash
    ok "OpenClaw installed"
fi

# -------------------------------------------------------
# Step 8: Run OpenClaw onboarding
# -------------------------------------------------------
step "Running OpenClaw onboarding"

echo ""
echo -e "${YELLOW}    The onboarding wizard will now run interactively.${NC}"
echo -e "${YELLOW}    Recommended settings:${NC}"
echo -e "${YELLOW}      - Gateway bind: loopback (default, secure)${NC}"
echo -e "${YELLOW}      - Install daemon: Yes${NC}"
echo -e "${YELLOW}      - Enter your Anthropic/OpenAI API key when prompted${NC}"
echo ""
read -p "    Press Enter to start onboarding..."

openclaw onboard --install-daemon

# -------------------------------------------------------
# Done
# -------------------------------------------------------
DROPLET_IP=$(hostname -I | awk '{print $1}')

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  OpenClaw installed successfully!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${CYAN}Droplet IP:${NC} $DROPLET_IP"
echo ""
echo -e "${CYAN}Next steps:${NC}"
echo ""
echo "  1. Access the Control UI (from your local machine):"
echo "     ssh -L 18789:localhost:18789 root@$DROPLET_IP"
echo "     Then open: http://localhost:18789"
echo ""
echo "  2. Set up messaging channels:"
echo "     - WhatsApp: openclaw channels login --channel whatsapp"
echo "     - Telegram: openclaw channels add --channel telegram --token <BOT_TOKEN>"
echo "     - Gmail: openclaw webhooks gmail setup --account <EMAIL>"
echo ""
echo "  3. Check status:"
echo "     openclaw status"
echo "     systemctl --user status openclaw-gateway"
echo ""
echo -e "${CYAN}Documentation:${NC}"
echo "  - WhatsApp: https://docs.openclaw.ai/channels/whatsapp"
echo "  - Telegram: https://docs.openclaw.ai/channels/telegram"
echo "  - Gmail: https://docs.openclaw.ai/automation/gmail-pubsub"
echo ""
