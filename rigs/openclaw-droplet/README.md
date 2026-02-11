# OpenClaw on DigitalOcean

Deploy [OpenClaw](https://openclaw.ai) -- a personal AI assistant -- on a DigitalOcean droplet with WhatsApp, Telegram, and Gmail integration.

## What This Rig Does

- Installs OpenClaw on a $6/month Ubuntu droplet
- Configures swap for 1GB RAM droplets
- Sets up systemd for always-on operation
- Guides you through connecting WhatsApp, Telegram, and Gmail

After setup, your AI assistant responds on all three channels 24/7.

## Prerequisites

Before running the installer, you need:

| Requirement | Description | Where to Get It |
|-------------|-------------|-----------------|
| DigitalOcean Account | Create a $6/month Ubuntu 24.04 droplet | [cloud.digitalocean.com](https://cloud.digitalocean.com/) |
| SSH Access | Key-based or password auth to your droplet | Created during droplet setup |
| AI API Key | Anthropic or OpenAI API key | [console.anthropic.com](https://console.anthropic.com/) |
| Dedicated Phone Number | For WhatsApp (see guide below) | Google Voice, prepaid SIM, etc. |
| Google Cloud Account | For Gmail Pub/Sub (optional) | [console.cloud.google.com](https://console.cloud.google.com/) |

## Quick Install

Run from your local machine (Windows, macOS, or Linux):

**Windows (PowerShell):**
```powershell
irm https://raw.githubusercontent.com/marshellis/ai-foundry/main/rigs/openclaw-droplet/install.ps1 | iex
```

**macOS/Linux (Bash):**
```bash
curl -fsSL https://raw.githubusercontent.com/marshellis/ai-foundry/main/rigs/openclaw-droplet/install.sh | bash
```

The installer will:
1. Ask for your droplet IP address
2. SSH into the droplet
3. Install OpenClaw and dependencies
4. Run the onboarding wizard
5. Print channel setup instructions

---

## Getting a Dedicated WhatsApp Number

OpenClaw recommends using a dedicated phone number for WhatsApp -- not your personal number. This keeps your assistant's messages separate and avoids self-chat complications.

### Option 1: Google Voice (US only, free)

Best for US users who want a free option.

1. Go to [voice.google.com](https://voice.google.com)
2. Sign in with your Google account
3. Click "Get Google Voice" and choose a number
4. Verify with your existing phone number
5. Install the Google Voice app on your phone
6. Use this number to register WhatsApp

**Notes:**
- Google Voice numbers work with WhatsApp but may require verification via the Google Voice app
- You can receive SMS verification codes in the Google Voice app
- Free and works well for personal use

### Option 2: Prepaid SIM Card ($10-20)

Most reliable option, works worldwide.

1. Buy a prepaid SIM from any carrier (T-Mobile, AT&T, Mint Mobile, etc.)
2. Activate it with the minimum plan (you just need SMS for verification)
3. Insert the SIM in a spare phone or dual-SIM phone
4. Register WhatsApp with this number
5. After verification, you can let the plan lapse -- WhatsApp stays linked

**Notes:**
- Most reliable method -- carriers rarely block these numbers
- One-time cost, no recurring fees after initial verification
- Can use a cheap spare phone or dual-SIM

### Option 3: eSIM Services

For phones that support eSIM (iPhone XS+, Pixel 3+, etc.).

1. Get an eSIM from [Airalo](https://www.airalo.com/), [Holafly](https://www.holafly.com/), or similar
2. Make sure the eSIM includes SMS capability (not all do)
3. Activate the eSIM on your phone
4. Register WhatsApp with the eSIM number

**Notes:**
- Not all eSIMs support SMS -- check before purchasing
- Some eSIMs are data-only and won't work for WhatsApp verification
- Good option if you travel frequently

### Option 4: Twilio (~$1/month)

Programmatic option for tech-savvy users.

1. Create a [Twilio](https://www.twilio.com/) account
2. Buy a phone number with SMS capability (~$1/month)
3. Set up SMS forwarding to email or use Twilio console
4. Use this number for WhatsApp verification

**Notes:**
- Some VoIP numbers are blocked by WhatsApp, but Twilio generally works
- Requires ongoing payment (~$1/month)
- Good if you want programmatic control over the number

### Option 5: Dedicated Cheap Phone ($20-50)

If you want complete separation.

1. Buy a cheap Android phone (Blu, Nokia, etc.)
2. Get a prepaid SIM as in Option 2
3. Install WhatsApp on this phone
4. Link to OpenClaw using `openclaw channels login --channel whatsapp`

**Notes:**
- Complete isolation from your personal phone
- Can leave the phone plugged in at home
- WhatsApp Web/linked devices work even when the phone is off (for 14 days)

---

## Channel Setup

After the base installation, set up your messaging channels.

### WhatsApp

1. SSH into your droplet:
   ```bash
   ssh root@YOUR_DROPLET_IP
   ```

2. Link WhatsApp:
   ```bash
   openclaw channels login --channel whatsapp
   ```

3. A QR code will appear in the terminal

4. On your phone (with the dedicated number):
   - Open WhatsApp
   - Go to Settings > Linked Devices > Link a Device
   - Scan the QR code

5. Configure access policy in `~/.openclaw/openclaw.json`:
   ```json
   {
     "channels": {
       "whatsapp": {
         "dmPolicy": "pairing",
         "allowFrom": ["+1234567890"]
       }
     }
   }
   ```

**Documentation:** [docs.openclaw.ai/channels/whatsapp](https://docs.openclaw.ai/channels/whatsapp)

### Telegram

1. Create a bot via BotFather:
   - Open Telegram and search for `@BotFather`
   - Send `/newbot`
   - Choose a name (e.g., "My AI Assistant")
   - Choose a username ending in `bot` (e.g., `myai_assistant_bot`)
   - Copy the token (format: `123456789:ABCdefGHIjklMNOpqrsTUVwxyz`)

2. SSH into your droplet:
   ```bash
   ssh root@YOUR_DROPLET_IP
   ```

3. Add the Telegram channel:
   ```bash
   openclaw channels add --channel telegram --token YOUR_BOT_TOKEN
   ```

4. (Optional) Disable privacy mode for groups:
   - Message `@BotFather`
   - Send `/setprivacy`
   - Select your bot
   - Choose "Disable"
   - This lets the bot see all group messages, not just @mentions

**Documentation:** [docs.openclaw.ai/channels/telegram](https://docs.openclaw.ai/channels/telegram)

### Gmail (Pub/Sub)

This is the most complex channel. It requires a Google Cloud project.

#### Prerequisites

- Gmail account for your assistant (e.g., `my-assistant@gmail.com`)
- Google Cloud account with billing enabled
- Tailscale account (for secure webhook endpoint)

#### Step 1: Connect Tailscale

On your droplet:
```bash
tailscale up
```

Follow the link to authenticate with your Tailscale account.

#### Step 2: Set Up GCP Project

If you don't have a GCP project:
```bash
gcloud auth login
gcloud projects create openclaw-gmail --name="OpenClaw Gmail"
gcloud config set project openclaw-gmail
```

Enable required APIs:
```bash
gcloud services enable gmail.googleapis.com pubsub.googleapis.com
```

Create Pub/Sub topic:
```bash
gcloud pubsub topics create openclaw-gmail-watch

gcloud pubsub topics add-iam-policy-binding openclaw-gmail-watch \
  --member=serviceAccount:gmail-api-push@system.gserviceaccount.com \
  --role=roles/pubsub.publisher
```

#### Step 3: Run OpenClaw Gmail Setup

```bash
openclaw webhooks gmail setup --account your-assistant@gmail.com
```

The wizard will:
- Authorize access to your Gmail account
- Set up the Pub/Sub subscription
- Configure the webhook endpoint via Tailscale

**Documentation:** [docs.openclaw.ai/automation/gmail-pubsub](https://docs.openclaw.ai/automation/gmail-pubsub)

---

## Verification

After setup, verify everything works:

### Check OpenClaw Status

```bash
ssh root@YOUR_DROPLET_IP
openclaw status
```

You should see the gateway running with systemd.

### Access Control UI

From your local machine:
```bash
ssh -L 18789:localhost:18789 root@YOUR_DROPLET_IP
```

Then open [http://localhost:18789](http://localhost:18789) in your browser.

### Test Channels

1. **WhatsApp:** Send a message to your assistant's WhatsApp number
2. **Telegram:** Send a message to your bot
3. **Gmail:** Send an email to your assistant's Gmail address

Check logs for activity:
```bash
openclaw logs --follow
```

---

## Troubleshooting

### SSH Connection Failed

- Verify the droplet is running in DigitalOcean console
- Check the IP address is correct
- Try password auth if key-based fails: `ssh -o PreferredAuthentications=password root@IP`

### OpenClaw Not Starting

```bash
# Check systemd status
systemctl --user status openclaw-gateway

# View logs
journalctl --user -u openclaw-gateway -f

# Run doctor
openclaw doctor
```

### WhatsApp QR Code Not Appearing

- Make sure the gateway is running: `openclaw status`
- Try restarting: `openclaw gateway restart`
- Check logs: `openclaw logs --follow`

### Telegram Bot Not Responding

- Verify the token is correct
- Check if privacy mode is blocking messages (disable via BotFather)
- Ensure the bot is added to the group/chat

### Gmail Webhook Not Triggering

- Verify Tailscale is connected: `tailscale status`
- Check Pub/Sub subscription in GCP console
- Verify the watch is active: `gog gmail watch status --account EMAIL`

### Out of Memory

For 1GB droplets:
```bash
# Check memory
free -h

# Add more swap if needed
fallocate -l 4G /swapfile2
chmod 600 /swapfile2
mkswap /swapfile2
swapon /swapfile2
```

---

## Cost Breakdown

| Item | Cost |
|------|------|
| DigitalOcean Droplet (1GB) | $6/month |
| AI API (Anthropic/OpenAI) | ~$5-20/month (usage-based) |
| Dedicated Phone Number | $0-20 one-time (see options above) |
| Google Cloud Pub/Sub | ~$0.01/month (minimal usage) |
| **Total** | **~$11-26/month** |

---

## Files in This Rig

| File | Description |
|------|-------------|
| `install.ps1` | Remote installer for Windows |
| `install.sh` | Remote installer for macOS/Linux |
| `droplet-setup.sh` | Setup script that runs on the droplet |
| `setup-channels.sh` | Interactive channel configuration helper |
| `config.json` | Rig metadata |

---

## Links

- [OpenClaw Documentation](https://docs.openclaw.ai)
- [DigitalOcean Guide](https://docs.openclaw.ai/platforms/digitalocean)
- [WhatsApp Channel](https://docs.openclaw.ai/channels/whatsapp)
- [Telegram Channel](https://docs.openclaw.ai/channels/telegram)
- [Gmail Pub/Sub](https://docs.openclaw.ai/automation/gmail-pubsub)
