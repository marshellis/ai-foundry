#!/usr/bin/env bash
#
# OpenClaw Droplet Setup Script
# This script runs ON the DigitalOcean droplet to install OpenClaw
#
# Features:
#   - Saves progress to a checkpoint file
#   - Can resume from where it left off if interrupted
#   - Run with --reset to start fresh
#
# Usage: 
#   curl -fsSL https://raw.githubusercontent.com/.../droplet-setup.sh | bash
#   bash droplet-setup.sh --reset  # Start fresh, ignore checkpoints
#
set -euo pipefail

SCRIPT_VERSION="1.3.7"
CHECKPOINT_FILE="/tmp/openclaw-setup-checkpoint"

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
    echo "$1" > "$CHECKPOINT_FILE"
    ok "Progress saved (step: $1)"
}

load_checkpoint() {
    if [[ -f "$CHECKPOINT_FILE" ]]; then
        cat "$CHECKPOINT_FILE"
    else
        echo "0"
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

echo ""
echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}  OpenClaw Droplet Setup v${SCRIPT_VERSION}${NC}"
echo -e "${CYAN}========================================${NC}"

if [[ "$CURRENT_STEP" != "0" ]]; then
    echo ""
    echo -e "${YELLOW}Resuming from step $CURRENT_STEP${NC}"
    echo -e "${YELLOW}Run with --reset to start fresh${NC}"
fi

# -------------------------------------------------------
# Step 1: Check prerequisites
# -------------------------------------------------------
if [[ "$CURRENT_STEP" -lt 1 ]]; then
    step "Step 1/8: Checking prerequisites"

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

    save_checkpoint 1
fi

# -------------------------------------------------------
# Step 2: Update system
# -------------------------------------------------------
if [[ "$CURRENT_STEP" -lt 2 ]]; then
    step "Step 2/8: Updating system packages"

    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
    ok "System updated"

    save_checkpoint 2
fi

# -------------------------------------------------------
# Step 3: Add swap (for 1GB droplets)
# -------------------------------------------------------
if [[ "$CURRENT_STEP" -lt 3 ]]; then
    step "Step 3/8: Checking swap configuration"

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

    save_checkpoint 3
fi

# -------------------------------------------------------
# Step 4: Install Node.js 22
# -------------------------------------------------------
if [[ "$CURRENT_STEP" -lt 4 ]]; then
    step "Step 4/8: Installing Node.js 22"

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

    save_checkpoint 4
fi

# -------------------------------------------------------
# Step 5: Install Tailscale (for Gmail Pub/Sub webhook)
# -------------------------------------------------------
if [[ "$CURRENT_STEP" -lt 5 ]]; then
    step "Step 5/8: Installing Tailscale"

    if command -v tailscale &> /dev/null; then
        ok "Tailscale already installed"
    else
        curl -fsSL https://tailscale.com/install.sh | sh
        ok "Tailscale installed"
    fi

    # Check if Tailscale is connected
    if tailscale status &>/dev/null 2>&1 && ! tailscale status 2>&1 | grep -q "Logged out"; then
        TS_NAME=$(tailscale status --self --json 2>/dev/null | grep -o '"DNSName":"[^"]*"' | head -1 | cut -d'"' -f4 || echo "")
        if [[ -n "$TS_NAME" ]]; then
            ok "Tailscale connected as $TS_NAME"
        else
            ok "Tailscale connected"
        fi
    else
        echo ""
        echo "    Tailscale provides a public HTTPS endpoint for Gmail webhooks."
        echo "    If you plan to use Gmail, you should connect Tailscale now."
        echo ""
        echo "    To get an auth key:"
        echo "    1. Sign up at: https://tailscale.com/ (free for personal use)"
        echo "       (Click 'Skip this introduction' if you see a device setup wizard)"
        echo "    2. Go to: https://login.tailscale.com/admin/settings/keys"
        echo "    3. Generate a new auth key"
        echo "    4. Copy the key"
        echo ""
        read -p "    Enter Tailscale auth key (or press Enter to skip): " ts_key
        if [[ -n "$ts_key" ]]; then
            echo ""
            echo -e "${YELLOW}>>> Running: tailscale up --authkey <KEY>${NC}"
            if tailscale up --authkey "$ts_key" 2>&1; then
                ok "Tailscale connected"
            else
                warn "Tailscale auth failed. Run 'tailscale up --authkey <KEY>' manually."
            fi
        else
            echo -e "${YELLOW}    Skipped. Run 'tailscale up' later if you need Gmail.${NC}"
        fi
    fi

    save_checkpoint 5
