# Netbox Setup Guide

This guide covers setting up and using Netbox for Network as Code (NaC) and as a source of truth for your infrastructure.

## What is Netbox?

Netbox is an open-source IP address management (IPAM) and data center infrastructure management (DCIM) tool. It serves as a source of truth for:

- **IP Address Management (IPAM)**: IP addresses, prefixes, VLANs, VRFs
- **DCIM**: Devices, racks, sites, cables
- **Virtualization**: Virtual machines, clusters
- **Circuits**: Internet connections, point-to-point links
- **Secrets**: Encrypted credential storage

## Installation

### Using Docker Compose (Recommended)

1. Navigate to the netbox directory:
   ```bash
   cd netbox
   ```

2. Create environment files:
   ```bash
   cp env/postgres.env.example env/postgres.env
   cp env/netbox.env.example env/netbox.env
   ```

3. Edit `env/postgres.env` and set a strong password:
   ```bash
   POSTGRES_PASSWORD=your_secure_password_here
   ```

4. Edit `env/netbox.env`:
   - Update `DB_PASSWORD` to match `POSTGRES_PASSWORD`
   - Generate a secret key:
     ```bash
     python3 -c 'from secrets import token_urlsafe; print(token_urlsafe(50))'
     ```
   - Set `SECRET_KEY` to the generated value
   - Update `ALLOWED_HOSTS` if needed (use `*` for all hosts)

5. Start Netbox:
   ```bash
   docker-compose up -d
   ```

6. Create a superuser:
   ```bash
   docker-compose exec netbox python /opt/netbox/netbox/manage.py createsuperuser
   ```

7. Access Netbox at http://localhost:8000

## Initial Configuration

### 1. Login and Create API Token

1. Login with your superuser credentials
2. Click on your username → Profile → API Tokens
3. Click "Add a token"
4. Give it a description (e.g., "Terraform Integration")
5. Click "Create"
6. **Save the token** - it will only be shown once

### 2. Create Basic Site Structure

#### Create a Site

1. Navigate to Organization → Sites
2. Click "Add"
3. Fill in:
   - Name: "Home"
   - Status: Active
   - Facility: Optional
   - Physical address: Optional
4. Click "Create"

#### Create Device Roles

1. Navigate to Devices → Device Roles
2. Create roles like:
   - Hypervisor (for Proxmox)
   - Router
   - Switch
   - Firewall
   - Server

#### Add Proxmox as a Device

1. Navigate to Devices → Devices
2. Click "Add"
3. Fill in:
   - Name: "proxmox-01"
   - Device Role: Hypervisor
   - Site: Home
   - Status: Active
4. Click "Create"

### 3. Configure IPAM

#### Create Prefixes

1. Navigate to IPAM → Prefixes
2. Add your network prefixes:
   - `10.0.0.0/24` - Management Network
   - `10.0.1.0/24` - VM Network
   - `10.0.2.0/24` - Container Network

#### Create IP Ranges

1. Navigate to IPAM → IP Ranges
2. Define ranges for DHCP, static assignments, etc.

#### Add VLANs (if applicable)

1. Navigate to IPAM → VLANs
2. Add your VLANs with IDs and names

## Integrating with Terraform

### Install Netbox Terraform Provider

Add to your Terraform configuration:

```hcl
terraform {
  required_providers {
    netbox = {
      source  = "e-breuninger/netbox"
      version = "~> 3.0"
    }
  }
}

provider "netbox" {
  server_url = var.netbox_url
  api_token  = var.netbox_api_token
}
```

### Example: Register VMs in Netbox

```hcl
# Create VM in Proxmox
module "web_server" {
  source = "../modules/proxmox-vm"
  # ... configuration ...
}

# Register in Netbox
resource "netbox_virtual_machine" "web_server" {
  name       = module.web_server.vm_name
  cluster_id = netbox_cluster.proxmox.id
  status     = "active"
  vcpus      = 2
  memory_mb  = 4096
  disk_size_gb = 30
}

# Assign IP address
resource "netbox_ip_address" "web_server_ip" {
  ip_address = "${module.web_server.vm_ip}/24"
  status     = "active"
  virtual_machine_interface_id = netbox_interface.web_server_eth0.id
  dns_name   = "web-server.home.local"
}
```

