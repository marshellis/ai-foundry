#!/usr/bin/env bash
#
# OpenClaw Channel Setup Helper
# Run this on the droplet after base installation to configure channels
#
# Usage: bash setup-channels.sh
#
set -euo pipefail

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
echo -e "${CYAN}  OpenClaw Channel Setup${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""
echo "This script helps you configure messaging channels."
echo "Make sure OpenClaw is already installed (openclaw --version)."
echo ""

# Check OpenClaw is installed
if ! command -v openclaw &> /dev/null; then
    fail "OpenClaw is not installed"
    echo "    Run the main installer first: droplet-setup.sh"
    exit 1
fi

# Menu
echo "Which channel would you like to set up?"
echo ""
echo "  1) WhatsApp"
echo "  2) Telegram"
echo "  3) Gmail (Pub/Sub)"
echo "  4) All channels"
echo "  5) Exit"
echo ""
read -p "Choice (1-5): " CHOICE

case $CHOICE in
    1)
        # -------------------------------------------------------
        # WhatsApp Setup
        # -------------------------------------------------------
        step "WhatsApp Setup"
        
        echo ""
        echo -e "${YELLOW}Prerequisites:${NC}"
        echo "  - A dedicated phone number for your assistant"
        echo "  - WhatsApp installed on a phone with that number"
        echo ""
        echo -e "${YELLOW}Getting a dedicated number:${NC}"
        echo "  - Google Voice (US, free): voice.google.com"
        echo "  - Prepaid SIM card (\$10-20)"
        echo "  - Twilio number (~\$1/month)"
        echo ""
        read -p "Do you have a dedicated number ready? (y/N) " -n 1 -r
        echo
        
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo ""
            echo "Get a dedicated number first, then re-run this script."
            exit 0
        fi
        
        echo ""
        echo -e "${YELLOW}Linking WhatsApp:${NC}"
        echo "  1. A QR code will appear in the terminal"
        echo "  2. Open WhatsApp on your phone (with the dedicated number)"
        echo "  3. Go to Settings > Linked Devices > Link a Device"
        echo "  4. Scan the QR code"
        echo ""
        read -p "Press Enter to show QR code..."
        
        openclaw channels login --channel whatsapp
        
        echo ""
        ok "WhatsApp linked!"
        echo ""
        echo "Configure access policy in ~/.openclaw/openclaw.json:"
        echo '  "channels": {'
        echo '    "whatsapp": {'
        echo '      "dmPolicy": "pairing",'
        echo '      "allowFrom": ["+1234567890"]'
        echo '    }'
        echo '  }'
        ;;
        
    2)
        # -------------------------------------------------------
        # Telegram Setup
        # -------------------------------------------------------
        step "Telegram Setup"
        
        echo ""
        echo -e "${YELLOW}Creating a Telegram Bot:${NC}"
        echo "  1. Open Telegram and search for @BotFather"
        echo "  2. Send /newbot"
        echo "  3. Choose a name for your bot (e.g., 'My AI Assistant')"
        echo "  4. Choose a username ending in 'bot' (e.g., 'myai_assistant_bot')"
        echo "  5. BotFather will give you a token like: 123456789:ABCdefGHIjklMNOpqrsTUVwxyz"
        echo ""
        read -p "Enter your bot token: " BOT_TOKEN
        
        if [[ -z "$BOT_TOKEN" ]]; then
            fail "No token provided"
            exit 1
        fi
        
        echo ""
        echo "Adding Telegram channel..."
        openclaw channels add --channel telegram --token "$BOT_TOKEN"
        
        ok "Telegram bot configured!"
        echo ""
        echo -e "${YELLOW}Optional: Disable privacy mode for groups${NC}"
        echo "  1. Message @BotFather"
        echo "  2. Send /setprivacy"
        echo "  3. Select your bot"
        echo "  4. Choose 'Disable'"
        echo "  (This lets the bot see all group messages, not just @mentions)"
        ;;
        
    3)
        # -------------------------------------------------------
        # Gmail Setup
        # -------------------------------------------------------
        step "Gmail Pub/Sub Setup"
        
        echo ""
        echo -e "${YELLOW}This is the most complex channel to set up.${NC}"
        echo ""
        echo "Prerequisites:"
        echo "  - A Gmail account for your assistant"
        echo "  - A Google Cloud account with billing enabled"
        echo "  - gcloud CLI installed (should be done by installer)"
        echo "  - Tailscale account (for webhook endpoint)"
        echo ""
        
        # Check gcloud
        if ! command -v gcloud &> /dev/null; then
            fail "gcloud CLI not installed"
            echo "    Install: https://cloud.google.com/sdk/docs/install"
            exit 1
        fi
        ok "gcloud CLI available"
        
        # Check tailscale
        if ! command -v tailscale &> /dev/null; then
            fail "Tailscale not installed"
            echo "    Install: curl -fsSL https://tailscale.com/install.sh | sh"
            exit 1
        fi
        ok "Tailscale available"
        
        echo ""
        read -p "Enter the Gmail address for your assistant: " GMAIL_ACCOUNT
        
        if [[ -z "$GMAIL_ACCOUNT" ]]; then
            fail "No email provided"
            exit 1
        fi
        
        echo ""
        echo -e "${YELLOW}Step 1: Connect Tailscale${NC}"
        echo "  Run: tailscale up"
        echo "  This connects your droplet to your tailnet for secure webhooks."
        echo ""
        read -p "Is Tailscale connected? (y/N) " -n 1 -r
        echo
        
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Run 'tailscale up' first, then re-run this script."
            exit 0
        fi
        
        echo ""
        echo -e "${YELLOW}Step 2: GCP Project Setup${NC}"
        echo ""
        echo "If you don't have a GCP project, create one:"
        echo "  gcloud projects create openclaw-gmail --name='OpenClaw Gmail'"
        echo "  gcloud config set project openclaw-gmail"
        echo ""
        echo "Enable required APIs:"
        echo "  gcloud services enable gmail.googleapis.com pubsub.googleapis.com"
        echo ""
        echo "Create Pub/Sub topic:"
        echo "  gcloud pubsub topics create openclaw-gmail-watch"
        echo "  gcloud pubsub topics add-iam-policy-binding openclaw-gmail-watch \\"
        echo "    --member=serviceAccount:gmail-api-push@system.gserviceaccount.com \\"
        echo "    --role=roles/pubsub.publisher"
        echo ""
        read -p "Have you completed the GCP setup above? (y/N) " -n 1 -r
        echo
        
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Complete the GCP setup, then re-run this script."
            exit 0
        fi
        
        echo ""
        echo -e "${YELLOW}Step 3: Run OpenClaw Gmail Setup Wizard${NC}"
        echo ""
        echo "The wizard will:"
        echo "  - Authorize access to your Gmail account"
        echo "  - Set up the Pub/Sub subscription"
        echo "  - Configure the webhook endpoint via Tailscale"
        echo ""
        read -p "Press Enter to run the wizard..."
        
        openclaw webhooks gmail setup --account "$GMAIL_ACCOUNT"
        
        ok "Gmail Pub/Sub configured!"
        ;;
        
    4)
        # -------------------------------------------------------
        # All Channels
        # -------------------------------------------------------
        echo ""
        echo "Setting up all channels in sequence..."
        echo "You can skip any channel by pressing Ctrl+C and re-running."
        echo ""
        
        # Re-run this script for each channel
        bash "$0" <<< "1"
        bash "$0" <<< "2"
        bash "$0" <<< "3"
        ;;
        
    5)
        echo "Exiting."
        exit 0
        ;;
        
    *)
        fail "Invalid choice"
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Channel setup complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Check status: openclaw status"
echo "View logs: openclaw logs --follow"
echo ""