fi

# -------------------------------------------------------
# Step 6: Install gcloud CLI and gog (for Gmail Pub/Sub)
# -------------------------------------------------------
if [[ "$CURRENT_STEP" -lt 6 ]]; then
    step "Step 6/8: Installing Google Cloud CLI and gog"

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

    # Install gog (Google OAuth CLI for Gmail)
    if command -v gog &> /dev/null; then
        GOG_VER=$(gog --version 2>/dev/null | head -1 || echo "unknown")
        ok "gog already installed ($GOG_VER)"
    else
        echo "    Installing gog (Google OAuth CLI)..."
        # Download release from GitHub (binary is named 'gog' inside the tarball)
        GOG_VERSION="0.9.0"
        curl -fsSL "https://github.com/steipete/gogcli/releases/download/v${GOG_VERSION}/gogcli_${GOG_VERSION}_linux_amd64.tar.gz" -o /tmp/gog.tar.gz
        tar -xzf /tmp/gog.tar.gz -C /tmp
        mv /tmp/gog /usr/local/bin/gog
        chmod +x /usr/local/bin/gog
        rm -f /tmp/gog.tar.gz
        ok "gog v${GOG_VERSION} installed"
    fi

    save_checkpoint 6
fi

# -------------------------------------------------------
# Step 7: Install OpenClaw
# -------------------------------------------------------
if [[ "$CURRENT_STEP" -lt 7 ]]; then
    step "Step 7/8: Installing OpenClaw"

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

    save_checkpoint 7
fi

# -------------------------------------------------------
# Step 8: Run OpenClaw onboarding
# -------------------------------------------------------
if [[ "$CURRENT_STEP" -lt 8 ]]; then
    step "Step 8/8: Running OpenClaw onboarding"

    # Check if onboarding was already completed by checking openclaw status
    ONBOARDING_DONE=false
    if openclaw status 2>&1 | grep -q "Gateway service.*running"; then
        ONBOARDING_DONE=true
    elif openclaw status 2>&1 | grep -q "Gateway service.*installed"; then
        ONBOARDING_DONE=true
    fi

    if [[ "$ONBOARDING_DONE" == "true" ]]; then
        ok "OpenClaw onboarding already completed (daemon is configured)"
        echo ""
        echo "    To re-run onboarding, use: openclaw onboard --install-daemon"
    else
        echo ""
        echo -e "${YELLOW}    The onboarding wizard will now run interactively.${NC}"
        echo -e "${YELLOW}    Recommended settings:${NC}"
        echo -e "${YELLOW}      - Gateway bind: loopback (default, secure)${NC}"
        echo -e "${YELLOW}      - Install daemon: Yes${NC}"
        echo -e "${YELLOW}      - Enter your Anthropic/OpenAI API key when prompted${NC}"
        echo ""
        read -p "    Press Enter to start onboarding..."

        # Limit Node.js heap to prevent OOM on 1GB droplets (swap handles overflow)
        export NODE_OPTIONS="--max-old-space-size=768"
        openclaw onboard --install-daemon
    fi

    save_checkpoint 8
fi

