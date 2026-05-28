# Upload SSH keys
resource "hcloud_ssh_key" "main" {
  name       = "${var.server_name}-main-key"
  public_key = file(var.ssh_key_path)
}

resource "hcloud_ssh_key" "extra" {
  count      = length(var.extra_ssh_keys)
  name       = "${var.server_name}-${element(split(" ", var.extra_ssh_keys[count.index]), 2)}-key"
  public_key = var.extra_ssh_keys[count.index]
}

# Firewall rules
resource "hcloud_firewall" "main" {
  name = "${var.server_name}-firewall"

  rule {
    description = "Allow SSH from Home IP"
    direction   = "in"
    port        = "22"
    protocol    = "tcp"
    source_ips  = [var.home_ip]
  }

  rule {
    description = "Allow HTTP"
    direction   = "in"
    port        = "80"
    protocol    = "tcp"
    source_ips  = ["0.0.0.0/0", "::/0"]
  }

  rule {
    description = "Allow HTTPS"
    direction   = "in"
    port        = "443"
    protocol    = "tcp"
    source_ips  = ["0.0.0.0/0", "::/0"]
  }
}

# Generate cloud-init script
locals {
  cloud_init_content = templatefile("${path.module}/cloud-init.yaml", {
    username        = var.username
    ssh_public_keys = concat([file(var.ssh_key_path)], var.extra_ssh_keys)
  })
}

# Create server
resource "hcloud_server" "main" {
  name        = var.server_name
  image       = var.image
  server_type = var.server_type
  location    = var.location
  ssh_keys    = concat([hcloud_ssh_key.main.id], hcloud_ssh_key.extra[*].id)
  backups     = var.enable_backups
  user_data   = local.cloud_init_content

  labels = {
    environment = "development"
    managed_by  = "opentofu"
  }

  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }
}

# Attach firewall
resource "hcloud_firewall_attachment" "main" {
  count       = var.enable_firewall ? 1 : 0
  firewall_id = hcloud_firewall.main.id
  server_ids  = [hcloud_server.main.id]
}

# Auto-generate Ansible inventory
resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/ansible-inventory.tpl", {
    server_ip    = hcloud_server.main.ipv4_address
    username     = var.username
    ssh_key_path = replace(var.ssh_key_path, ".pub", "")
  })
  filename        = "${path.module}/../ansible/inventory.yml"
  file_permission = "0644"
}

# Auto-generate Ansible infrastructure variables
# Service configuration is in ansible/group_vars/all/services.yml (user-managed, never touched by Terraform)
resource "local_file" "ansible_infrastructure" {
  content = templatefile("${path.module}/ansible-infrastructure.tpl", {
    domain      = var.domain
    home_ip     = replace(var.home_ip, "/32", "")
    github_org  = var.github_org
    github_repo = var.github_repo
    username    = var.username
  })
  filename        = "${path.module}/../ansible/group_vars/all/infrastructure.yml"
  file_permission = "0644"
}