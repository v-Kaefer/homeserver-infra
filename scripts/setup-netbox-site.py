#!/usr/bin/env python3
"""
Netbox Site Setup Script

This script automates the initial setup of a Netbox instance by creating:
- Default site (Home)
- Common device roles (Hypervisor, Router, Switch, Firewall, Server)
- Default IP prefixes for common networks
- Device types and manufacturers (optional)

Usage:
    python3 setup-netbox-site.py <API_TOKEN>
    
Or via Makefile:
    make netbox-setup-site NETBOX_TOKEN=<your-token>

Requirements:
    - Netbox running and accessible
    - API token with write permissions
    - pynetbox library (pip install pynetbox)
"""

import sys
import os

try:
    import pynetbox
except ImportError:
    print("Error: pynetbox library not installed")
    print("Install it with: pip install pynetbox")
    sys.exit(1)


def setup_netbox_site(api_token, netbox_url="http://localhost:8000"):
    """
    Automated Netbox site setup
    
    Args:
        api_token: Netbox API token
        netbox_url: Netbox URL (default: http://localhost:8000)
    """
    
    print(f"Connecting to Netbox at {netbox_url}...")
    
    try:
        nb = pynetbox.api(netbox_url, token=api_token)
        nb.http_session.verify = False  # For self-signed certificates
        
        # Test connection
        nb.status()
        print("✓ Connected to Netbox successfully\n")
        
    except Exception as e:
        print(f"✗ Failed to connect to Netbox: {e}")
        print("\nTroubleshooting:")
        print("1. Ensure Netbox is running: docker compose ps")
        print("2. Check Netbox is accessible at", netbox_url)
        print("3. Verify your API token is correct")
        sys.exit(1)
    
    # Create default site
    print("Creating default site...")
    try:
        site = nb.dcim.sites.get(name="Home")
        if site:
            print("  - Site 'Home' already exists")
        else:
            site = nb.dcim.sites.create(
                name="Home",
                slug="home",
                status="active",
                description="Home datacenter"
            )
            print("  ✓ Created site 'Home'")
    except Exception as e:
        print(f"  ✗ Error creating site: {e}")
    
    # Create device roles
    print("\nCreating device roles...")
    roles = [
        {"name": "Hypervisor", "slug": "hypervisor", "color": "9c27b0", "vm_role": False},
        {"name": "Router", "slug": "router", "color": "2196f3", "vm_role": False},
        {"name": "Switch", "slug": "switch", "color": "4caf50", "vm_role": False},
        {"name": "Firewall", "slug": "firewall", "color": "f44336", "vm_role": False},
        {"name": "Server", "slug": "server", "color": "ff9800", "vm_role": True},
        {"name": "Storage", "slug": "storage", "color": "795548", "vm_role": False},
    ]
    
    for role_data in roles:
        try:
            role = nb.dcim.device_roles.get(slug=role_data["slug"])
            if role:
                print(f"  - Role '{role_data['name']}' already exists")
            else:
                nb.dcim.device_roles.create(**role_data)
                print(f"  ✓ Created role '{role_data['name']}'")
        except Exception as e:
            print(f"  ✗ Error creating role '{role_data['name']}': {e}")
    
    # Create IP prefixes
    print("\nCreating IP prefixes...")
    prefixes = [
        {"prefix": "10.0.0.0/24", "description": "Management Network"},
        {"prefix": "10.0.1.0/24", "description": "VM Network"},
        {"prefix": "10.0.2.0/24", "description": "Container Network"},
        {"prefix": "192.168.1.0/24", "description": "Home Network"},
    ]
    
    for prefix_data in prefixes:
        try:
            prefix = nb.ipam.prefixes.get(prefix=prefix_data["prefix"])
            if prefix:
                print(f"  - Prefix '{prefix_data['prefix']}' already exists")
            else:
                nb.ipam.prefixes.create(
                    prefix=prefix_data["prefix"],
                    status="active",
                    description=prefix_data["description"]
                )
                print(f"  ✓ Created prefix '{prefix_data['prefix']}'")
        except Exception as e:
            print(f"  ✗ Error creating prefix '{prefix_data['prefix']}': {e}")
    
    # Create manufacturer for Proxmox
    print("\nCreating manufacturers...")
    try:
        manufacturer = nb.dcim.manufacturers.get(slug="proxmox")
        if manufacturer:
            print("  - Manufacturer 'Proxmox' already exists")
        else:
            manufacturer = nb.dcim.manufacturers.create(
                name="Proxmox",
                slug="proxmox"
            )
            print("  ✓ Created manufacturer 'Proxmox'")
    except Exception as e:
        print(f"  ✗ Error creating manufacturer: {e}")
    
    # Create cluster type for virtualization
    print("\nCreating cluster types...")
    try:
        cluster_type = nb.virtualization.cluster_types.get(slug="proxmox")
        if cluster_type:
            print("  - Cluster type 'Proxmox' already exists")
        else:
            cluster_type = nb.virtualization.cluster_types.create(
                name="Proxmox",
                slug="proxmox"
            )
            print("  ✓ Created cluster type 'Proxmox'")
    except Exception as e:
        print(f"  ✗ Error creating cluster type: {e}")
    
    # Create default cluster
    print("\nCreating default cluster...")
    try:
        cluster = nb.virtualization.clusters.get(name="Proxmox-Cluster")
        if cluster:
            print("  - Cluster 'Proxmox-Cluster' already exists")
        else:
            cluster_type = nb.virtualization.cluster_types.get(slug="proxmox")
            if cluster_type and site:
                cluster = nb.virtualization.clusters.create(
                    name="Proxmox-Cluster",
                    type=cluster_type.id,
                    site=site.id
                )
                print("  ✓ Created cluster 'Proxmox-Cluster'")
            else:
                print("  - Skipping cluster creation (missing prerequisites)")
    except Exception as e:
        print(f"  ✗ Error creating cluster: {e}")
    
    print("\n" + "="*50)
    print("✓ Netbox site setup completed!")
    print("="*50)
    print("\nYou can now:")
    print(f"1. Access Netbox at {netbox_url}")
    print("2. Add devices, VMs, and IP addresses")
    print("3. Integrate with Terraform for automated VM registration")
    print("\nFor more information, see docs/netbox-setup.md")


def main():
    if len(sys.argv) < 2:
        print("Error: API token not provided")
        print("\nUsage:")
        print("  python3 setup-netbox-site.py <API_TOKEN>")
        print("\nOr via Makefile:")
        print("  make netbox-setup-site NETBOX_TOKEN=<your-token>")
        print("\nTo get your API token:")
        print("1. Login to Netbox at http://localhost:8000")
        print("2. Go to your profile -> API Tokens")
        print("3. Create a new token with write permissions")
        sys.exit(1)
    
    api_token = sys.argv[1]
    netbox_url = os.environ.get("NETBOX_URL", "http://localhost:8000")
    
    setup_netbox_site(api_token, netbox_url)


if __name__ == "__main__":
    main()
