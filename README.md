# N8N Production Platform on Hetzner Cloud

[![OpenTofu](https://img.shields.io/badge/OpenTofu-FFDA18?style=for-the-badge&logo=opentofu&logoColor=black)](https://opentofu.org/docs/)
[![Ansible](https://img.shields.io/badge/Ansible-EE0000?style=for-the-badge&logo=ansible&logoColor=white)](https://docs.ansible.com/)
[![Hetzner](https://img.shields.io/badge/Hetzner-D50C2D?style=for-the-badge&logo=hetzner&logoColor=white)](https://console.hetzner.com/)
[![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://docs.docker.com/)
[![N8N](https://img.shields.io/badge/n8n-EA4B71?style=for-the-badge&logo=n8n&logoColor=white)](https://n8n.io/)

Deploy a production-ready N8N automation platform with optional companion services on Hetzner Cloud. Uses OpenTofu for infrastructure and Ansible for configuration management.

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
- **OpenTofu** → Infrastructure (server, firewall, cloud-init)
- **Ansible** → Configuration (DNS, secrets, services)

**Why?**
- Service changes take ~30 seconds (vs 5+ minutes)
- Idempotent - safe to re-run anytime
- Proper tool separation
- Better operations (logs, restarts, backups)

---

## Prerequisites

1. **Hetzner Cloud account** + API token ([get it here](https://console.hetzner.cloud))
2. **OpenTofu** - `brew install opentofu` (or see [install guide](https://opentofu.org/docs/intro/install))
3. **Ansible** - `brew install ansible` (or `pip install ansible`)
4. **GitHub PAT** with read access to your private repo:
   - GitHub → Settings → Developer settings → Personal access tokens → Fine-grained tokens
   - Set Resource owner to build-automate, Repository access: All repositories
   - Permissions: Contents → Read-only
5. **SSH key pair** - `ssh-keygen -t ed25519 -C "n8n-server" -f ~/.ssh/id_ed25519_n8n`
6. **Domain name** with DNS access

---

## Quick Start

### 1. Infrastructure (OpenTofu)

```bash
# Clone and configure
git clone https://github.com/build-automate/n8n-hetzner-deploy.git
cd n8n-hetzner-deploy/opentofu
cp terraform.tfvars.example terraform.tfvars
code terraform.tfvars  # Edit with your values

# Required settings:
# hcloud_token, domain, home_ip, ssh_key_path, github_pat

# Deploy
tofu init
tofu apply
```

This creates the server and auto-generates `ansible/inventory.yml` and `ansible/group_vars/all.yml`.

### 2. Configuration (optional)

```bash
cd ..
code ansible/group_vars/all.yml
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

### 4. Deploy Services

```bash
make install-requirements
make deploy
```

Visit `https://n8n.yourdomain.com` and create your account!

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
1. Edit `ansible/group_vars/all.yml` (set `enabled: true/false`)
2. Run `make deploy` (generates secrets for new services)

---

## Server Sizing

| Size | Specs | Cost/month | Use Case |
|------|-------|------------|----------|
| cx23 | 4 vCPU, 8GB RAM | ~$7 | N8N only |
| cx33 | 8 vCPU, 16GB RAM | ~$14 | N8N + 1-2 services |
| cx43 | 16 vCPU, 32GB RAM | ~$28 | Production workload |

Change in `opentofu/terraform.tfvars`:
```hcl
server_type = "cx33"
```

---

## Configuration

### OpenTofu (`opentofu/terraform.tfvars`)

```hcl
hcloud_token = "your-hetzner-api-token"
domain       = "yourdomain.com"
home_ip      = "1.2.3.4"
ssh_key_path = "~/.ssh/id_ed25519_n8n.pub"
github_pat   = "github_pat_xxxxx"

server_type  = "cx23"
location     = "hel1"  # or nbg1, fsn1, ash
```

### Ansible (`ansible/group_vars/all.yml`)

Auto-generated by OpenTofu, edit to enable services:

```yaml
domain: "yourdomain.com"
home_ip: "1.2.3.4"
github_pat: "github_pat_xxxxx"

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

## Support

Questions? Join the [Build & Automate community on Skool](https://www.skool.com/build-automate)

---

## License

MIT - Use at your own risk
