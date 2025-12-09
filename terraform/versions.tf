# Terraform and Provider Versions
terraform {
  required_version = ">= 1.0.0"

  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.54"
    }
  }
}

# OpenStack Provider Configuration
# Credentials are sourced from environment variables (OS_* from openrc file)
provider "openstack" {
  # Authentication is handled via environment variables:
  # OS_AUTH_URL, OS_PROJECT_NAME, OS_USERNAME, OS_PASSWORD, etc.
  # Source your openrc file before running terraform: source ~/duratm-openrc.sh

  # Skip TLS certificate verification (for self-signed certificates)
  insecure = true
}

