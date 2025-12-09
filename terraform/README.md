# Terraform OpenStack 3-Tier Web API Infrastructure

This Terraform configuration deploys a 3-tier web application infrastructure on OpenStack, equivalent to the HEAT template.

## Architecture

```
                    ┌─────────────────────────────────────────────────────────┐
                    │                    Public Network                        │
                    └─────────────────────────┬───────────────────────────────┘
                                              │
                                    ┌─────────┴─────────┐
                                    │   Floating IP     │
                                    │  (Load Balancer)  │
                                    └─────────┬─────────┘
                                              │
┌─────────────────────────────────────────────┼───────────────────────────────────────────────┐
│                           Private Network (10.0.1.0/24)                                      │
│                                             │                                                │
│  ┌──────────────────────────────────────────┴──────────────────────────────────────────┐    │
│  │                        Load Balancer (Octavia)                                       │    │
│  │                        - HTTP Listener (Port 80)                                     │    │
│  │                        - Round Robin Pool                                            │    │
│  │                        - Health Monitor (/health)                                    │    │
│  └──────────────────────────────────┬───────────────────────────────────────────────────┘    │
│                                     │                                                        │
│              ┌──────────────────────┼──────────────────────┐                                │
│              │                      │                      │                                │
│    ┌─────────┴─────────┐  ┌─────────┴─────────┐  ┌─────────┴─────────┐                     │
│    │  Web API Server 1 │  │  Web API Server 2 │  │  Web API Server N │                     │
│    │  (Flask/Gunicorn) │  │  (Flask/Gunicorn) │  │  (Flask/Gunicorn) │                     │
│    │  Port 80          │  │  Port 80          │  │  Port 80          │                     │
│    └─────────┬─────────┘  └─────────┬─────────┘  └─────────┬─────────┘                     │
│              │                      │                      │                                │
│              └──────────────────────┼──────────────────────┘                                │
│                                     │                                                        │
│                           ┌─────────┴─────────┐                                             │
│                           │   PostgreSQL DB   │                                             │
│                           │   Port 5432       │                                             │
│                           └───────────────────┘                                             │
│                                                                                              │
└──────────────────────────────────────────────────────────────────────────────────────────────┘
```

## File Structure

```
terraform/
├── versions.tf           # Provider and Terraform version requirements
├── variables.tf          # Input variables
├── network.tf            # Network, subnet, router resources
├── security_groups.tf    # Security groups and rules
├── database.tf           # PostgreSQL database instance
├── application.tf        # Web API instances
├── loadbalancer.tf       # Octavia load balancer resources
├── outputs.tf            # Output values
├── terraform.tfvars.example  # Example variables file
├── deploy.sh             # Deployment helper script
└── README.md             # This file
```

## Prerequisites

1. **Terraform** >= 1.0.0 installed
2. **OpenStack credentials** configured via environment variables
3. **Required OpenStack services**: Nova, Neutron, Octavia, Glance

## Quick Start

### 1. Source OpenStack Credentials

```bash
source ~/duratm-openrc.sh
```

### 2. Configure Variables (Optional)

Copy and customize the variables file:

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
```

### 3. Deploy Using Script

```bash
chmod +x deploy.sh

# Initialize Terraform
./deploy.sh init

# Preview changes
./deploy.sh plan

# Apply changes
./deploy.sh apply
```

### Or Deploy Manually

```bash
# Initialize
terraform init

# Preview
terraform plan

# Apply
terraform apply

# View outputs
terraform output
```

## Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `key_name` | SSH keypair name | `hercules` |
| `image` | Image name for instances | `ubuntu-noble` |
| `web_flavor` | Flavor for web servers | `m1.small` |
| `db_flavor` | Flavor for database | `m1.medium` |
| `web_instance_count` | Number of web servers | `2` |
| `public_net` | Public network name | `public` |
| `private_net_cidr` | Private network CIDR | `10.0.1.0/24` |
| `db_name` | Database name | `apidb` |
| `db_user` | Database user | `apiuser` |
| `db_password` | Database password | `SecurePassword123!` |

## Outputs

After deployment, Terraform will output:

- **loadbalancer_floating_ip**: Public IP of the load balancer
- **loadbalancer_url**: URL to access the API
- **api_data_url**: URL to access the data endpoint
- **web_api_server_ips**: Private IPs of web servers
- **database_server_ip**: Private IP of database server

## Testing the Deployment

```bash
# Get the load balancer URL
LB_URL=$(terraform output -raw loadbalancer_url)

# Test root endpoint
curl $LB_URL

# Test health endpoint
curl ${LB_URL}health

# Test data endpoint
curl ${LB_URL}api/data
```

## Security Groups

### Web API Security Group
- Ingress TCP 80 (HTTP) from 0.0.0.0/0
- Ingress TCP 22 (SSH) from 0.0.0.0/0
- Ingress ICMP from 0.0.0.0/0

### Database Security Group
- Ingress TCP 5432 (PostgreSQL) from Web API Security Group only
- Ingress TCP 22 (SSH) from 0.0.0.0/0
- Ingress ICMP from 0.0.0.0/0

## Cleanup

```bash
# Using script
./deploy.sh destroy

# Or manually
terraform destroy
```

## Troubleshooting

### Check OpenStack credentials
```bash
openstack token issue
```

### View Terraform state
```bash
terraform show
```

### Check instance logs
```bash
openstack console log show <instance-name>
```

### SSH to instances (via bastion or floating IP)
```bash
ssh -i ~/.ssh/hercules ubuntu@<floating-ip>
```

## Differences from HEAT Template

| Feature | HEAT | Terraform |
|---------|------|-----------|
| Syntax | YAML | HCL |
| State Management | OpenStack-managed | Local or remote backend |
| Scalability | Manual duplication | `count` or `for_each` |
| Modularity | Nested stacks | Modules |
| Drift Detection | Limited | Built-in |

## Extending the Configuration

### Adding More Web Servers

Simply change the `web_instance_count` variable:

```hcl
web_instance_count = 4
```

### Using Remote State

Add a backend configuration to `versions.tf`:

```hcl
terraform {
  backend "swift" {
    container = "terraform-state"
  }
}
```

