# homeserver-infra

Infrastructure as Code (IaC) and Network as Code (NaC) for Proxmox-based homeserver using Terraform, Netbox, and Zabbix.

## Quick Start

```bash
# 1. Setup configuration files
make setup

# 2. Edit configuration
# - terraform/proxmox/terraform.tfvars (Proxmox credentials)
# - netbox/env/netbox.env (Netbox config)
# - netbox/env/postgres.env (Database config)
# - zabbix/env/zabbix.env (Zabbix config)
# - zabbix/env/postgres.env (Zabbix database config)

# 3. Start services
make netbox-up          # Start Netbox
make zabbix-up          # Start Zabbix
make init-terraform     # Initialize Terraform

# 4. Deploy infrastructure
make plan-terraform     # Preview changes
make apply-terraform    # Apply changes

# See all commands
make help
```

## Technology Stack

- **Proxmox VE** - Hypervisor for VMs and containers
- **Terraform** - Infrastructure as Code automation
- **Netbox** - Network source of truth (IPAM/DCIM)
- **Zabbix** - Infrastructure monitoring and alerting

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

- **[Getting Started Guide](docs/getting-started.md)** - Complete walkthrough
- [Proxmox Setup](docs/proxmox-setup.md) - Install and configure Proxmox
- [Terraform Guide](docs/terraform-setup.md) - Terraform usage and examples
- [Netbox Guide](docs/netbox-setup.md) - Netbox deployment and API
- [Zabbix Guide](docs/zabbix-setup.md) - Zabbix monitoring setup

## Project Structure

```
├── terraform/
│   ├── proxmox/       - Main Terraform configuration
│   └── modules/       - Reusable modules
├── netbox/            - Netbox Docker deployment
├── zabbix/            - Zabbix monitoring deployment
├── docs/              - Detailed documentation
├── Makefile           - Main automation tasks
├── netbox/Makefile    - Netbox-specific operations
└── zabbix/Makefile    - Zabbix-specific operations
```

## Common Commands

**Infrastructure:**
```bash
make validate          # Validate setup
make init-terraform    # Initialize Terraform
make plan-terraform    # Preview changes
make apply-terraform   # Apply changes
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
