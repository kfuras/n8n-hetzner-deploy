# N8N Production Platform on Hetzner Cloud

[![OpenTofu](https://img.shields.io/badge/OpenTofu-FFDA18?style=for-the-badge&logo=opentofu&logoColor=black)](https://opentofu.org/docs/)
[![Ansible](https://img.shields.io/badge/Ansible-EE0000?style=for-the-badge&logo=ansible&logoColor=white)](https://docs.ansible.com/)
[![Hetzner](https://img.shields.io/badge/Hetzner-D50C2D?style=for-the-badge&logo=hetzner&logoColor=white)](https://console.hetzner.com/)
[![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://docs.docker.com/)
[![N8N](https://img.shields.io/badge/n8n-EA4B71?style=for-the-badge&logo=n8n&logoColor=white)](https://n8n.io/)

Deploy a production-ready **N8N workflow automation platform** (think Zapier or Make.com but self-hosted) with optional companion services on Hetzner Cloud. Uses OpenTofu for infrastructure provisioning and Ansible for configuration management.

**Perfect for:** Automating business workflows, connecting apps, and building custom integrations without vendor lock-in.

---

## What You Get

- **N8N** - Workflow automation with PostgreSQL database
- **Traefik** - Automatic SSL certificates via Let's Encrypt
- **Optional Services** - BaseRow, NocoDB, MinIO, Postiz, NCA Toolkit, Kokoro TTS
- **Security** - Firewall, SSH hardening, fail2ban, automated secrets
- **Ubuntu 24.04** with Docker and hardening

All secrets are automatically generated server-side using `openssl` - they never pass through OpenTofu/Ansible state.

---

## Architecture

**Two-tool approach for production:**
- **OpenTofu** → Creates the server (infrastructure)
- **Ansible** → Installs & configures services (software)

**Why split these?**
- Service changes take ~30 seconds (vs 5+ minutes)
- Safe to re-run anytime without breaking things
- Each tool does what it's best at
- Better day-to-day operations (logs, restarts, backups)

---

## Prerequisites

1. **Hetzner Cloud account** + API token ([get it here](https://console.hetzner.cloud))
   - Affordable European cloud provider (~$7/month to start)
   - API token lets OpenTofu create servers automatically

2. **OpenTofu** - Open-source infrastructure automation tool (like Terraform)
   - **macOS:** `brew install opentofu`
   - **Windows:** `winget install --exact --id=OpenTofu.Tofu`
   - **Linux:** See [install guide](https://opentofu.org/docs/intro/install)
   - Describes infrastructure as code

3. **Ansible** - Configuration management tool that installs and configures software on servers
   - **macOS:** `brew install ansible` (or `pip install ansible`)
   - **Linux:** `sudo apt install ansible` (Ubuntu/Debian) or `pip install ansible`

4. **GitHub PAT** (Personal Access Token) - needed to access the private docker-compose repo:
   - GitHub → Settings → Developer settings → Personal access tokens → Fine-grained tokens
   - Set Resource owner to **build-automate**
   - Repository access: **All repositories**
   - Permissions: **Contents → Read-only**
   - This allows the server to pull the docker-compose configuration files

5. **SSH key pair** - Secure way to access your server (no passwords needed)
   
   **Creating an SSH key pair:**
   ```bash
   ssh-keygen -t ed25519 -C "n8n-server" -f ~/.ssh/id_ed25519_n8n
   ```
   
   This creates two files:
   - `~/.ssh/id_ed25519_n8n` - **Private key** (keep this secret, stays on your computer)
   - `~/.ssh/id_ed25519_n8n.pub` - **Public key** (this is what you put in terraform.tfvars)
   
   **Important:** Use the `.pub` file path in your `ssh_key_path` variable!

6. **Your home IP address** - Get it by running: `curl ifconfig.me`
   - Must include `/32` at the end (e.g., `123.45.67.89/32`)
   - This restricts SSH access to only your IP for security

7. **Domain name** with DNS access
   - Any domain registrar works (Namecheap, Cloudflare, Google Domains, etc.)
   - You'll need to add DNS A records pointing to your server

---

## Quick Start

### 1. Infrastructure (OpenTofu)

```bash
# Clone and configure
git clone https://github.com/build-automate/n8n-hetzner-deploy.git
cd n8n-hetzner-deploy/opentofu
cp terraform.tfvars.example terraform.tfvars
code terraform.tfvars  # Edit with your values

# Edit the required settings:
# - server_name
# - username
# - hcloud_token
# - domain
# - home_ip
# - ssh_key_path
# - github_pat

# Deploy
tofu init
tofu apply
```

This creates the server and auto-generates `ansible/inventory.yml` and `ansible/group_vars/infrastructure.yml`.

### 2. Configuration (optional)

```bash
cd ..
code ansible/group_vars/services.yml
# Enable optional services: set enabled: true for nocodb, minio, etc.
```

### 3. DNS Setup

Add DNS A records pointing to your server IP (shown in tofu output).

**Option 1: Wildcard (recommended)**
```
*.yourdomain.com → <server-ip>
```
Covers all services automatically.

**Option 2: Individual records**
```
n8n.yourdomain.com → <server-ip>
nocodb.yourdomain.com → <server-ip>
minio.yourdomain.com → <server-ip>
minio-data.yourdomain.com → <server-ip>
# Add records for each enabled service
```

**Tip:** DNS changes can take 5-60 minutes to propagate. You can proceed to step 4 while waiting.

### 4. Deploy Services

```bash
make install-requirements  # Installs required Ansible roles (one-time)
make deploy               # Configures server and starts all services (~2-3 min)
```

Visit `https://n8n.yourdomain.com` and create your admin account!

**First deployment takes 2-3 minutes.** SSL certificates are generated automatically.

---

## Daily Operations

```bash
make services                    # Show running containers
make logs service=n8n            # View last 100 lines
make restart                     # Restart all services
make restart service=traefik     # Restart one service
make backup                      # Backup databases
```

**To follow logs in real-time** (streaming), SSH directly to the server:
```bash
ssh -i ~/.ssh/id_ed25519_n8n_dev USER@SERVER_IP "cd stack && docker compose logs -f SERVICE"
```

**Update deployment:**
- `make deploy` - Full deployment (use when adding/removing services, changing config, or when in doubt)
- `make update` - Quick update (only when you've changed docker-compose files in stack repo)

**Enable/disable services:**
1. Edit `ansible/group_vars/services.yml` (set `enabled: true/false`)
2. Run `make deploy` (generates secrets for new services)

---

## Server Sizing

**👉 Recommended for beginners:** Start with **cx23** (~$3.49/month) for n8n only. You can resize later if needed.

### Cost-Optimized (CX Series) - Shared Resources Intel/AMD
Best for development, testing, and small-scale automation:

| Size | vCPU | RAM | Storage | Cost/month | Best For |
|------|------|-----|---------|------------|----------|
| cx23 | 2 | 4GB | 40GB SSD | ~$3.49 | **Recommended starter** - N8N core + light workflows |
| cx33 | 4 | 8GB | 80GB SSD | ~$5.99 | N8N + 2-3 services (NocoDB, MinIO) |
| cx43 | 8 | 16GB | 160GB SSD | ~$9.99 | Heavy automation workloads |
| cx53 | 16 | 32GB | 320GB SSD | ~$18.99 | Large-scale production |

### Regular Performance (CPX Series) - Shared AMD
Balanced price/performance for production workloads:

| Size | vCPU | RAM | Storage | Cost/month | Best For |
|------|------|-----|---------|------------|----------|
| cpx22 | 2 | 4GB | 80GB SSD | ~$6.99 | Budget production |
| cpx32 | 4 | 8GB | 160GB SSD | ~$11.99 | Consistent performance |
| cpx42 | 8 | 16GB | 320GB SSD | ~$21.99 | Business-critical automation |
| cpx52 | 12 | 24GB | 480GB SSD | ~$31.49 | High-performance needs |

**💡 My recommendation:** I run cx33 (~$5.99/month) with n8n, NocoDB, MinIO, and several workflows. Perfect sweet spot.

**To change server size:**
1. Edit `opentofu/terraform.tfvars`:
   ```hcl
   server_type = "cx33"
   ```
2. Run `tofu apply` (requires ~2 minute downtime)

Check current pricing at [hetzner.com/cloud](https://www.hetzner.com/cloud).

---

## Configuration

### OpenTofu (`opentofu/terraform.tfvars`)

```hcl
# Hetzner
hcloud_token = "your-hetzner-cloud-api-token" # Change me
ssh_key_path = "~/.ssh/id_ed25519_your_ssh_key.pub" # Change me
home_ip      = "your.ip.address/32" # Change me

# Server
server_name = "your-server-name" # Change me
server_type = "cx23"
location    = "hel1"  # Helsinki (Northern Europe) | nbg1/fsn1 (Germany) | ash (US East)
image       = "ubuntu-24.04"
username    = "your-username" # Change me

# GitHub
github_org  = "build-automate"
github_repo = "n8n-production-platform"
github_pat  = "github_pat_xxxxxxxxxxxxx" # Change me

# Domain & Core
domain = "yourdomain.com" # Change me

# Security & Deployment
enable_firewall = true
enable_backups  = false
```

### Ansible (`ansible/group_vars/`)

**infrastructure.yml** (auto-generated by OpenTofu):
```yaml
domain: "yourdomain.com"
home_ip: "1.2.3.4"
github_pat: "github_pat_xxxxx"
```

**services.yml** (user-managed, never overwritten):
```yaml
services:
  baserow:
    enabled: false
  nocodb:
    enabled: true   # Enable this service
  minio:
    enabled: true
  # ... etc
```

---

## Security

- **Network:** SSH restricted to your IP, fail2ban, automatic SSL
- **SSH:** Key-only auth, root login disabled
- **Secrets:** Auto-generated server-side with `openssl`, never in OpenTofu/Ansible state
- **Docker:** Non-root user, log rotation configured

**⚠️ Important:** Encryption keys are permanent. Do not regenerate them post-deployment or you'll lose N8N workflow data.

---

## Common Mistakes

**❌ Forgot to edit terraform.tfvars**
- Copy the example file AND edit all 7 required fields marked with `# Change me`

**❌ Wrong home_ip format**
- Must include `/32` at the end: `123.45.67.89/32`
- Get your IP: `curl ifconfig.me` (from prerequisite #6)

**❌ Skipped DNS setup**
- DNS must be configured BEFORE visiting your domain
- Use wildcard (`*.yourdomain.com`) for easiest setup

**❌ SSH key issues**
- Make sure you use the `.pub` (public) key in terraform.tfvars
- Private key (without .pub) stays on your computer

**❌ Wrong GitHub PAT permissions**
- Must have access to `build-automate/n8n-production-platform` repo
- Resource owner must be set to "build-automate"

---

## Troubleshooting

**DNS not propagating?**
```bash
dig @1.1.1.1 n8n.yourdomain.com +short  # Should show server IP
```

**Services not starting?**
```bash
ssh -i ~/.ssh/your_key user@server-ip
docker ps
docker compose -f ~/stack/docker-compose.yml logs -f
```

**SSL certificate issues?**
```bash
docker compose -f ~/stack/docker-compose.yml logs traefik | grep acme
```

**Can't SSH?**
- Wait 2-3 minutes for server boot
- Check `home_ip` matches your IP: `curl ifconfig.me`
- Verify SSH key path in terraform.tfvars

**Service won't enable?**
Force re-run provisioning:
```bash
cd ansible && make deploy
```

---

## Useful Commands

```bash
# Infrastructure
tofu show                        # Current state
tofu output public_ipv4          # Get server IP
tofu destroy                     # Delete everything

# SSH access
ssh -i ~/.ssh/id_ed25519_n8n user@server-ip

# On server
docker ps                        # Running containers
docker compose logs -f n8n       # View logs
docker compose restart           # Restart all
```

---

## Cost Estimate

**Typical monthly costs for a production n8n setup:**

| Component | Cost | Notes |
|-----------|------|-------|
| Server (cx23) | ~$3.49/month | 2 vCPU, 4GB RAM - perfect for n8n core |
| Server (cx33) | ~$5.99/month | 4 vCPU, 8GB RAM - n8n + 2-3 services |
| Traffic | $0 | 20TB included (more than enough) |
| Backups (optional) | +20% | ~$0.70-1.20/month if enabled |
| Domain | ~$12/year | From your registrar (not Hetzner) |

**💰 Total: $3.49-5.99/month** for a fully-featured automation platform with SSL, backups, and professional infrastructure.

Compare to managed alternatives:
- n8n Cloud: $20-300/month
- Zapier: $30-600/month
- Make.com: $9-299/month

**You own the infrastructure and data** with no workflow limits or execution quotas.

---

## Support

Questions? Join the [Build & Automate community on Skool](https://www.skool.com/build-automate)

---

## License

MIT - Use at your own risk
