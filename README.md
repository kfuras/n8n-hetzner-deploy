# N8N Production Platform on Hetzner Cloud

[![OpenTofu](https://img.shields.io/badge/OpenTofu-FFDA18?style=for-the-badge&logo=opentofu&logoColor=black)](https://opentofu.org/docs/)
[![Hetzner](https://img.shields.io/badge/Hetzner-D50C2D?style=for-the-badge&logo=hetzner&logoColor=white)](https://console.hetzner.com/)
[![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://docs.docker.com/)
[![N8N](https://img.shields.io/badge/n8n-EA4B71?style=for-the-badge&logo=n8n&logoColor=white)](https://n8n.io/)
[![Traefik](https://img.shields.io/badge/Traefik-24A1C1?style=for-the-badge&logo=traefikproxy&logoColor=white)](https://traefik.io/)

Deploy a complete N8N automation platform with optional companion services on Hetzner Cloud. Fully automated deployment with SSL certificates, security hardening, and modular architecture.

**Security:** Secrets are automatically generated on the server during deployment using `openssl`. They never pass through Terraform state, keeping your infrastructure code secure. Encryption keys are permanent - do not change them post-deployment as this will break N8N workflows and encrypted data.

---

## ⚠️ REQUIRED: GitHub Personal Access Token

**This deployment will NOT work without a GitHub PAT.** You need a Personal Access Token with read access to the private `build-automate/n8n-production-platform` repository.

### How to Create Your PAT:

1. Go to GitHub.com and click your **profile icon** (upper right)
2. Navigate: **Settings** → **Developer Settings** → **Personal Access Tokens** → **Fine-grained tokens**
3. Click **Generate new token**
4. Configure:
   - **Token name**: `n8n-deploy-read` (or any name you prefer)
   - **Resource owner**: Select **build-automate**
   - **Expiration**: **Never** (or set your own policy)
   - **Repository access**: **All repositories**
   - **Permissions**: 
     - Repository permissions → **Contents**: **Read-only**
5. Click **Generate token**
6. **Copy the token immediately** - you won't see it again!

Save this token securely - you'll need it in `terraform.tfvars` as `github_pat`.

---

## What Gets Created

When you run this configuration, you'll get:

- **N8N Core** - Workflow automation platform with PostgreSQL database
- **Traefik Reverse Proxy** - Automatic SSL certificates via Let's Encrypt
- **Optional Services** (enable/disable via flags):
  - BaseRow - Airtable alternative
  - NocoDB - Airtable alternative
  - MinIO - S3-compatible object storage
  - Kokoro TTS - Text-to-speech service
  - NCA Toolkit - Neural character animation
  - Postiz - Social media management
- **Ubuntu 24.04 server** with Docker and security hardening
- **Firewall** with SSH restricted to your IP, HTTP/HTTPS open
- **fail2ban** protecting against brute-force attacks

All services are automatically configured with your domain and secured behind Traefik with Let's Encrypt SSL certificates.

## Architecture

This setup uses a modular Docker Compose architecture:

- **Base Stack**: N8N + PostgreSQL + Traefik (always deployed)
- **Optional Services**: Each service has its own `docker-compose.{service}.yml` file
- **Configuration**: Single `.env` file with domain-based variables
- **Service Control**: Toggle services on/off via `enable_*` flags in `terraform.tfvars`

When you enable a service, OpenTofu automatically:
1. Uncomments the service's compose file in the includes section
2. Copies and configures environment files
3. Starts the service with `docker compose up -d`

Disabling a service comments out its include and removes the containers automatically.

## Prerequisites

Before you start, you need:

1. **Hetzner Cloud Account** and API token with **Read & Write** permissions
   - Get it from [console.hetzner.cloud](https://console.hetzner.cloud) → Security → API Tokens

2. **OpenTofu** installed:
   - macOS: `brew install opentofu`
   - Windows: `winget install --exact --id=OpenTofu.Tofu`
   - Linux: See [opentofu.org/docs/intro/install](https://opentofu.org/docs/intro/install)

3. **GitHub Personal Access Token** with read access to your private repo
   - Settings → Developer settings → Personal access tokens → Fine-grained tokens
   - Only needs "Contents: Read-only" permission

4. **SSH key pair** for server access

5. **Domain name** with access to DNS settings
   - Works with any DNS hosting service where you can add DNS records
   - You'll manually configure DNS records; deployment waits for propagation

### DNS Configuration - Works With Any Service

You can use **any DNS hosting service** to configure your domain's DNS records:

- **Cloudflare** - Dashboard or API
- **AWS Route53** - Console or CLI
- **Namecheap** - Control panel
- **GoDaddy** - Domain manager
- **Google Domains** - DNS settings
- **Any other service** - Just needs A record support

**How it works:**
1. You manually add DNS records in your DNS hosting service's dashboard
2. OpenTofu checks if those records have propagated (using public DNS servers)
3. Once verified, deployment continues automatically

### Creating an SSH Key Pair

If you don't have an SSH key yet, create one:

```bash
ssh-keygen -t ed25519 -C "n8n-server" -f ~/.ssh/id_ed25519_n8n_dev
```

This creates two files:
- `~/.ssh/id_ed25519_n8n_dev` - Private key (keep this secret)
- `~/.ssh/id_ed25519_n8n_dev.pub` - Public key (this goes in your tfvars)

## Quick Start

1. **Clone this repository**
   ```bash
   git clone <your-repo>
   cd opentofu
   ```

2. **Create your configuration**
   
   Copy the example and fill in your values:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

   Edit `terraform.tfvars`:
   ```terraform
   # Hetzner
   hcloud_token = "your-hetzner-api-token"
   ssh_key_path = "~/.ssh/id_ed25519_n8n_dev.pub"
   home_ip      = "your.ip.address/32"

   # Server
   server_name  = "n8n-server-1"
   server_type  = "cx23"
   location     = "hel1"
   username     = "yourname"

   # GitHub (for private repo access)
   github_org   = "your-github-org"
   github_repo  = "n8n-production-platform"
   github_pat   = "github_pat_xxxxx"

   # Domain
   domain       = "yourdomain.com"

   # Apps to enable
   enable_baserow     = false
   enable_nocodb      = false
   enable_minio       = false
   enable_kokoro_tts  = false
   enable_nca_toolkit = false
   enable_postiz      = false
   ```

3. **Get your public IP address**
   ```bash
   curl ifconfig.co -4
   ```
   Use this for `home_ip` with `/32` suffix (e.g., `27.87.234.153/32`)

4. **Initialize OpenTofu**
   ```bash
   tofu init
   ```

5. **Review what will be created**
   ```bash
   tofu plan
   ```

6. **Deploy the infrastructure**
   ```bash
   tofu apply
   ```
   
   The deployment will:
   - Create the server and get an IP address
   - Wait for DNS to propagate (checks automatically)
   - Configure services once DNS is ready
   - Start all enabled services

7. **Configure DNS (while deployment waits)**
   
   The deployment pauses to check DNS. In another terminal or browser:
   
   ```bash
   # Get the required DNS records
   tofu output dns_records_needed
   ```
   
   Point your domain's DNS records to the server IP (shown in output):
   ```
   A    n8n        -> <server-ip>
   A    nocodb     -> <server-ip>
   # ... (only records for enabled services)
   ```
   
   Or use wildcard (covers all services):
   ```
   A    *.yourdomain.com -> <server-ip>
   ```
   
   **DNS providers**: Works with any provider (Cloudflare, Route53, Namecheap, GoDaddy, etc.)
   
   Once DNS propagates (1-5 minutes), Terraform automatically detects it and continues.

8. **Wait for services to start**
   
   The first deployment takes 5-10 minutes total:
   - DNS propagation: 1-5 minutes (automatic check)
   - Cloud-init installs Docker: 2-3 minutes
   - Traefik requests SSL certificates: 1-2 minutes
   - Services initialize databases: 1-2 minutes

9. **Access N8N**
   
   Open `https://n8n.yourdomain.com` in your browser and set up your account.

## Enabling/Disabling Services

To enable additional services, edit `terraform.tfvars`:

```terraform
enable_baserow = true  # Enable BaseRow
enable_nocodb  = true  # Enable NocoDB
```

Then apply the changes:
```bash
tofu apply
```

OpenTofu will:
- Detect the configuration change via triggers
- Uncomment the service's docker-compose include
- Start the service automatically
- Service will be available at `https://servicename.yourdomain.com`

To disable a service, set it to `false` and run `tofu apply` again. The containers will be stopped and removed automatically.

## Configuration

### DNS Wait Check

By default, OpenTofu waits for DNS to propagate before starting services. This ensures SSL certificates work on first try.

**Control via `terraform.tfvars`:**
```terraform
wait_for_dns = true   # Wait for DNS (recommended, default)
wait_for_dns = false  # Skip DNS check, start immediately
```

**How it works:**
- Checks DNS every 30 seconds (up to 30 minutes)
- Only checks enabled services
- Queries Cloudflare's public DNS resolver (1.1.1.1) for checking propagation
- Continues anyway after timeout

### Server Sizing

Default is `cx23` (2 vCPU, 4GB RAM, 40GB SSD, ~$5/month). Recommended sizing:

**For N8N only:**
- `cx23` - 2 vCPU, 4GB RAM (~$5/month) - Good for light automation

**For N8N + 1-2 services:**
- `cx33` - 4 vCPU, 8GB RAM (~$7/month) - Recommended starting point

**For N8N + 3-5 services:**
- `cx43` - 8 vCPU, 16GB RAM (~$12/month) - Production workloads

**For full stack (all services):**
- `cx53` - 16 vCPU, 32GB RAM (~$23/month) - Heavy usage

### Locations

Default is Helsinki (`hel1`). Available locations:
- `hel1` - Helsinki, Finland (EU, lowest latency Northern Europe)
- `nbg1` - Nuremberg, Germany (EU)
- `fsn1` - Falkenstein, Germany (EU)
- `ash` - Ashburn, USA (East Coast)

### Firewall Control

Firewall is enabled by default. Control in `terraform.tfvars`:

```terraform
enable_firewall = true  # SSH from your IP only, HTTP/HTTPS open
enable_firewall = false # Open access (not recommended)
```

### Backups

Automatic daily backups are disabled by default to minimize costs:

```terraform
enable_backups = true  # Enable automatic daily backups (+20% cost)
```

Hetzner keeps the last 7 daily backups.

## Service URLs

After deployment, services are available at:

- **N8N**: `https://n8n.yourdomain.com`
- **N8N Webhooks**: `https://webhook.yourdomain.com`
- **BaseRow**: `https://baserow.yourdomain.com` (if enabled)
- **NocoDB**: `https://nocodb.yourdomain.com` (if enabled)
- **MinIO Console**: `https://minio-console.yourdomain.com` (if enabled)
- **MinIO API**: `https://minio-api.yourdomain.com` (if enabled)
- **Postiz**: `https://postiz.yourdomain.com` (if enabled)

All services automatically get SSL certificates from Let's Encrypt via Traefik.

## Security Features

### Network Security
- SSH access restricted to your IP address only
- All services behind Traefik reverse proxy
- Automatic SSL/TLS certificates
- fail2ban protecting against brute-force attacks

### SSH Hardening
- Root login disabled
- Password authentication disabled
- Key-only authentication required

### Docker Security
- Log rotation configured (10MB max, 3 files per container)
- Non-root user with Docker access

### Application Security
- Unique secure secrets auto-generated on server using `openssl rand`
- Secrets never stored in Terraform state (generated server-side only)
- GitHub PAT only needs read-only access to contents
- Encryption keys are permanent and cannot be changed without data loss

## How It Works

### Deployment Flow

1. **Server Creation**: Hetzner creates the server and assigns an IP address

2. **DNS Check** (if `wait_for_dns = true`):
   - OpenTofu pauses and checks if DNS records point to the new IP
   - Checks only enabled services (n8n, baserow, nocodb, etc.)
   - Queries Cloudflare's public resolver (1.1.1.1) to verify propagation
   - Continues automatically when DNS propagates (or after 30 min timeout)

3. **Cloud-init Setup**: While DNS propagates, the server:
   - Installs Docker and security tools
   - Configures SSH hardening and fail2ban
   - Clones your GitHub repo to `/home/username/stack`

4. **Service Configuration**: Once DNS is ready, OpenTofu:
   - Waits for Docker to be available
   - Copies `production.env.example` to `.env`
   - Updates `DOMAIN` and `HOME_IP` values
   - Modifies `docker-compose.yml` to enable/disable services

5. **Service Launch**: Starts services in background with `docker compose up -d`

6. **SSL Certificates**: Traefik automatically requests Let's Encrypt certificates (works because DNS is ready)

### Domain Variable Substitution

The `.env` file uses shell variable substitution for all domain-based values:

```bash
DOMAIN=yourdomain.com
ACME_EMAIL=admin@${DOMAIN}
N8N_HOST=n8n.${DOMAIN}
N8N_WEBHOOK_URL=webhook.${DOMAIN}
BASEROW_HOST=baserow.${DOMAIN}
# etc...
```

OpenTofu only needs to set `DOMAIN` once, and all services automatically use it. This keeps configuration DRY and makes it easy to change domains.

## File Structure

```
.
├── main.tf                    # Infrastructure resources and provisioning
├── variables.tf               # All configurable variables
├── outputs.tf                 # Information displayed after deployment
├── provider.tf                # OpenTofu and provider configuration
├── cloud-init.yaml            # Server initialization script
├── terraform.tfvars           # Your configuration (not in git)
├── terraform.tfvars.example   # Template for configuration
├── .gitignore                 # Protects secrets
└── README.md                  # This file
```

## Useful Commands

```bash
# See current infrastructure state
tofu show

# Get server IP and DNS records needed
tofu output public_ipv4
tofu output dns_records_needed

# Check which services are enabled
tofu state show null_resource.copy_env_file

# Enable a service
# Edit terraform.tfvars: enable_nocodb = true
tofu apply

# Disable a service  
# Edit terraform.tfvars: enable_nocodb = false
tofu apply

# Skip DNS check (if you want to set DNS later)
# Edit terraform.tfvars: wait_for_dns = false
tofu apply

# SSH to server
ssh -i ~/.ssh/id_ed25519_n8n_dev username@server-ip

# Check service status on server
docker compose -f /home/username/stack/docker-compose.yml ps

# View service logs
docker compose -f /home/username/stack/docker-compose.yml logs -f n8n

# View Traefik logs (SSL certificate issues)
docker compose -f /home/username/stack/docker-compose.yml logs -f traefik

# Restart all services
docker compose -f /home/username/stack/docker-compose.yml restart

# Destroy everything (be careful!)
tofu destroy

# Format code
tofu fmt

# Validate configuration
tofu validate
```

## Troubleshooting

### DNS Not Propagating

If OpenTofu is waiting for DNS:

**Check current DNS:**
```bash
dig @1.1.1.1 n8n.yourdomain.com +short
```

**Update DNS in your provider** (Cloudflare, Route53, etc.) to point to server IP

**DNS propagation typically takes 1-5 minutes**, but can be up to 30 minutes

**To skip DNS check and continue anyway:**
```bash
# Ctrl+C the current apply
# Edit terraform.tfvars: wait_for_dns = false
tofu apply
```

### Services Not Starting

**Check Docker status:**
```bash
ssh -i ~/.ssh/your_key user@server-ip
docker ps
docker compose -f ~/stack/docker-compose.yml ps
```

**View logs:**
```bash
docker compose -f ~/stack/docker-compose.yml logs -f
```

**If deployment appears stuck:**
- Containers may be running but Terraform provisioner waiting
- Safe to Ctrl+C and check server manually
- Re-run `tofu apply` to complete provisioning

### SSL Certificate Issues

**Symptoms**: "Your connection is not private" errors

**Causes**:
- DNS not pointing to server yet (check with `dig n8n.yourdomain.com`)
- Let's Encrypt rate limit hit (5 certs per domain per week)
- Port 80/443 not accessible
- Traefik started before DNS propagated

**Check Traefik logs:**
```bash
docker compose -f ~/stack/docker-compose.yml logs traefik | grep acme
```

**Force certificate renewal:**
```bash
# Remove acme.json and restart Traefik
docker compose -f ~/stack/docker-compose.yml down traefik
rm ~/stack/traefik/acme.json
docker compose -f ~/stack/docker-compose.yml up -d traefik
```

### Can't Access Services

**Check DNS:**
```bash
dig @1.1.1.1 n8n.yourdomain.com +short
nslookup n8n.yourdomain.com
```

Should return your server's IP address.

**Check firewall:**
```bash
curl -I http://server-ip
```

Should return HTTP response (redirects to HTTPS).

### Service Won't Enable

**Force recreation:**
```bash
tofu apply -replace="null_resource.copy_env_file"
```

This re-runs the provisioning logic.

### SSH Connection Refused

- Server might be rebooting (wait 2-3 minutes)
- Check your `home_ip` is correct: `curl ifconfig.me`
- Verify SSH key path in `terraform.tfvars`

### Docker Permission Denied

Log out and back in for group membership to take effect:
```bash
newgrp docker
```

## Adding New Services

To add a new service to the platform:

1. **Add variable** in `variables.tf`:
   ```terraform
   variable "enable_newservice" {
     description = "Enable NewService"
     type        = bool
     default     = false
   }
   ```

2. **Add to tfvars** in `terraform.tfvars`:
   ```terraform
   enable_newservice = false
   ```

3. **Add to services map** in `main.tf`:
   ```terraform
   services = {
     # ... existing services ...
     newservice = var.enable_newservice
   }
   ```

4. **Add to triggers** in `main.tf`:
   ```terraform
   triggers = {
     # ... existing triggers ...
     enable_newservice = var.enable_newservice
   }
   ```

5. **Create docker-compose file** in your docker repo:
   - `docker-compose.newservice.yml`
   - Add include line in main `docker-compose.yml`

6. **Add configuration** in `.env`:
   ```bash
   NEWSERVICE_HOST=newservice.${DOMAIN}
   # ... other newservice configs ...
   ```

## Cost Estimate

**Minimal Setup** (N8N only, cx23):
- Server: ~$5/month
- Traffic: 20TB included
- **Total: ~$5/month**

**Standard Setup** (N8N + 2 services, cx33):
- Server: ~$7/month
- Traffic: 20TB included
- **Total: ~$7/month**

**Full Stack** (All services, cx53):
- Server: ~$23/month
- Traffic: 20TB included
- **Total: ~$23/month**

Add ~20% for backups if enabled. All prices approximate, check [hetzner.com/cloud](https://www.hetzner.com/cloud) for current rates.

## Support & Community

Questions or issues? Join the Build & Automate community on [Skool](https://www.skool.com/build-automate)

## License

This configuration is provided as-is for use with your own infrastructure.