# -------------------------------------------------------
# Step 9: Verify OpenClaw is working
# -------------------------------------------------------
if [[ "$CURRENT_STEP" -lt 9 ]]; then
    step "Step 9/10: Verifying OpenClaw"

    echo ""
    echo "    Let's verify OpenClaw is working with a simple test."
    echo ""
    
    # Check if openclaw is running
    if openclaw status &>/dev/null; then
        ok "OpenClaw service is running"
    else
        warn "OpenClaw service may not be running"
        echo "    Trying to start it..."
        openclaw gateway start &>/dev/null || true
        sleep 2
    fi
    
    # Test with a simple prompt
    echo ""
    echo -e "${YELLOW}    Testing with a simple prompt...${NC}"
    echo -e "${YELLOW}>>> Running: openclaw agent -m 'Say hello in 3 words' --agent main${NC}"
    echo ""
    
    export NODE_OPTIONS="--max-old-space-size=768"
    TEST_RESULT=$(timeout 30 openclaw agent -m "Say hello in exactly 3 words" --agent main 2>&1) || true
    
    if [[ -n "$TEST_RESULT" ]] && [[ "$TEST_RESULT" != *"error"* ]] && [[ "$TEST_RESULT" != *"Error"* ]]; then
        ok "OpenClaw responded: $TEST_RESULT"
        echo ""
    else
        warn "OpenClaw test failed or timed out"
        if [[ -n "$TEST_RESULT" ]]; then
            echo "    Output: $TEST_RESULT"
        fi
        echo ""
        echo "    This usually means the API key is not configured."
        echo ""
        echo -e "${YELLOW}    Would you like to configure your API key now?${NC}"
        read -p "    (y/n): " configure_key
        
        if [[ "$configure_key" == "y" || "$configure_key" == "Y" ]]; then
            echo ""
            echo "    Running onboard again to set API key..."
            echo ""
            openclaw onboard
            
            # Test again
            echo ""
            echo "    Testing again..."
            TEST_RESULT=$(timeout 30 openclaw agent -m "Say hello in exactly 3 words" --agent main 2>&1) || true
            if [[ -n "$TEST_RESULT" ]] && [[ "$TEST_RESULT" != *"error"* ]]; then
                ok "OpenClaw responded: $TEST_RESULT"
            else
                warn "Still not working. You may need to check your API key."
                echo "    Run 'openclaw onboard' to reconfigure."
            fi
        fi
    fi

    save_checkpoint 9
fi

