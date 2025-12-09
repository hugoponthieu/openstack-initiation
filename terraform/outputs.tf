# =============================================================================
# Outputs
# =============================================================================

# -----------------------------------------------------------------------------
# Load Balancer Outputs
# -----------------------------------------------------------------------------
output "loadbalancer_floating_ip" {
  description = "Floating IP address of the load balancer"
  value       = openstack_networking_floatingip_v2.lb_floating_ip.address
}

output "loadbalancer_url" {
  description = "URL to access the load balanced web API"
  value       = "http://${openstack_networking_floatingip_v2.lb_floating_ip.address}/"
}

output "api_data_url" {
  description = "URL to access database data through the API"
  value       = "http://${openstack_networking_floatingip_v2.lb_floating_ip.address}/api/data"
}

# -----------------------------------------------------------------------------
# Web API Server Outputs
# -----------------------------------------------------------------------------
output "web_api_server_ips" {
  description = "Private IP addresses of web API servers"
  value       = openstack_compute_instance_v2.web_api[*].access_ip_v4
}

output "web_api_server_names" {
  description = "Names of web API servers"
  value       = openstack_compute_instance_v2.web_api[*].name
}

# -----------------------------------------------------------------------------
# Database Outputs
# -----------------------------------------------------------------------------
output "database_server_ip" {
  description = "Private IP address of database server"
  value       = openstack_compute_instance_v2.database.access_ip_v4
}

output "database_connection_string" {
  description = "PostgreSQL connection string"
  value       = "postgresql://${var.db_user}:${var.db_password}@${openstack_compute_instance_v2.database.access_ip_v4}/${var.db_name}"
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Network Outputs
# -----------------------------------------------------------------------------
output "private_network_id" {
  description = "ID of the private network"
  value       = openstack_networking_network_v2.private_net.id
}

output "private_subnet_id" {
  description = "ID of the private subnet"
  value       = openstack_networking_subnet_v2.private_subnet.id
}

output "router_id" {
  description = "ID of the router"
  value       = openstack_networking_router_v2.router.id
}

