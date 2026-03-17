variable "hcloud_token" {
  description = "Hetzner Cloud API Token"
  type        = string
  sensitive   = true
}

variable "ssh_key_path" {
  description = "Path to your SSH public key"
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}

variable "extra_ssh_keys" {
  description = "Additional SSH public keys to authorize (besides ssh_key_path)"
  type        = list(string)
  default     = []
}

variable "server_name" {
  description = "Name for the server"
  type        = string
  default     = "main-server-1"
}

variable "server_type" {
  description = "Server type (cx23, cx33, etc)"
  type        = string
  default     = "cx23"
}

variable "location" {
  description = "Server location"
  type        = string
  default     = "hel1"
}

variable "image" {
  description = "OS image"
  type        = string
  default     = "ubuntu-24.04"
}

variable "enable_firewall" {
  description = "Enable firewall rules"
  type        = bool
  default     = true
}

variable "enable_backups" {
  description = "Enable automatic backups"
  type        = bool
  default     = false
}

variable "home_ip" {
  description = "Your home IP for SSH access"
  type        = string
}

variable "username" {
  description = "Username for server"
  type        = string
  default     = "kaf"
}

# GitHub Configuration
variable "github_org" {
  description = "GitHub organization"
  type        = string
  default     = "build-automate"
}

variable "github_repo" {
  description = "GitHub repository with Docker compose"
  type        = string
  default     = "n8n-production-platform"
}

variable "github_pat" {
  description = "Fine-grained GitHub PAT (read-only to repo)"
  type        = string
  sensitive   = true
}

# Domain Configuration
variable "domain" {
  description = "Base domain for all services"
  type        = string
}
