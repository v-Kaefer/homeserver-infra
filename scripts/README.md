# Scripts

This directory contains automation scripts for managing the homeserver infrastructure.

## Netbox Setup Script

**`setup-netbox-site.py`** - Automates initial Netbox site configuration

### What it does:

- Creates a default site ("Home")
- Sets up common device roles (Hypervisor, Router, Switch, Firewall, Server, Storage)
- Creates default IP prefixes for common networks
- Configures Proxmox cluster type and default cluster

### Requirements:

```bash
pip install pynetbox
```

### Usage:

**Via Makefile (recommended):**
```bash
cd netbox
make netbox-setup-site NETBOX_TOKEN=your-api-token-here
```

**Direct execution:**
```bash
python3 scripts/setup-netbox-site.py your-api-token-here
```

### Getting an API Token:

1. Start Netbox: `make netbox-up`
2. Create superuser: `make netbox-create-superuser`
3. Login at http://localhost:8000
4. Go to your profile → API Tokens
5. Click "Add a token"
6. Give it write permissions
7. Copy the token and use it with the setup script

### Custom Netbox URL:

```bash
NETBOX_URL=http://your-netbox:8000 python3 scripts/setup-netbox-site.py your-token
```

## Adding More Scripts

When adding new automation scripts:
1. Make them executable: `chmod +x script-name.sh`
2. Add proper documentation
3. Include usage examples
4. Add shebang line (#!/bin/bash or #!/usr/bin/env python3)
