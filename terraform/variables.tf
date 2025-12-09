# =============================================================================
# Input Variables for 3-Tier Web API Infrastructure
# =============================================================================

# -----------------------------------------------------------------------------
# Compute Variables
# -----------------------------------------------------------------------------
variable "key_name" {
  description = "Name of keypair to assign to servers"
  type        = string
  default     = "duratm"
}

variable "image" {
  description = "Name of image to use for servers"
  type        = string
  default     = "ubuntu-noble"
}

variable "web_flavor" {
  description = "Flavor to use for web API servers"
  type        = string
  default     = "m1.small"
}

variable "db_flavor" {
  description = "Flavor to use for database server"
  type        = string
  default     = "m1.medium"
}

variable "web_instance_count" {
  description = "Number of web API instances to deploy"
  type        = number
  default     = 2
}

# -----------------------------------------------------------------------------
# Network Variables
# -----------------------------------------------------------------------------
variable "public_net" {
  description = "Name or ID of public network for floating IP allocations"
  type        = string
  default     = "public"
}

variable "private_net_cidr" {
  description = "Private network address (CIDR notation)"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_net_gateway" {
  description = "Private network gateway address"
  type        = string
  default     = "10.0.1.1"
}

variable "private_net_pool_start" {
  description = "Start of private network IP address allocation pool"
  type        = string
  default     = "10.0.1.10"
}

variable "private_net_pool_end" {
  description = "End of private network IP address allocation pool"
  type        = string
  default     = "10.0.1.200"
}

variable "dns_nameservers" {
  description = "DNS nameservers for the private subnet"
  type        = list(string)
  default     = ["8.8.8.8", "8.8.4.4"]
}

# -----------------------------------------------------------------------------
# Database Variables
# -----------------------------------------------------------------------------
variable "db_name" {
  description = "Database name"
  type        = string
  default     = "apidb"
}

variable "db_user" {
  description = "Database username"
  type        = string
  default     = "apiuser"
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
  default     = "SecurePassword123!"
}

# -----------------------------------------------------------------------------
# Naming Variables
# -----------------------------------------------------------------------------
variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "web-api"
}

