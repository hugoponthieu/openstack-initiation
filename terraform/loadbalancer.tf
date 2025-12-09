# =============================================================================
# Load Balancer Tier (Octavia)
# Creates: Load Balancer, Listener, Pool, Health Monitor, Pool Members, Floating IP
# Note: Using openstack_lb_* resources which work with Octavia
# =============================================================================

# -----------------------------------------------------------------------------
# Load Balancer
# -----------------------------------------------------------------------------
resource "openstack_lb_loadbalancer_v2" "web_api_lb" {
  name               = "${var.project_name}-lb"
  vip_subnet_id      = openstack_networking_subnet_v2.private_subnet.id
  loadbalancer_provider = "octavia"

  depends_on = [
    openstack_networking_router_interface_v2.router_interface
  ]
}

# -----------------------------------------------------------------------------
# Listener
# -----------------------------------------------------------------------------
resource "openstack_lb_listener_v2" "web_api_listener" {
  name            = "${var.project_name}-listener"
  protocol        = "HTTP"
  protocol_port   = 80
  loadbalancer_id = openstack_lb_loadbalancer_v2.web_api_lb.id
}

# -----------------------------------------------------------------------------
# Pool
# -----------------------------------------------------------------------------
resource "openstack_lb_pool_v2" "web_api_pool" {
  name        = "${var.project_name}-pool"
  protocol    = "HTTP"
  lb_method   = "ROUND_ROBIN"
  listener_id = openstack_lb_listener_v2.web_api_listener.id
}

# -----------------------------------------------------------------------------
# Health Monitor
# -----------------------------------------------------------------------------
resource "openstack_lb_monitor_v2" "web_api_monitor" {
  name        = "${var.project_name}-health-monitor"
  pool_id     = openstack_lb_pool_v2.web_api_pool.id
  type        = "HTTP"
  delay       = 5
  timeout     = 3
  max_retries = 3
  url_path    = "/health"
}

# -----------------------------------------------------------------------------
# Pool Members
# -----------------------------------------------------------------------------
resource "openstack_lb_member_v2" "web_api_member" {
  count         = var.web_instance_count
  name          = "${var.project_name}-member-${count.index + 1}"
  pool_id       = openstack_lb_pool_v2.web_api_pool.id
  address       = openstack_compute_instance_v2.web_api[count.index].access_ip_v4
  protocol_port = 80
  subnet_id     = openstack_networking_subnet_v2.private_subnet.id
}

# -----------------------------------------------------------------------------
# Floating IP for Load Balancer
# -----------------------------------------------------------------------------
resource "openstack_networking_floatingip_v2" "lb_floating_ip" {
  pool = var.public_net
}

resource "openstack_networking_floatingip_associate_v2" "lb_floating_ip_assoc" {
  floating_ip = openstack_networking_floatingip_v2.lb_floating_ip.address
  port_id     = openstack_lb_loadbalancer_v2.web_api_lb.vip_port_id
}

