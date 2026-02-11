#!/usr/bin/env bash
#
# OpenClaw on DigitalOcean - Remote Installer
# Runs on your LOCAL machine (macOS/Linux), SSHs into the droplet
#
# Features:
#   - Saves progress to a local checkpoint file
#   - Can resume from where it left off if interrupted
#   - Run with --reset to start fresh
#
# Usage: 
#   curl -fsSL https://raw.githubusercontent.com/marshellis/ai-foundry/main/rigs/openclaw-droplet/install.sh | bash
#   bash install.sh --reset  # Start fresh
#
set -euo pipefail

SCRIPT_VERSION="1.1.0"
RIG_BASE_URL="https://raw.githubusercontent.com/marshellis/ai-foundry/main/rigs/openclaw-droplet"
CHECKPOINT_FILE="${TMPDIR:-/tmp}/openclaw-droplet-checkpoint"

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

# -------------------------------------------------------
# Checkpoint functions
# -------------------------------------------------------
save_checkpoint() {
    local step="$1"
    local droplet_ip="${2:-}"
    local ssh_user="${3:-root}"
    echo "STEP=$step" > "$CHECKPOINT_FILE"
    echo "DROPLET_IP=$droplet_ip" >> "$CHECKPOINT_FILE"
    echo "SSH_USER=$ssh_user" >> "$CHECKPOINT_FILE"
    echo "TIMESTAMP=$(date -Iseconds)" >> "$CHECKPOINT_FILE"
    ok "Progress saved (step: $step)"
}

load_checkpoint() {
    if [[ -f "$CHECKPOINT_FILE" ]]; then
        source "$CHECKPOINT_FILE"
        echo "${STEP:-0}"
    else
        echo "0"
    fi
}

load_checkpoint_vars() {
    if [[ -f "$CHECKPOINT_FILE" ]]; then
        source "$CHECKPOINT_FILE"
    fi
}

clear_checkpoint() {
    rm -f "$CHECKPOINT_FILE"
}

# Check for --reset flag
if [[ "${1:-}" == "--reset" ]]; then
    clear_checkpoint
    echo "Checkpoint cleared. Starting fresh."
fi

# Load current progress
CURRENT_STEP=$(load_checkpoint)
load_checkpoint_vars
DROPLET_IP="${DROPLET_IP:-}"
SSH_USER="${SSH_USER:-root}"

echo ""
echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}  OpenClaw on DigitalOcean${NC}"
echo -e "${CYAN}  Remote Installer v${SCRIPT_VERSION}${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""
echo "This installer runs on your LOCAL machine and"
echo "SSHs into your DigitalOcean droplet to set up OpenClaw."
echo ""

if [[ "$CURRENT_STEP" != "0" ]]; then
    echo -e "${YELLOW}Resuming from step $CURRENT_STEP${NC}"
    if [[ -n "$DROPLET_IP" ]]; then
        echo -e "${YELLOW}Droplet: $SSH_USER@$DROPLET_IP${NC}"
    fi
    echo -e "${YELLOW}Run with --reset to start fresh${NC}"
    echo ""
fi

# -------------------------------------------------------
# Step 1: Check local prerequisites
# -------------------------------------------------------
if [[ "$CURRENT_STEP" -lt 1 ]]; then
    step "Step 1/5: Checking local prerequisites"

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

    save_checkpoint 1 "" "root"
    CURRENT_STEP=1
fi

# -------------------------------------------------------
# Step 2: Get droplet information
# -------------------------------------------------------
if [[ "$CURRENT_STEP" -lt 2 ]]; then
    step "Step 2/5: Droplet connection details"

    echo ""
    read -p "    Enter your droplet IP address: " DROPLET_IP

    if [[ -z "$DROPLET_IP" ]]; then
        fail "No IP address provided"
        exit 1
    fi

    read -p "    SSH username (default: root): " input_user
    if [[ -n "$input_user" ]]; then
        SSH_USER="$input_user"
    fi

    save_checkpoint 2 "$DROPLET_IP" "$SSH_USER"
    CURRENT_STEP=2
fi

# -------------------------------------------------------
# Step 3: Test SSH connection
# -------------------------------------------------------
if [[ "$CURRENT_STEP" -lt 3 ]]; then
    step "Step 3/5: Testing SSH connection"

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

    save_checkpoint 3 "$DROPLET_IP" "$SSH_USER"
    CURRENT_STEP=3
fi

# -------------------------------------------------------
# Step 4: Download and upload setup script
# -------------------------------------------------------
if [[ "$CURRENT_STEP" -lt 4 ]]; then
    step "Step 4/5: Downloading and uploading setup script"

    SETUP_SCRIPT=$(curl -fsSL "$RIG_BASE_URL/droplet-setup.sh")
    if [[ -z "$SETUP_SCRIPT" ]]; then
        fail "Could not download droplet-setup.sh"
        exit 1
    fi
    ok "Setup script downloaded"

    echo "    Uploading to droplet..."
    echo "$SETUP_SCRIPT" | ssh "$SSH_USER@$DROPLET_IP" "cat > /tmp/openclaw-setup.sh && chmod +x /tmp/openclaw-setup.sh"
    ok "Setup script uploaded to /tmp/openclaw-setup.sh"

    save_checkpoint 4 "$DROPLET_IP" "$SSH_USER"
    CURRENT_STEP=4
fi

# -------------------------------------------------------
# Step 5: Execute setup on droplet
# -------------------------------------------------------
if [[ "$CURRENT_STEP" -lt 5 ]]; then
    step "Step 5/5: Running setup on droplet"

    echo ""
    echo -e "${YELLOW}    The setup will now run on your droplet.${NC}"
    echo -e "${YELLOW}    This may take several minutes.${NC}"
    echo -e "${YELLOW}    If interrupted, run this script again to resume.${NC}"
    echo ""

    # Run the setup script interactively
    # The droplet script has its own checkpointing
    if ! ssh -t "$SSH_USER@$DROPLET_IP" "bash /tmp/openclaw-setup.sh"; then
        warn "Setup may not have completed successfully"
        echo "    Run this script again to retry/resume"
        exit 1
    fi

    save_checkpoint 5 "$DROPLET_IP" "$SSH_USER"
    CURRENT_STEP=5
fi

# -------------------------------------------------------
# Done - Clear checkpoint and print guide
# -------------------------------------------------------
clear_checkpoint

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
echo "   - Prepaid SIM card (\$10-20)"
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
