output "next_steps" {
  description = "Next steps after infrastructure is created"
  value       = <<-EOT
    Infrastructure created successfully!
    
    Server IP: ${hcloud_server.main.ipv4_address}
    SSH: ssh -i ${replace(var.ssh_key_path, ".pub", "")} ${var.username}@${hcloud_server.main.ipv4_address}
    
    Next steps:
    
    1. Add DNS wildcard record:
      *.${var.domain} → ${hcloud_server.main.ipv4_address}
    
    2. Enable services (optional):
      code ../ansible/group_vars/services.yml
      # Set enabled: true for nocodb, minio, etc.
    
    3. Deploy (from project root):
      cd ..
      make install-requirements
      make deploy
    
    4. Access N8N:
      https://n8n.${var.domain}
    
    Daily commands:
      make services     - Show running services
      make logs service=n8n - View logs
      make restart      - Restart all services
      make backup       - Backup databases
  EOT
}
