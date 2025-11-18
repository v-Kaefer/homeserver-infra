# Netbox Configuration

This directory contains configuration for Netbox - Network as Code (NaC) solution.

## Overview

Netbox serves as the source of truth for:
- IP Address Management (IPAM)
- Device inventory
- Network topology
- Virtual machines
- Connections and cables

## Integration with Terraform

The Terraform configuration can be integrated with Netbox to:
1. Query IP addresses and network information
2. Register VMs created via Terraform
3. Maintain network documentation

## Setup

### Using Docker Compose

The recommended way to run Netbox is using Docker Compose. See `docker-compose.yml` for the configuration.

### Initial Configuration

1. Start Netbox:
   ```bash
   docker-compose up -d
   ```

2. Create a superuser:
   ```bash
   docker-compose exec netbox python /opt/netbox/netbox/manage.py createsuperuser
   ```

3. Access Netbox at http://localhost:8000

4. Create an API token in Netbox for Terraform integration

## Terraform Integration

Add the Netbox provider to your Terraform configuration:

```hcl
provider "netbox" {
  server_url = var.netbox_url
  api_token  = var.netbox_api_token
}
```

## Resources

- [Netbox Documentation](https://docs.netbox.dev/)
- [Netbox Docker](https://github.com/netbox-community/netbox-docker)
- [Terraform Netbox Provider](https://registry.terraform.io/providers/e-breuninger/netbox/latest/docs)
