# =============================================================================
# Database Tier
# Creates: PostgreSQL Database Instance with Port
# =============================================================================

# -----------------------------------------------------------------------------
# Database Port
# -----------------------------------------------------------------------------
resource "openstack_networking_port_v2" "database_port" {
  name           = "${var.project_name}-database-port"
  network_id     = openstack_networking_network_v2.private_net.id
  admin_state_up = true

  security_group_ids = [
    openstack_networking_secgroup_v2.database_sg.id
  ]

  fixed_ip {
    subnet_id = openstack_networking_subnet_v2.private_subnet.id
  }
}

# -----------------------------------------------------------------------------
# Database User Data Script
# -----------------------------------------------------------------------------
locals {
  database_user_data = <<-EOF
    #!/bin/bash
    set -e

    # Update system
    export DEBIAN_FRONTEND=noninteractive
    apt-get update
    apt-get upgrade -y

    # Install PostgreSQL
    apt-get install -y postgresql postgresql-contrib

    # Wait for PostgreSQL to be ready
    sleep 5

    # Configure PostgreSQL
    sudo -u postgres psql -c "CREATE DATABASE ${var.db_name};"
    sudo -u postgres psql -c "CREATE USER ${var.db_user} WITH PASSWORD '${var.db_password}';"
    sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE ${var.db_name} TO ${var.db_user};"

    # Create sample table and data
    sudo -u postgres psql -d ${var.db_name} -c "CREATE TABLE items (id SERIAL PRIMARY KEY, name VARCHAR(100), description TEXT, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP);"
    sudo -u postgres psql -d ${var.db_name} -c "GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO ${var.db_user};"
    sudo -u postgres psql -d ${var.db_name} -c "GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO ${var.db_user};"
    sudo -u postgres psql -d ${var.db_name} -c "INSERT INTO items (name, description) VALUES ('Sample Item 1', 'This is a test item from the database'), ('Sample Item 2', 'Another test item'), ('Sample Item 3', 'Yet another test item');"

    # Configure PostgreSQL to accept connections from private network
    echo "host    all             all             10.0.1.0/24             md5" >> /etc/postgresql/*/main/pg_hba.conf
    sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" /etc/postgresql/*/main/postgresql.conf

    # Restart PostgreSQL
    systemctl restart postgresql
    systemctl enable postgresql

    # Create status file
    echo "PostgreSQL setup completed at $(date)" > /var/log/db-setup-complete.log
  EOF
}

# -----------------------------------------------------------------------------
# Database Instance
# -----------------------------------------------------------------------------
data "openstack_images_image_v2" "image" {
  name        = var.image
  most_recent = true
}

resource "openstack_compute_instance_v2" "database" {
  name        = "${var.project_name}-postgresql-database"
  image_id    = data.openstack_images_image_v2.image.id
  flavor_name = var.db_flavor
  key_pair    = var.key_name
  user_data   = local.database_user_data

  network {
    port = openstack_networking_port_v2.database_port.id
  }

  depends_on = [
    openstack_networking_router_interface_v2.router_interface
  ]
}

