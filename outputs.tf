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

output "cloudflare_dns_update_command" {
  description = "Command to update Cloudflare DNS (run from cloudflare-dns directory)"
  value       = "cd ~/code/cloudflare-dns && tofu apply --auto-approve"
}