# =============================================================================
# Security Groups
# Creates: Web API Security Group and Database Security Group
# =============================================================================

# -----------------------------------------------------------------------------
# Web API Security Group
# Allows: HTTP (80), SSH (22), ICMP
# -----------------------------------------------------------------------------
resource "openstack_networking_secgroup_v2" "web_api_sg" {
  name        = "${var.project_name}-web-api-sg"
  description = "Security group for web API servers"
}

resource "openstack_networking_secgroup_rule_v2" "web_api_http" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 80
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.web_api_sg.id
}

resource "openstack_networking_secgroup_rule_v2" "web_api_ssh" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.web_api_sg.id
}

resource "openstack_networking_secgroup_rule_v2" "web_api_icmp" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.web_api_sg.id
}

# -----------------------------------------------------------------------------
# Database Security Group
# Allows: PostgreSQL (5432) from Web API SG, SSH (22), ICMP
# -----------------------------------------------------------------------------
resource "openstack_networking_secgroup_v2" "database_sg" {
  name        = "${var.project_name}-database-sg"
  description = "Security group for database server"
}

resource "openstack_networking_secgroup_rule_v2" "database_postgres" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 5432
  port_range_max    = 5432
  remote_group_id   = openstack_networking_secgroup_v2.web_api_sg.id
  security_group_id = openstack_networking_secgroup_v2.database_sg.id
}

resource "openstack_networking_secgroup_rule_v2" "database_ssh" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.database_sg.id
}

resource "openstack_networking_secgroup_rule_v2" "database_icmp" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.database_sg.id
}

