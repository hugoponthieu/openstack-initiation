# =============================================================================
# Network Infrastructure
# Creates: Private Network, Subnet, Router, and Router Interface
# =============================================================================

# -----------------------------------------------------------------------------
# Private Network
# -----------------------------------------------------------------------------
resource "openstack_networking_network_v2" "private_net" {
  name           = "${var.project_name}-private-network"
  admin_state_up = true
}

# -----------------------------------------------------------------------------
# Private Subnet
# -----------------------------------------------------------------------------
resource "openstack_networking_subnet_v2" "private_subnet" {
  name            = "${var.project_name}-private-subnet"
  network_id      = openstack_networking_network_v2.private_net.id
  cidr            = var.private_net_cidr
  gateway_ip      = var.private_net_gateway
  ip_version      = 4
  dns_nameservers = var.dns_nameservers

  allocation_pool {
    start = var.private_net_pool_start
    end   = var.private_net_pool_end
  }
}

# -----------------------------------------------------------------------------
# Router (connects private network to public network)
# -----------------------------------------------------------------------------
data "openstack_networking_network_v2" "public_net" {
  name = var.public_net
}

resource "openstack_networking_router_v2" "router" {
  name                = "${var.project_name}-router"
  admin_state_up      = true
  external_network_id = data.openstack_networking_network_v2.public_net.id
}

# -----------------------------------------------------------------------------
# Router Interface
# -----------------------------------------------------------------------------
resource "openstack_networking_router_interface_v2" "router_interface" {
  router_id = openstack_networking_router_v2.router.id
  subnet_id = openstack_networking_subnet_v2.private_subnet.id
}

