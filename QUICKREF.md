# Command Quick Reference

> **For setup instructions, see [README.md](README.md)**

---

## Daily Operations

```bash
# View running services
make services

# View logs
make logs service=n8n
make logs service=traefik
make logs service=postgres
# Note: Shows last 100 lines with color-coded errors (red) and info (green)

# Follow logs in real-time (use SSH directly, Ctrl+C to exit)
# ssh -i ~/.ssh/id_ed25519_n8n_dev kaf@SERVER_IP "cd stack && docker compose logs -f SERVICE"

# Restart services
make restart                   # All services
make restart service=n8n       # Single service

# Update deployment
make deploy                    # Full deployment (adding services, config changes, when in doubt)
make update                    # Quick update (only changed docker-compose files)

# Backup databases
make backup

# Test connection
make ping
```

---

## Service Names

For use with `make logs service=X` and `make restart service=X`:

- `n8n` - Workflow automation
- `postgres` - Database
- `redis` - Cache
- `traefik` - Reverse proxy
- `baserow` - Airtable alternative (optional)
- `nocodb` - Airtable alternative (optional)
- `minio` - Object storage (optional)
- `postiz` - Social media management (optional)
- `nca-toolkit` - Neural character animation (optional)
- `kokoro-tts` - Text-to-speech (optional)

---

## Direct Ansible

```bash
cd ansible

# Full deployment
ansible-playbook playbooks/site.yml

# View logs
ansible-playbook playbooks/logs.yml -e "service=n8n"

# Restart services
ansible-playbook playbooks/restart.yml
ansible-playbook playbooks/restart.yml -e "service=traefik"

# Update from git
ansible-playbook playbooks/update.yml

# Backup
ansible-playbook playbooks/backup.yml

# Ad-hoc commands
ansible all -m ping
ansible all -m shell -a "docker ps"
ansible all -m shell -a "cd ~/stack && docker compose ps"
```

---

## Infrastructure Management

```bash
cd opentofu

# View current state
tofu show
tofu output
tofu output public_ipv4

# Make changes
code terraform.tfvars
tofu plan
tofu apply

# Destroy everything
tofu destroy
```

---

## SSH & On-Server

```bash
# SSH to server
ssh -i ~/.ssh/id_ed25519_n8n user@server-ip

# Once connected:
cd ~/stack

# Docker commands
docker compose ps
docker compose logs -f n8n
docker compose logs traefik | grep acme
docker compose restart
docker compose restart traefik
docker compose down
docker compose up -d

# Check environment
cat .env
cat .env | grep -v "^#" | grep -v "^$"

# Check git status
git status
git log --oneline -5
```

---

## Backup & Restore

**Backup Strategy:**

**Option 1: Hetzner Snapshots (Recommended for disaster recovery)**
- Backs up entire server disk
- Easy full server restoration
- Configure in `opentofu/terraform.tfvars`: `enable_backups = true`
- Best for: Complete server failures, testing major changes

**Option 2: Database Backups (For selective restore/migration)**
- Backs up just databases and secrets
- Useful for: Moving to different server, restoring specific data, point-in-time recovery

**What gets backed up with `make backup`:**
- All PostgreSQL containers (separate container per service: n8n, nocodb, baserow, postiz, etc.)
- `.env` file (encryption keys and secrets)
- MinIO data (if MinIO is enabled)

**What requires manual backup:**
- Traefik SSL certificates: `~/stack/traefik/acme.json` (but Let's Encrypt can regenerate these)

```bash
# Create database backup
make backup

# Download backups from server
scp -i ~/.ssh/id_ed25519_n8n user@server-ip:/opt/backups/postgres_*.sql.gz ./
scp -i ~/.ssh/id_ed25519_n8n user@server-ip:/opt/backups/env_*.backup ./
scp -i ~/.ssh/id_ed25519_n8n user@server-ip:/opt/backups/minio_* ./ -r  # if MinIO enabled

# Upload backup to new server
scp -i ~/.ssh/id_ed25519_n8n backup.sql.gz user@server-ip:/tmp/
scp -i ~/.ssh/id_ed25519_n8n env_backup.backup user@server-ip:/tmp/

# Restore backup (on server)
ssh -i ~/.ssh/id_ed25519_n8n user@server-ip
cd ~/stack
# First restore .env (contains encryption keys!)
cp /tmp/env_backup.backup .env
# Then restore database
gunzip < /tmp/backup.sql.gz | docker compose exec -T postgres psql -U postgres
docker compose restart
```

**⚠️ CRITICAL:** The `.env` backup contains `N8N_ENCRYPTION_KEY` and other secrets. Without it, the database restore is useless (n8n can't decrypt credentials).

---

## Troubleshooting

```bash
# Check DNS
dig @1.1.1.1 n8n.yourdomain.com +short

# Get server IP
cd opentofu && tofu output public_ipv4

# View all logs
make logs service=n8n
make logs service=traefik
make logs service=postgres

# Check service status
make services

# Force restart
ssh -i ~/.ssh/id_ed25519_n8n user@server-ip
cd ~/stack && docker compose restart

# Check SSL certificates
ssh -i ~/.ssh/id_ed25519_n8n user@server-ip
cd ~/stack && docker compose logs traefik | grep acme

# Re-run deployment
cd ansible && ansible-playbook playbooks/site.yml
```

---

## Enable/Disable Services

```bash
# 1. Edit configuration
code ansible/group_vars/all.yml

# Set enabled: true or enabled: false for each service:
services:
  nocodb:
    enabled: true
  minio:
    enabled: false

# 2. Redeploy
make deploy
```

---

## File Locations

### Local
```
opentofu/terraform.tfvars      # Infrastructure config
ansible/inventory.yml          # Server connection (auto-generated)
ansible/group_vars/all.yml     # Services config (auto-generated)
```

### On Server
```
~/stack/.env                   # Secrets & environment
~/stack/docker-compose.yml     # Service definitions
~/stack/traefik/acme.json      # SSL certificates
/opt/backups/                  # Database backups
```

---

## DNS Configuration

**Option 1: Wildcard (recommended)**
```
A    *.yourdomain.com → server-ip
```

**Option 2: Individual records**
```
A    n8n.yourdomain.com → server-ip
A    nocodb.yourdomain.com → server-ip
A    minio.yourdomain.com → server-ip
A    minio-data.yourdomain.com → server-ip
# Add for each enabled service
```
