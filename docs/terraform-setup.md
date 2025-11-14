# Terraform Setup Guide

This guide covers setting up and using Terraform for Infrastructure as Code (IaC) with Proxmox.

## Prerequisites

- Proxmox VE installed and configured
- API token created in Proxmox
- Terraform installed on your local machine

## Installing Terraform

### Linux

```bash
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform
```

### macOS

```bash
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
```

### Windows

Download from [Terraform Downloads](https://www.terraform.io/downloads) or use Chocolatey:

```powershell
choco install terraform
```

### Verify Installation

```bash
terraform --version
```

## Configuration

### 1. Configure Proxmox Credentials

Create a `terraform.tfvars` file in the `terraform/proxmox` directory:

```bash
cd terraform/proxmox
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your Proxmox details:

```hcl
proxmox_api_url          = "https://your-proxmox-ip:8006/api2/json"
proxmox_api_token_id     = "root@pam!terraform"
proxmox_api_token_secret = "your-api-token-secret"
proxmox_tls_insecure     = true
proxmox_node             = "pve"
```

⚠️ **Security Note**: Never commit `terraform.tfvars` to version control!

### 2. Initialize Terraform

```bash
cd terraform/proxmox
terraform init
```

This will:
- Download the Proxmox provider
- Initialize the backend
- Prepare the working directory

### 3. Validate Configuration

```bash
terraform validate
```

### 4. Plan Infrastructure Changes

```bash
terraform plan
```

This shows what Terraform will create, modify, or destroy.

### 5. Apply Configuration

```bash
terraform apply
```

Review the plan and type `yes` to confirm.

## Using the Proxmox VM Module

### Example: Creating a VM

Create a new file `vms.tf` in `terraform/proxmox`:

```hcl
module "web_server" {
  source = "../modules/proxmox-vm"
  
  vm_name        = "web-server-01"
  vm_id          = 100
  target_node    = var.proxmox_node
  clone_template = "ubuntu-cloud"
  
  cores     = 2
  memory    = 4096
  disk_size = "30G"
  
  network_bridge = "vmbr0"
  ip_address     = "10.0.0.100/24"
  gateway        = "10.0.0.1"
}

output "web_server_ip" {
  value = module.web_server.vm_ip
}
```

### Example: Multiple VMs

```hcl
locals {
  vms = {
    web-01 = { id = 101, cores = 2, memory = 4096, ip = "10.0.0.101/24" }
    web-02 = { id = 102, cores = 2, memory = 4096, ip = "10.0.0.102/24" }
    db-01  = { id = 103, cores = 4, memory = 8192, ip = "10.0.0.103/24" }
  }
}

module "servers" {
  for_each = local.vms
  source   = "../modules/proxmox-vm"
  
  vm_name        = each.key
  vm_id          = each.value.id
  target_node    = var.proxmox_node
  clone_template = "ubuntu-cloud"
  
  cores     = each.value.cores
  memory    = each.value.memory
  disk_size = "30G"
  
  network_bridge = "vmbr0"
  ip_address     = each.value.ip
  gateway        = "10.0.0.1"
}
```

## Terraform State Management

### Remote State (Recommended for Teams)

Configure a remote backend in `main.tf`:

```hcl
terraform {
  backend "s3" {
    bucket = "my-terraform-state"
    key    = "homeserver/terraform.tfstate"
    region = "us-east-1"
  }
}
```

Or use Terraform Cloud:

```hcl
terraform {
  cloud {
    organization = "my-org"
    
    workspaces {
      name = "homeserver-infra"
    }
  }
}
```

### Local State (Default)

The state is stored in `terraform.tfstate` (automatically created).

⚠️ **Important**: Keep state files secure and backed up!

## Common Terraform Commands

```bash
# Initialize working directory
terraform init

# Validate configuration
terraform validate

# Format configuration files
terraform fmt

# Show current state
terraform show

# List resources in state
terraform state list

# Plan changes
terraform plan

# Apply changes
terraform apply

# Destroy all resources
terraform destroy

# Target specific resource
terraform apply -target=module.web_server

# Import existing resource
terraform import proxmox_vm_qemu.example 100
```

## Best Practices

1. **Version Control**: Commit `.tf` files, not `.tfstate` or `.tfvars`
2. **State Locking**: Use remote backends with locking for teams
3. **Modules**: Reuse code with modules
4. **Variables**: Use variables for flexibility
5. **Outputs**: Export important values
6. **Workspaces**: Separate environments (dev, staging, prod)
7. **Documentation**: Comment complex configurations
8. **Validation**: Always run `terraform plan` before `apply`

## Troubleshooting

### TLS Certificate Errors

If you get TLS errors, set `proxmox_tls_insecure = true` in your variables (not recommended for production).

### Authentication Errors

Verify:
- API URL is correct
- Token ID and secret are valid
- Token has appropriate permissions

### Resource Already Exists

If a VM already exists with the same ID:
```bash
terraform import module.web_server.proxmox_vm_qemu.vm 100
```

## Resources

- [Terraform Documentation](https://www.terraform.io/docs)
- [Proxmox Terraform Provider](https://registry.terraform.io/providers/Telmate/proxmox/latest/docs)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)