### Example: Query Available IPs

```hcl
data "netbox_prefix" "vm_network" {
  cidr = "10.0.1.0/24"
}

# Get available IP from prefix
data "netbox_available_ip_addresses" "next_ip" {
  prefix_id = data.netbox_prefix.vm_network.id
}
```

## Using Netbox API

### Python Example

```python
import requests

NETBOX_URL = "http://localhost:8000"
API_TOKEN = "your-api-token"

headers = {
    "Authorization": f"Token {API_TOKEN}",
    "Content-Type": "application/json"
}

# Get all VMs
response = requests.get(
    f"{NETBOX_URL}/api/virtualization/virtual-machines/",
    headers=headers
)
vms = response.json()

# Create a new IP address
data = {
    "address": "10.0.1.100/24",
    "status": "active",
    "description": "Web Server"
}
response = requests.post(
    f"{NETBOX_URL}/api/ipam/ip-addresses/",
    headers=headers,
    json=data
)
```

### cURL Example

```bash
# Get API token info
curl -X GET http://localhost:8000/api/users/tokens/ \
  -H "Authorization: Token your-api-token"

# List all prefixes
curl -X GET http://localhost:8000/api/ipam/prefixes/ \
  -H "Authorization: Token your-api-token"

# Create new IP address
curl -X POST http://localhost:8000/api/ipam/ip-addresses/ \
  -H "Authorization: Token your-api-token" \
  -H "Content-Type: application/json" \
  -d '{
    "address": "10.0.1.100/24",
    "status": "active",
    "description": "Web Server"
  }'
```

## Best Practices

1. **Single Source of Truth**: Use Netbox as the definitive source for network information
2. **Automation**: Integrate with Terraform to automatically update Netbox
3. **Documentation**: Use custom fields and descriptions extensively
4. **Tagging**: Use tags to categorize and filter resources
5. **Regular Audits**: Periodically verify Netbox data matches reality
6. **Access Control**: Use permissions and groups to control access
7. **Backup**: Regularly backup Netbox database
8. **API-First**: Use the API for automation instead of manual entry

## Backup and Restore

### Backup

```bash
# Backup database
docker-compose exec postgres pg_dump -U netbox netbox > netbox_backup.sql

# Backup media files
docker-compose exec netbox tar czf /tmp/media-backup.tar.gz /opt/netbox/netbox/media
docker-compose cp netbox:/tmp/media-backup.tar.gz ./media-backup.tar.gz
```

### Restore

```bash
# Restore database
cat netbox_backup.sql | docker-compose exec -T postgres psql -U netbox netbox

# Restore media files
docker-compose cp media-backup.tar.gz netbox:/tmp/
docker-compose exec netbox tar xzf /tmp/media-backup.tar.gz -C /
```

## Maintenance

### Update Netbox

```bash
# Pull latest images
docker-compose pull

# Recreate containers
docker-compose up -d

# Run migrations
docker-compose exec netbox python /opt/netbox/netbox/manage.py migrate
```

### Clear Cache

```bash
docker-compose exec netbox python /opt/netbox/netbox/manage.py clearcache
```

### View Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f netbox
```

## Common Tasks

### Import Existing Infrastructure

Use the CSV import feature or API to bulk import:
1. Navigate to the relevant section (e.g., Devices)
2. Click "Import"
3. Download the CSV template
4. Fill in your data
5. Upload and import

### Custom Fields

Create custom fields for additional metadata:
1. Navigate to Customization → Custom Fields
2. Click "Add"
3. Configure field type and options
4. Assign to content types

### Webhooks

Configure webhooks to trigger actions on events:
1. Navigate to Customization → Webhooks
2. Click "Add"
3. Configure endpoint and events
4. Use for CI/CD integration

## Resources

- [Netbox Documentation](https://docs.netbox.dev/)
- [Netbox API Documentation](https://docs.netbox.dev/en/stable/integrations/rest-api/)
- [Netbox Docker](https://github.com/netbox-community/netbox-docker)
- [Terraform Netbox Provider](https://registry.terraform.io/providers/e-breuninger/netbox/latest/docs)
- [PyNetbox Python Library](https://github.com/netbox-community/pynetbox)
