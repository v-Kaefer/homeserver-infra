# homeserver-infra

A repository for managing homeserver infrastructure using Proxmox, Terraform, and Netbox.

## 🚀 Getting Started

New to this infrastructure setup? Start here:

👉 **[Getting Started Guide](docs/getting-started.md)** - Complete walkthrough from installation to your first VM

### Quick Validation

Run the validation script to check your setup:

```bash
./validate-setup.sh
```

This will verify that all required tools are installed and configurations are in place.

## Overview

This repository provides Infrastructure as Code (IaC) and Network as Code (NaC) solutions for managing a homeserver environment.

### Technology Stack

- **Proxmox VE**: Hypervisor and OS for running virtual machines and containers
- **Terraform**: Infrastructure as Code tool for automated VM provisioning
- **Netbox**: Network as Code and source of truth for IPAM, DCIM, and virtualization

## Repository Structure

```
├── terraform/
│   ├── proxmox/          # Main Proxmox Terraform configuration
│   │   ├── main.tf       # Provider configuration
│   │   ├── variables.tf  # Variable definitions
│   │   ├── outputs.tf    # Output values
│   │   └── terraform.tfvars.example  # Example configuration
│   └── modules/
│       └── proxmox-vm/   # Reusable VM module
│           ├── main.tf
│           ├── variables.tf
│           └── outputs.tf
├── netbox/
│   ├── docker-compose.yml      # Netbox deployment
│   ├── env/                    # Environment configuration
│   └── README.md              # Netbox documentation
├── docs/
│   ├── proxmox-setup.md       # Proxmox installation and configuration
│   ├── terraform-setup.md     # Terraform usage guide
│   └── netbox-setup.md        # Netbox setup and integration
└── README.md
```

## Quick Start

### Automated Setup (Recommended)

Use the provided Makefile for easy setup:

```bash
# Initial setup - copies example configuration files
make setup

# Edit configuration files with your details
# - terraform/proxmox/terraform.tfvars
# - netbox/env/netbox.env
# - netbox/env/postgres.env

# Validate your setup
make validate

# Start Netbox
make start-netbox

# Initialize Terraform
make init-terraform

# View all available commands
make help
```

### Manual Setup

### 1. Set Up Proxmox

Follow the [Proxmox Setup Guide](docs/proxmox-setup.md) to:
- Install Proxmox VE on your server
- Configure networking and storage
- Create VM templates
- Generate API tokens

### 2. Configure Terraform

Follow the [Terraform Setup Guide](docs/terraform-setup.md) to:
- Install Terraform
- Configure Proxmox credentials
- Deploy your first VM

```bash
cd terraform/proxmox
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your Proxmox details
terraform init
terraform plan
terraform apply
```

### 3. Deploy Netbox

Follow the [Netbox Setup Guide](docs/netbox-setup.md) to:
- Deploy Netbox using Docker Compose
- Configure IPAM and DCIM
- Integrate with Terraform

```bash
cd netbox
cp env/postgres.env.example env/postgres.env
cp env/netbox.env.example env/netbox.env
# Edit env files with your configuration
docker-compose up -d
```

## Features

### Infrastructure as Code (IaC)

- Automated VM provisioning with Terraform
- Reusable VM modules
- Version-controlled infrastructure
- Consistent and repeatable deployments

### Network as Code (NaC)

- Centralized IP address management
- Device and VM inventory
- Network topology documentation
- API-driven network automation

### Integration

- Terraform creates VMs on Proxmox
- VMs are automatically registered in Netbox
- IP addresses managed through Netbox
- Single source of truth for infrastructure

## Documentation

- **[Getting Started Guide](docs/getting-started.md)** - Complete setup walkthrough for beginners
- [Proxmox Setup Guide](docs/proxmox-setup.md) - Installation and configuration
- [Terraform Setup Guide](docs/terraform-setup.md) - IaC deployment
- [Netbox Setup Guide](docs/netbox-setup.md) - NaC and IPAM

## Example Usage

### Creating a VM

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
  
  network_bridge = "vmbr0"
  ip_address     = "10.0.0.100/24"
  gateway        = "10.0.0.1"
}
```

## Contributing

This is a personal homeserver infrastructure repository. Feel free to fork and adapt for your own use.

## License

This project is open source and available for personal use.

## Resources

- [Proxmox VE Documentation](https://pve.proxmox.com/pve-docs/)
- [Terraform Documentation](https://www.terraform.io/docs)
- [Netbox Documentation](https://docs.netbox.dev/)
- [Proxmox Terraform Provider](https://registry.terraform.io/providers/Telmate/proxmox/latest/docs)
