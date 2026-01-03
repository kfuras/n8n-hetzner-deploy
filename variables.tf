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

# Database & Core Environment
variable "postgres_user" {
  description = "PostgreSQL user"
  type        = string
  default     = "n8n_postgres_user"
}

variable "postgres_db" {
  description = "PostgreSQL database name"
  type        = string
  default     = "n8n_core"
}

variable "acme_email" {
  description = "Email for Let's Encrypt"
  type        = string
  default     = null
}

variable "generic_timezone" {
  description = "Server timezone"
  type        = string
  default     = "UTC"
}

variable "compose_project_name" {
  description = "Docker Compose project name"
  type        = string
  default     = "n8n-core"
}

# N8N Configuration
variable "n8n_host" {
  description = "N8N hostname"
  type        = string
  default     = null
}

variable "n8n_webhook" {
  description = "N8N webhook hostname"
  type        = string
  default     = null
}

variable "n8n_basic_auth_active" {
  description = "Enable N8N basic auth"
  type        = bool
  default     = true
}

variable "n8n_basic_auth_user" {
  description = "N8N basic auth username"
  type        = string
  default     = "admin"
}

variable "n8n_protocol" {
  description = "N8N protocol (http or https)"
  type        = string
  default     = "https"
}

variable "n8n_port" {
  description = "N8N port"
  type        = number
  default     = 5678
}

# App toggles
variable "enable_baserow" {
  description = "Deploy BaseRow"
  type        = bool
  default     = false
}

variable "enable_nocodb" {
  description = "Deploy NocoDB"
  type        = bool
  default     = false
}

variable "enable_minio" {
  description = "Deploy MinIO"
  type        = bool
  default     = false
}

variable "enable_kokoro_tts" {
  description = "Deploy Kokoro TTS"
  type        = bool
  default     = false
}

variable "enable_nca_toolkit" {
  description = "Deploy NCA Toolkit"
  type        = bool
  default     = false
}

variable "enable_postiz" {
  description = "Deploy Postiz"
  type        = bool
  default     = false
}

# NocoDB
variable "nocodb_user" {
  description = "NocoDB database user"
  type        = string
  default     = "postgres"
}

variable "nocodb_password" {
  description = "NocoDB database password"
  type        = string
  sensitive   = true
  default     = ""
}

variable "nocodb_db" {
  description = "NocoDB database name"
  type        = string
  default     = "nocodb"
}

# MinIO
variable "minio_root_user" {
  description = "MinIO root user"
  type        = string
  default     = "minioadmin"
}

variable "minio_console_host" {
  description = "MinIO console hostname"
  type        = string
  default     = ""
}

variable "minio_api_host" {
  description = "MinIO API hostname"
  type        = string
  default     = ""
}

variable "minio_root_password" {
  description = "MinIO root password"
  type        = string
  sensitive   = true
  default     = ""
}

variable "nca_bucket_name" {
  description = "MinIO bucket name for NCA Toolkit"
  type        = string
  default     = "nca-toolkit"
}

# NCA Toolkit
variable "nca_api_key" {
  description = "NCA Toolkit API key"
  type        = string
  sensitive   = true
  default     = ""
}

variable "nca_s3_access_key" {
  description = "NCA S3 access key"
  type        = string
  sensitive   = true
  default     = ""
}

variable "nca_s3_secret_key" {
  description = "NCA S3 secret key"
  type        = string
  sensitive   = true
  default     = ""
}

variable "nca_host" {
  description = "NCA Toolkit hostname"
  type        = string
  default     = ""
}

# Postiz
variable "postiz_db_user" {
  description = "Postiz database user"
  type        = string
  default     = "postiz-user"
}

variable "postiz_db_name" {
  description = "Postiz database name"
  type        = string
  default     = "postiz-db-local"
}

variable "postiz_db_password" {
  description = "Postiz database password"
  type        = string
  sensitive   = true
  default     = ""
}

variable "postiz_jwt_secret" {
  description = "Postiz JWT secret"
  type        = string
  sensitive   = true
  default     = ""
}

variable "postiz_host" {
  description = "Postiz hostname"
  type        = string
  default     = ""
}

# BaseRow
variable "baserow_host" {
  description = "BaseRow hostname"
  type        = string
  default     = ""
}

variable "baserow_secret_key" {
  description = "BaseRow secret key"
  type        = string
  sensitive   = true
  default     = ""
}

variable "baserow_password" {
  description = "BaseRow database password"
  type        = string
  sensitive   = true
  default     = ""
}

variable "baserow_redis_password" {
  description = "BaseRow Redis password"
  type        = string
  sensitive   = true
  default     = ""
}

variable "baserow_caddy_addresses" {
  description = "BaseRow Caddy addresses"
  type        = string
  default     = ":80"
}

variable "baserow_s3_access_key" {
  description = "BaseRow S3 access key"
  type        = string
  default     = "admin"
}

variable "baserow_s3_secret_key" {
  description = "BaseRow S3 secret key"
  type        = string
  sensitive   = true
  default     = ""
}

variable "baserow_s3_bucket" {
  description = "BaseRow S3 bucket name"
  type        = string
  default     = "baserow"
}

variable "baserow_s3_region" {
  description = "BaseRow S3 region"
  type        = string
  default     = "us-east-1"
}