# -------------------------------------------------------
# Step 10: Channel setup
# -------------------------------------------------------
if [[ "$CURRENT_STEP" -lt 10 ]]; then
    step "Step 10/10: Channel Setup"

    DROPLET_IP=$(hostname -I | awk '{print $1}')

    echo ""
    echo -e "${YELLOW}    Which channels would you like to set up?${NC}"
    echo ""
    echo "    1) WhatsApp (requires dedicated phone number)"
    echo "    2) Telegram (requires bot token from @BotFather)"
    echo "    3) Gmail (requires Google Cloud project)"
    echo "    4) Skip channel setup for now"
    echo ""
    read -p "    Enter choice: " channel_choices

    export NODE_OPTIONS="--max-old-space-size=768"

    if [[ "$channel_choices" == *"1"* ]]; then
        echo ""
        echo -e "${CYAN}--- WhatsApp Setup ---${NC}"
        echo ""
        echo "    You'll need a dedicated phone number for WhatsApp."
        echo "    Options: Google Voice (free, US), prepaid SIM, or Twilio"
        echo ""
        echo "    A QR code will appear. Scan it with WhatsApp on your"
        echo "    dedicated phone (Settings > Linked Devices > Link a Device)"
        echo ""
        read -p "    Ready to link WhatsApp? (y/n): " wa_ready
        if [[ "$wa_ready" == "y" || "$wa_ready" == "Y" ]]; then
            echo ""
            echo -e "${YELLOW}>>> Running: openclaw channels login --channel whatsapp${NC}"
            echo -e "${YELLOW}>>> A QR code should appear below. Scan it with WhatsApp.${NC}"
            echo ""
            openclaw channels login --channel whatsapp
        fi
    fi

    if [[ "$channel_choices" == *"2"* ]]; then
        echo ""
        echo -e "${CYAN}--- Telegram Setup ---${NC}"
        echo ""
        echo "    To create a Telegram bot:"
        echo "    1. Open Telegram and message @BotFather"
        echo "    2. Send /newbot"
        echo "    3. Choose a name and username for your bot"
        echo "    4. Copy the bot token (format: 123456789:ABCdef...)"
        echo ""
        read -p "    Enter your Telegram bot token: " tg_token
        if [[ -n "$tg_token" ]]; then
            echo ""
            echo -e "${YELLOW}>>> Running: openclaw channels add --channel telegram --token <TOKEN>${NC}"
            echo ""
            openclaw channels add --channel telegram --token "$tg_token"
            ok "Telegram bot configured"
            echo ""
            echo "    Your bot is ready! Message it on Telegram to test."
        fi
    fi

    if [[ "$channel_choices" == *"3"* ]]; then
        echo ""
        echo -e "${CYAN}--- Gmail Setup ---${NC}"
        echo ""
        echo "    Gmail setup requires Tailscale, gcloud, and gog."
        echo "    We'll walk through each step now."
        echo ""

        # Step 1: Ensure Tailscale is connected
        echo -e "${YELLOW}[Step 1/5] Connecting Tailscale${NC}"
        if tailscale status &>/dev/null 2>&1 && ! tailscale status 2>&1 | grep -q "Logged out"; then
            TS_NAME=$(tailscale status --self --json 2>/dev/null | grep -o '"DNSName":"[^"]*"' | head -1 | cut -d'"' -f4 || echo "")
            if [[ -n "$TS_NAME" ]]; then
                ok "Tailscale connected as $TS_NAME"
            else
                ok "Tailscale connected"
            fi
        else
            echo ""
            echo "    Tailscale provides a public HTTPS endpoint for Gmail webhooks."
            echo "    You need a Tailscale account (free for personal use)."
            echo "    Sign up at: https://tailscale.com/"
            echo "    (Click 'Skip this introduction' if you see a device setup wizard)"
            echo ""
            echo "    Since this is a headless server, we'll use an auth key."
            echo ""
            echo "    To get an auth key:"
            echo "    1. Go to: https://login.tailscale.com/admin/settings/keys"
            echo "    2. Generate a new auth key (reusable is fine)"
            echo "    3. Copy the key"
            echo ""
            read -p "    Enter your Tailscale auth key (or 'skip' to skip Gmail): " ts_key

            if [[ "$ts_key" == "skip" ]]; then
                echo "    Skipping Gmail setup."
                # Jump past Gmail by not entering the rest of the block
            else
                echo ""
                echo -e "${YELLOW}>>> Running: tailscale up --authkey <KEY>${NC}"
                echo ""
                if tailscale up --authkey "$ts_key" 2>&1; then
                    ok "Tailscale connected"
                else
                    warn "Tailscale auth failed. You can try manually: tailscale up --authkey <KEY>"
                fi
            fi
        fi

        # Only continue if Tailscale is connected
        if tailscale status &>/dev/null 2>&1 && ! tailscale status 2>&1 | grep -q "Logged out"; then

        # Step 2: Check/authenticate gcloud
        echo ""
        echo -e "${YELLOW}[Step 2/5] Authenticating gcloud CLI${NC}"
        if gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>/dev/null | grep -q "@"; then
            GCLOUD_ACCOUNT=$(gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>/dev/null | head -1)
            ok "gcloud already authenticated as $GCLOUD_ACCOUNT"
        else
            echo ""
            echo "    You need to authenticate gcloud. Since this is a headless server,"
            echo "    gcloud will show you a command to run on your LOCAL machine."
            echo ""
            echo -e "${YELLOW}    IMPORTANT: You need gcloud CLI installed on your local machine.${NC}"
            echo "    Install from: https://cloud.google.com/sdk/docs/install"
            echo ""
            echo "    The flow will be:"
            echo "    1. gcloud prints a command starting with 'gcloud auth login --remote-bootstrap=...'"
            echo "    2. Copy that ENTIRE command (it's very long)"
            echo "    3. Run it in a terminal on your LOCAL machine (not here)"
            echo "    4. A browser will open, sign in and authorize"
            echo "    5. Your local gcloud will print output - copy ALL of it"
            echo "    6. Paste that output back here"
            echo ""
            read -p "    Press Enter when ready..." _
            echo ""
            echo -e "${YELLOW}>>> Running: gcloud auth login --no-browser${NC}"
            echo ""
            if gcloud auth login --no-browser; then
                ok "gcloud authenticated"
            else
                warn "gcloud auth failed. Gmail setup cannot continue."
                echo "    Run 'gcloud auth login --no-browser' manually later."
            fi
        fi

        # Step 3: Set GCP project
        echo ""
        echo -e "${YELLOW}[Step 3/5] Setting Google Cloud project${NC}"
        echo ""
        echo "    Gmail uses Google Cloud for Pub/Sub notifications."
        echo "    You need a Google Cloud project with billing enabled."
        echo ""

        CURRENT_PROJECT=$(gcloud config get-value project 2>/dev/null)
        if [[ -n "$CURRENT_PROJECT" && "$CURRENT_PROJECT" != "(unset)" ]]; then
            echo "    Current project: $CURRENT_PROJECT"
            read -p "    Use this project? (y/n): " use_current
            if [[ "$use_current" != "y" && "$use_current" != "Y" ]]; then
                CURRENT_PROJECT=""
            fi
        fi

        if [[ -z "$CURRENT_PROJECT" || "$CURRENT_PROJECT" == "(unset)" ]]; then
            # Check for existing projects
            PROJECT_LIST=$(gcloud projects list --format="value(projectId)" 2>/dev/null)

            if [[ -n "$PROJECT_LIST" ]]; then
                echo "    Your existing projects:"
                echo ""
                gcloud projects list --format="table(projectId,name)" 2>/dev/null
                echo ""
                read -p "    Enter a project ID from above (or 'new' to create one): " gcp_project
            else
                echo "    No existing Google Cloud projects found."
                gcp_project="new"
            fi

            if [[ "$gcp_project" == "new" ]]; then
                echo ""
                echo "    Let's create a new Google Cloud project."
                echo ""
                DEFAULT_PROJECT_ID="openclaw-assistant-$(date +%Y%m%d)"
                read -p "    Project ID (default: $DEFAULT_PROJECT_ID): " input_project_id
                GCP_PROJECT_ID="${input_project_id:-$DEFAULT_PROJECT_ID}"

                echo ""
                echo -e "${YELLOW}>>> Running: gcloud projects create $GCP_PROJECT_ID${NC}"
                echo ""
                if gcloud projects create "$GCP_PROJECT_ID" --name="OpenClaw Assistant" 2>&1; then
                    ok "Project '$GCP_PROJECT_ID' created"
                    gcp_project="$GCP_PROJECT_ID"
                else
                    warn "Could not create project. You may need to create one manually at:"
                    echo "    https://console.cloud.google.com/projectcreate"
                    echo ""
                    read -p "    Enter your project ID after creating it: " gcp_project
                fi
            fi

            if [[ -n "$gcp_project" && "$gcp_project" != "new" ]]; then
                gcloud config set project "$gcp_project"
                ok "Project set to $gcp_project"

                # Enable required APIs
                echo ""
                echo "    Enabling required APIs (Gmail and Pub/Sub)..."
                echo -e "${YELLOW}>>> Running: gcloud services enable gmail.googleapis.com pubsub.googleapis.com${NC}"
                if gcloud services enable gmail.googleapis.com pubsub.googleapis.com 2>&1; then
                    ok "Gmail API and Pub/Sub API enabled"
                else
                    warn "Could not enable APIs. You may need to enable billing first."
                    echo ""
                    echo "    1. Go to: https://console.cloud.google.com/billing"
                    echo "    2. Link a billing account to your project"
                    echo "    3. Then run this script again"
                    echo ""
                    read -p "    Press Enter after enabling billing (or 'skip' to continue): " billing_response
                    if [[ "$billing_response" != "skip" ]]; then
                        echo "    Retrying API enable..."
                        if gcloud services enable gmail.googleapis.com pubsub.googleapis.com 2>&1; then
                            ok "Gmail API and Pub/Sub API enabled"
                        else
                            warn "APIs still could not be enabled. Gmail setup may fail."
                        fi
                    fi
                fi
            fi
        fi

        # Step 4: Authenticate gog (for Gmail OAuth)
        echo ""
        echo -e "${YELLOW}[Step 4/5] Authenticating gog (Gmail OAuth)${NC}"
        if gog auth status &>/dev/null; then
            ok "gog already authenticated"
        else
            echo ""
            echo "    gog needs OAuth access to Gmail."
            echo "    This also uses a --no-browser flow."
            echo ""
            echo -e "${YELLOW}>>> Running: gog auth --no-browser${NC}"
            echo ""
            read -p "    Press Enter to continue..." _
            if gog auth --no-browser || gog auth; then
                ok "gog authenticated"
            else
                warn "gog auth may have failed. Check manually with 'gog auth status'"
            fi
        fi

        # Step 5: Run OpenClaw Gmail setup
        echo ""
        echo -e "${YELLOW}[Step 5/5] Running OpenClaw Gmail webhook setup${NC}"

        # Get the current GCP project ID to pass to openclaw
        GCP_PROJECT=$(gcloud config get-value project 2>/dev/null || echo "")
        if [[ -z "$GCP_PROJECT" || "$GCP_PROJECT" == "(unset)" ]]; then
            echo ""
            warn "No GCP project set. OpenClaw needs a project ID for Gmail."
            read -p "    Enter your GCP project ID: " GCP_PROJECT
        else
            echo "    Using GCP project: $GCP_PROJECT"
        fi

        read -p "    Enter the Gmail address for your assistant: " gmail_addr
        if [[ -n "$gmail_addr" && -n "$GCP_PROJECT" ]]; then
            echo ""
            echo -e "${YELLOW}>>> Running: openclaw webhooks gmail setup --account $gmail_addr --project $GCP_PROJECT${NC}"
            echo ""
            openclaw webhooks gmail setup --account "$gmail_addr" --project "$GCP_PROJECT" || true
            echo ""
            ok "Gmail setup attempted. Check output above for any errors."
        elif [[ -n "$gmail_addr" ]]; then
            echo ""
            echo -e "${YELLOW}>>> Running: openclaw webhooks gmail setup --account $gmail_addr${NC}"
            echo ""
            openclaw webhooks gmail setup --account "$gmail_addr" || true
            echo ""
            ok "Gmail setup attempted. Check output above for any errors."
        fi

        fi # end: Tailscale connected check
    fi

    save_checkpoint 10
fi

# -------------------------------------------------------
# Done - Clear checkpoint
# -------------------------------------------------------
clear_checkpoint

DROPLET_IP=$(hostname -I | awk '{print $1}')

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Setup complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${CYAN}Droplet IP:${NC} $DROPLET_IP"
echo ""
echo -e "${CYAN}Quick commands:${NC}"
echo ""
echo "  Check status:        openclaw status"
echo "  Test chat:           echo 'Hello' | openclaw chat"
echo "  View logs:           openclaw logs --follow"
echo "  Restart gateway:     openclaw gateway restart"
echo ""
echo -e "${CYAN}Access Control UI (from your local machine):${NC}"
echo "  ssh -L 18789:localhost:18789 root@$DROPLET_IP"
echo "  Then open: http://localhost:18789"
echo ""
echo -e "${CYAN}Add more channels later:${NC}"
echo "  WhatsApp:  openclaw channels login --channel whatsapp"
echo "  Telegram:  openclaw channels add --channel telegram --token <TOKEN>"
echo "  Gmail:     openclaw webhooks gmail setup --account <EMAIL>"
echo ""
echo -e "${CYAN}Documentation:${NC}"
echo "  https://docs.openclaw.ai"
echo ""
