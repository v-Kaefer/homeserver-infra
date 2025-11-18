# homeserver-infra

Infrastructure as Code (IaC) and Network as Code (NaC) for Proxmox-based homeserver using Terraform, Netbox, and Zabbix.

## Quick Start

```bash
# 1. Setup configuration files
make setup

# 2. Edit configuration (IMPORTANT: Use same password for shared PostgreSQL)
# - postgres-shared/postgres.env (Shared database password)
# - terraform/proxmox/terraform.tfvars (Proxmox credentials)
# - netbox/env/netbox.env (Netbox config - use postgres-shared password)
# - zabbix/env/zabbix.env (Zabbix config - use postgres-shared password)

# 3. Start all services (recommended - starts in correct order)
make start-all

# OR start services individually:
# make postgres-up        # Start shared PostgreSQL first
# make netbox-up          # Then Netbox
# make zabbix-up          # Then Zabbix

# 4. Initialize Terraform
make init-terraform

# 5. Deploy infrastructure
make plan-terraform     # Preview changes
make apply-terraform    # Apply changes

# 6. Backup everything
make backup-all         # Unified backup of all services

# See all commands
make help
```

## Technology Stack

- **Proxmox VE** - Hypervisor for VMs and containers
- **Terraform** - Infrastructure as Code automation
- **Netbox** - Network source of truth (IPAM/DCIM)
- **Zabbix** - Infrastructure monitoring and alerting
- **PostgreSQL** - Shared database (50% resource optimization)

## Improvements Implemented

✅ **Consolidated PostgreSQL** - Single database instance for all services (50% resource reduction)
✅ **Unified Backup System** - Automated backup of all services with retention policy
✅ **Simplified Operations** - `start-all`, `stop-all`, and `backup-all` commands
✅ **Better Resource Management** - Shared resources, health checks, and monitoring

## Example: Deploy a VM

```hcl
module "web_server" {
  source = "../modules/proxmox-vm"
  
  vm_name        = "web-server-01"
  vm_id          = 100
  target_node    = "pve"
  clone_template = "ubuntu-cloud"
  
  cores     = 2
  memory    = 4096
  disk_size = "30G"
  
  ip_address = "10.0.0.100/24"
  gateway    = "10.0.0.1"
}
```

## Documentation

### Getting Started
- **[Getting Started Guide](docs/getting-started.md)** - Complete walkthrough
- [Proxmox Setup](docs/proxmox-setup.md) - Install and configure Proxmox
- [Terraform Guide](docs/terraform-setup.md) - Terraform usage and examples
- [Netbox Guide](docs/netbox-setup.md) - Netbox deployment and API
- [Zabbix Guide](docs/zabbix-setup.md) - Zabbix monitoring setup

### Planning & Architecture
- **[Infrastructure Analysis](docs/infrastructure-analysis.md)** - Comprehensive analysis, redundancies, and improvements
- **[Information Requirements](docs/information-requirements.md)** - Checklist of info needed for better planning
- [Infrastructure Diagram](docs/infrastructure-diagram.md) - Visual architecture reference for Draw.io
- [n8n Integration Plan](docs/n8n-integration-plan.md) - Workflow automation roadmap

## Project Structure

```
├── terraform/
│   ├── proxmox/          - Main Terraform configuration
│   └── modules/          - Reusable modules
├── postgres-shared/      - Shared PostgreSQL instance (NEW)
├── netbox/               - Netbox Docker deployment
├── zabbix/               - Zabbix monitoring deployment
├── scripts/              - Automation scripts
├── docs/                 - Detailed documentation
├── Makefile              - Main automation tasks
├── postgres-shared/Makefile - PostgreSQL operations
├── netbox/Makefile       - Netbox-specific operations
└── zabbix/Makefile       - Zabbix-specific operations
```

## Common Commands

**Quick Operations:**
```bash
make start-all         # Start all services in order
make stop-all          # Stop all services
make backup-all        # Unified backup of everything
make status            # Show status of all services
```

**Infrastructure:**
```bash
make validate          # Validate setup
make init-terraform    # Initialize Terraform
make plan-terraform    # Preview changes
make apply-terraform   # Apply changes
```

**Database:**
```bash
make postgres-up       # Start shared PostgreSQL
make postgres-backup   # Backup all databases
make postgres-logs     # View PostgreSQL logs
```

**Netbox:**
```bash
make netbox-up         # Start Netbox
make netbox-down       # Stop Netbox
make netbox-logs       # View logs
make netbox-backup     # Backup database
```

**Zabbix:**
```bash
make zabbix-up         # Start Zabbix
make zabbix-down       # Stop Zabbix
make zabbix-logs       # View logs
make zabbix-backup     # Backup database
```

**Utilities:**
```bash
make status            # Show service status
make clean             # Clean temporary files
```

## Resources

- [Proxmox Documentation](https://pve.proxmox.com/pve-docs/)
- [Terraform Documentation](https://www.terraform.io/docs)
- [Netbox Documentation](https://docs.netbox.dev/)
- [Zabbix Documentation](https://www.zabbix.com/documentation/current/)
- [Changelog](CHANGELOG.md)
