output "server_name" {
  description = "Server hostname"
  value       = hcloud_server.main.name
}

output "server_id" {
  description = "Server ID"
  value       = hcloud_server.main.id
}

output "public_ipv4" {
  description = "Public IPv4 address"
  value       = hcloud_server.main.ipv4_address
}

output "public_ipv6" {
  description = "Public IPv6 address"
  value       = hcloud_server.main.ipv6_address
}

output "status" {
  description = "Server status"
  value       = hcloud_server.main.status
}

output "ssh_command" {
  description = "SSH command to connect"
  value       = "ssh -i ${replace(var.ssh_key_path, ".pub", "")} ${var.username}@${hcloud_server.main.ipv4_address}"
}

output "domain" {
  description = "Domain name for services"
  value       = var.domain
}

output "dns_records_needed" {
  description = "DNS records to create in your DNS provider (point these to the server IP)"
  value = {
    domain       = var.domain
    server_ip    = hcloud_server.main.ipv4_address
    instructions = "Create A records pointing to ${hcloud_server.main.ipv4_address} for:"
    subdomains = concat(
      ["n8n.${var.domain}"],
      var.enable_baserow ? ["baserow.${var.domain}"] : [],
      var.enable_nocodb ? ["nocodb.${var.domain}"] : [],
      var.enable_minio ? ["minio.${var.domain}", "minio-console.${var.domain}"] : [],
      var.enable_nca_toolkit ? ["nca-toolkit.${var.domain}"] : [],
      var.enable_kokoro_tts ? ["kokoro-tts.${var.domain}"] : [],
      var.enable_postiz ? ["postiz.${var.domain}"] : []
    )
  }
}