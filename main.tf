# Upload SSH key
resource "hcloud_ssh_key" "main" {
  name       = "${var.server_name}-key"
  public_key = file(var.ssh_key_path)
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
    username       = var.username
    ssh_public_key = file(var.ssh_key_path)
    github_org     = var.github_org
    github_repo    = var.github_repo
    github_pat     = var.github_pat
  })

  # Map of all services with their enable status
  services = {
    baserow     = var.enable_baserow
    nocodb      = var.enable_nocodb
    minio       = var.enable_minio
    nca-toolkit = var.enable_nca_toolkit
    kokoro-tts  = var.enable_kokoro_tts
    postiz      = var.enable_postiz
  }

  # Build sed commands: uncomment enabled services, comment disabled ones
  service_commands = [
    for name, enabled in local.services :
    enabled
    ? "sed -i 's|^#  - docker-compose.${name}.yml|  - docker-compose.${name}.yml|' /home/${var.username}/stack/docker-compose.yml"
    : "sed -i 's|^  - docker-compose.${name}.yml|#  - docker-compose.${name}.yml|' /home/${var.username}/stack/docker-compose.yml"
  ]
}

# Create server
resource "hcloud_server" "main" {
  name        = var.server_name
  image       = var.image
  server_type = var.server_type
  location    = var.location
  ssh_keys    = [hcloud_ssh_key.main.id]
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

# Wait for DNS to propagate before starting services
resource "null_resource" "wait_for_dns" {
  count      = var.wait_for_dns ? 1 : 0
  depends_on = [hcloud_server.main]

  triggers = {
    server_id          = hcloud_server.main.id
    domain             = var.domain
    enable_baserow     = var.enable_baserow
    enable_nocodb      = var.enable_nocodb
    enable_minio       = var.enable_minio
    enable_nca_toolkit = var.enable_nca_toolkit
    enable_kokoro_tts  = var.enable_kokoro_tts
    enable_postiz      = var.enable_postiz
  }

  provisioner "local-exec" {
    command = <<-EOT
      #!/bin/bash
      set -e
      
      SERVER_IP="${hcloud_server.main.ipv4_address}"
      DOMAIN="${var.domain}"
      
      echo "Checking DNS propagation for $DOMAIN..."
      
      # Build list of enabled services
      SERVICES=("n8n")
      ${var.enable_baserow ? "SERVICES+=(\"baserow\")" : ""}
      ${var.enable_nocodb ? "SERVICES+=(\"nocodb\")" : ""}
      ${var.enable_minio ? "SERVICES+=(\"minio\" \"minio-console\")" : ""}
      ${var.enable_nca_toolkit ? "SERVICES+=(\"nca-toolkit\")" : ""}
      ${var.enable_kokoro_tts ? "SERVICES+=(\"kokoro-tts\")" : ""}
      ${var.enable_postiz ? "SERVICES+=(\"postiz\")" : ""}
      
      MAX_ATTEMPTS=60
      ATTEMPT=0
      
      while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
        ALL_RESOLVED=true
        
        for service in "$${SERVICES[@]}"; do
          FQDN="$service.$DOMAIN"
          RESOLVED_IP=$(dig +short "$FQDN" @1.1.1.1 2>/dev/null | head -n1)
          
          if [ "$RESOLVED_IP" != "$SERVER_IP" ]; then
            ALL_RESOLVED=false
            if [ $ATTEMPT -eq 0 ]; then
              echo "  Waiting for $FQDN → $SERVER_IP"
            fi
          fi
        done
        
        if [ "$ALL_RESOLVED" = true ]; then
          echo "DNS verified - all records point to $SERVER_IP"
          exit 0
        fi
        
        ATTEMPT=$((ATTEMPT + 1))
        
        if [ $ATTEMPT -lt $MAX_ATTEMPTS ]; then
          sleep 30
        else
          echo "Timeout: DNS not fully propagated. Continuing anyway..."
        fi
      done
      
      exit 0
    EOT
    
    interpreter = ["/bin/bash", "-c"]
  }
}

# Wait for repo to be cloned and Docker ready, then configure
resource "null_resource" "copy_env_file" {
  depends_on = [
    hcloud_server.main,
    null_resource.wait_for_dns
  ]

  # Re-run provisioner when any of these values change
  triggers = {
    server_id          = hcloud_server.main.id
    domain             = var.domain
    home_ip            = var.home_ip
    enable_baserow     = var.enable_baserow
    enable_nocodb      = var.enable_nocodb
    enable_minio       = var.enable_minio
    enable_kokoro_tts  = var.enable_kokoro_tts
    enable_nca_toolkit = var.enable_nca_toolkit
    enable_postiz      = var.enable_postiz
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Waiting for Docker and repo to be ready...'",
      "timeout 600 bash -c 'until [ -d /home/${var.username}/stack ] && docker ps &>/dev/null; do sleep 10; done'",
      "echo 'System ready for file transfer'"
    ]

    connection {
      type        = "ssh"
      user        = var.username
      private_key = file(replace(var.ssh_key_path, ".pub", ""))
      host        = hcloud_server.main.ipv4_address
      timeout     = "15m"
    }
  }

  provisioner "remote-exec" {
    inline = concat(
      [
        # Copy env files from repo to working location
        "cp /home/${var.username}/stack/secrets/production.env.example /home/${var.username}/stack/.env",
        "chmod 600 /home/${var.username}/stack/.env",
        # Update DOMAIN value - all other vars use ${DOMAIN} automatically
        "sed -i 's|DOMAIN=yourdomain.com|DOMAIN=${var.domain}|g' /home/${var.username}/stack/.env",
        "sed -i 's|HOME_IP=192.168.1.100|HOME_IP=${replace(var.home_ip, "/32", "")}|g' /home/${var.username}/stack/.env",
      ],
      # Toggle services based on enable flags
      local.service_commands,
      [
        "cd /home/${var.username}/stack && docker compose up -d --remove-orphans"
      ]
    )

    connection {
      type        = "ssh"
      user        = var.username
      private_key = file(replace(var.ssh_key_path, ".pub", ""))
      host        = hcloud_server.main.ipv4_address
      timeout     = "5m"
    }
  }
}

# Copy postiz env file to server (conditional)
resource "null_resource" "copy_postiz_env_file" {
  count      = var.enable_postiz ? 1 : 0
  depends_on = [null_resource.copy_env_file]

  provisioner "remote-exec" {
    inline = [
      "cp /home/${var.username}/stack/postiz.env.example /home/${var.username}/stack/postiz.env",
      "chmod 600 /home/${var.username}/stack/postiz.env",
      "sed -i 's|yourdomain.com|${var.domain}|g' /home/${var.username}/stack/postiz.env",
      "cd /home/${var.username}/stack && docker compose up -d"
    ]

    connection {
      type        = "ssh"
      user        = var.username
      private_key = file(replace(var.ssh_key_path, ".pub", ""))
      host        = hcloud_server.main.ipv4_address
      timeout     = "5m"
    }
  }
}