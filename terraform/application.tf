# =============================================================================
# Application Tier
# Creates: Web API Instances with Ports
# =============================================================================

# -----------------------------------------------------------------------------
# Web API Ports
# -----------------------------------------------------------------------------
resource "openstack_networking_port_v2" "web_api_port" {
  count          = var.web_instance_count
  name           = "${var.project_name}-web-api-port-${count.index + 1}"
  network_id     = openstack_networking_network_v2.private_net.id
  admin_state_up = true

  security_group_ids = [
    openstack_networking_secgroup_v2.web_api_sg.id
  ]

  fixed_ip {
    subnet_id = openstack_networking_subnet_v2.private_subnet.id
  }
}

# -----------------------------------------------------------------------------
# Web API User Data Script Template
# -----------------------------------------------------------------------------
locals {
  web_api_user_data = <<-EOF
    #!/bin/bash
    set -e

    # Update system
    export DEBIAN_FRONTEND=noninteractive
    apt-get update
    apt-get upgrade -y

    # Install dependencies
    apt-get install -y python3 python3-pip python3-venv postgresql-client

    # Create app directory
    mkdir -p /opt/webapp
    cd /opt/webapp

    # Create virtual environment
    python3 -m venv venv
    source venv/bin/activate

    # Install Python packages
    pip install flask psycopg2-binary gunicorn

    # Create Flask application
    cat > /opt/webapp/app.py << 'EOFAPP'
    from flask import Flask, jsonify
    import psycopg2
    import socket
    import os

    app = Flask(__name__)

    DB_HOST = os.environ.get('DB_HOST', '${openstack_compute_instance_v2.database.access_ip_v4}')
    DB_NAME = os.environ.get('DB_NAME', '${var.db_name}')
    DB_USER = os.environ.get('DB_USER', '${var.db_user}')
    DB_PASSWORD = os.environ.get('DB_PASSWORD', '${var.db_password}')

    def get_db_connection():
        try:
            conn = psycopg2.connect(
                host=DB_HOST,
                database=DB_NAME,
                user=DB_USER,
                password=DB_PASSWORD
            )
            return conn
        except Exception as e:
            return None

    @app.route('/')
    def index():
        hostname = socket.gethostname()
        return jsonify({
            'message': 'Welcome to the Web API',
            'server': hostname,
            'status': 'running'
        })

    @app.route('/health')
    def health():
        return jsonify({'status': 'healthy'}), 200

    @app.route('/api/data')
    def get_data():
        hostname = socket.gethostname()
        conn = get_db_connection()
        if conn is None:
            return jsonify({
                'error': 'Database connection failed',
                'server': hostname
            }), 500

        try:
            cur = conn.cursor()
            cur.execute('SELECT id, name, description, created_at FROM items;')
            rows = cur.fetchall()
            cur.close()
            conn.close()

            items = []
            for row in rows:
                items.append({
                    'id': row[0],
                    'name': row[1],
                    'description': row[2],
                    'created_at': str(row[3])
                })

            return jsonify({
                'server': hostname,
                'data': items
            })
        except Exception as e:
            return jsonify({
                'error': str(e),
                'server': hostname
            }), 500

    if __name__ == '__main__':
        app.run(host='0.0.0.0', port=80)
    EOFAPP

    # Create systemd service
    cat > /etc/systemd/system/webapp.service << 'EOFSVC'
    [Unit]
    Description=Flask Web API
    After=network.target

    [Service]
    Type=simple
    User=root
    WorkingDirectory=/opt/webapp
    Environment="DB_HOST=${openstack_compute_instance_v2.database.access_ip_v4}"
    Environment="DB_NAME=${var.db_name}"
    Environment="DB_USER=${var.db_user}"
    Environment="DB_PASSWORD=${var.db_password}"
    ExecStart=/opt/webapp/venv/bin/gunicorn -w 4 -b 0.0.0.0:80 app:app
    Restart=always

    [Install]
    WantedBy=multi-user.target
    EOFSVC

    # Start service
    systemctl daemon-reload
    systemctl start webapp
    systemctl enable webapp

    # Create status file
    echo "Web API setup completed at $(date)" > /var/log/webapp-setup-complete.log
  EOF
}

# -----------------------------------------------------------------------------
# Web API Instances
# -----------------------------------------------------------------------------
resource "openstack_compute_instance_v2" "web_api" {
  count       = var.web_instance_count
  name        = "${var.project_name}-web-api-server-${count.index + 1}"
  image_id    = data.openstack_images_image_v2.image.id
  flavor_name = var.web_flavor
  key_pair    = var.key_name
  user_data   = local.web_api_user_data

  network {
    port = openstack_networking_port_v2.web_api_port[count.index].id
  }

  depends_on = [
    openstack_compute_instance_v2.database,
    openstack_networking_router_interface_v2.router_interface
  ]
}

