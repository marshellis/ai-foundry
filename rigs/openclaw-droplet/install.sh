#!/usr/bin/env bash
#
# OpenClaw on DigitalOcean - Remote Installer
# Runs on your LOCAL machine (macOS/Linux), SSHs into the droplet
#
# Usage: curl -fsSL https://raw.githubusercontent.com/marshellis/ai-foundry/main/rigs/openclaw-droplet/install.sh | bash
#
set -euo pipefail

SCRIPT_VERSION="1.0.0"
RIG_BASE_URL="https://raw.githubusercontent.com/marshellis/ai-foundry/main/rigs/openclaw-droplet"

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
echo -e "${CYAN}  OpenClaw on DigitalOcean${NC}"
echo -e "${CYAN}  Remote Installer v${SCRIPT_VERSION}${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""
echo "This installer runs on your LOCAL machine and"
echo "SSHs into your DigitalOcean droplet to set up OpenClaw."
echo ""

# -------------------------------------------------------
# Step 1: Check local prerequisites
# -------------------------------------------------------
step "Checking local prerequisites"

if ! command -v ssh &> /dev/null; then
    fail "ssh is not installed"
    exit 1
fi
ok "ssh available"

if ! command -v curl &> /dev/null; then
    fail "curl is not installed"
    exit 1
fi
ok "curl available"

# -------------------------------------------------------
# Step 2: Get droplet information
# -------------------------------------------------------
step "Droplet connection details"

echo ""
read -p "    Enter your droplet IP address: " DROPLET_IP

if [[ -z "$DROPLET_IP" ]]; then
    fail "No IP address provided"
    exit 1
fi

read -p "    SSH username (default: root): " SSH_USER
SSH_USER=${SSH_USER:-root}

# -------------------------------------------------------
# Step 3: Test SSH connection
# -------------------------------------------------------
step "Testing SSH connection"

echo "    Connecting to $SSH_USER@$DROPLET_IP..."

if ! ssh -o ConnectTimeout=10 -o BatchMode=yes "$SSH_USER@$DROPLET_IP" "echo 'SSH connection successful'" 2>/dev/null; then
    warn "Could not connect with key-based auth, trying interactive..."
    if ! ssh -o ConnectTimeout=10 "$SSH_USER@$DROPLET_IP" "echo 'SSH connection successful'"; then
        fail "Could not connect to $SSH_USER@$DROPLET_IP"
        echo ""
        echo "    Make sure:"
        echo "    1. The droplet is running"
        echo "    2. The IP address is correct"
        echo "    3. SSH is enabled on the droplet"
        echo "    4. Your SSH key is added or you know the password"
        exit 1
    fi
fi
ok "SSH connection verified"

# -------------------------------------------------------
# Step 4: Download and upload setup script
# -------------------------------------------------------
step "Downloading setup script"

SETUP_SCRIPT=$(curl -fsSL "$RIG_BASE_URL/droplet-setup.sh")
if [[ -z "$SETUP_SCRIPT" ]]; then
    fail "Could not download droplet-setup.sh"
    exit 1
fi
ok "Setup script downloaded"

step "Uploading setup script to droplet"

echo "$SETUP_SCRIPT" | ssh "$SSH_USER@$DROPLET_IP" "cat > /tmp/openclaw-setup.sh && chmod +x /tmp/openclaw-setup.sh"
ok "Setup script uploaded to /tmp/openclaw-setup.sh"

# -------------------------------------------------------
# Step 5: Execute setup on droplet
# -------------------------------------------------------
step "Running setup on droplet"

echo ""
echo -e "${YELLOW}    The setup will now run on your droplet.${NC}"
echo -e "${YELLOW}    This may take several minutes.${NC}"
echo ""

# Run the setup script interactively
ssh -t "$SSH_USER@$DROPLET_IP" "bash /tmp/openclaw-setup.sh"

# -------------------------------------------------------
# Done - Print channel setup guide
# -------------------------------------------------------
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Base installation complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${CYAN}Your droplet IP:${NC} $DROPLET_IP"
echo ""
echo -e "${CYAN}To access the Control UI:${NC}"
echo "  ssh -L 18789:localhost:18789 $SSH_USER@$DROPLET_IP"
echo "  Then open: http://localhost:18789"
echo ""
echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}  Channel Setup Guide${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""
echo -e "${YELLOW}1. WhatsApp Setup${NC}"
echo "   First, get a dedicated phone number (see README for options):"
echo "   - Google Voice (US, free): voice.google.com"
echo "   - Prepaid SIM card ($10-20)"
echo "   - Twilio number (~\$1/month)"
echo ""
echo "   Then link WhatsApp:"
echo "   ssh $SSH_USER@$DROPLET_IP"
echo "   openclaw channels login --channel whatsapp"
echo "   # Scan the QR code with WhatsApp on your dedicated number"
echo ""
echo -e "${YELLOW}2. Telegram Setup${NC}"
echo "   a) Open Telegram and message @BotFather"
echo "   b) Send /newbot and follow the prompts"
echo "   c) Copy the bot token (format: 123456789:ABCdef...)"
echo "   d) Configure OpenClaw:"
echo "      ssh $SSH_USER@$DROPLET_IP"
echo "      openclaw channels add --channel telegram --token <YOUR_BOT_TOKEN>"
echo ""
echo -e "${YELLOW}3. Gmail Setup (requires GCP project)${NC}"
echo "   See the full guide in the README or run:"
echo "   ssh $SSH_USER@$DROPLET_IP"
echo "   openclaw webhooks gmail setup --account your-assistant@gmail.com"
echo ""
echo -e "${CYAN}Documentation:${NC}"
echo "  https://docs.openclaw.ai/channels/whatsapp"
echo "  https://docs.openclaw.ai/channels/telegram"
echo "  https://docs.openclaw.ai/automation/gmail-pubsub"
echo ""
