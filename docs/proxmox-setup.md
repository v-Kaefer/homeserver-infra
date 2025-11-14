# Proxmox Setup Guide

This guide covers setting up Proxmox as your homeserver infrastructure OS.

## Prerequisites

- Physical server or compatible hardware
- USB drive for installation (minimum 2GB)

## Installation

### 1. Download Proxmox VE

Download the latest Proxmox VE ISO from the [official website](https://www.proxmox.com/en/downloads).

### 2. Create Bootable USB

Use tools like:
- **Rufus** (Windows)
- **balenaEtcher** (Cross-platform)
- **dd** command (Linux/macOS)

```bash
# Example using dd on Linux/macOS
sudo dd if=proxmox-ve_*.iso of=/dev/sdX bs=1M status=progress
```

### 3. Install Proxmox

1. Boot from the USB drive
2. Select "Install Proxmox VE"
3. Accept the license agreement
4. Select target hard disk
5. Configure network settings:
   - Hostname (e.g., `pve.local`)
   - IP address
   - Gateway
   - DNS server
6. Set root password
7. Complete installation and reboot

### 4. Post-Installation Configuration

Access the Proxmox web interface at `https://YOUR_IP:8006`

#### Update System

```bash
apt update && apt upgrade -y
```

#### Configure Storage

1. Navigate to Datacenter → Storage
2. Add additional storage if needed (NFS, CIFS, ZFS, etc.)

#### Create API Token for Terraform

1. Navigate to Datacenter → Permissions → API Tokens
2. Click "Add"
3. Fill in:
   - User: `root@pam`
   - Token ID: `terraform`
   - Privilege Separation: Unchecked (for full access)
4. Click "Add"
5. **Save the token secret** - it will only be shown once
6. Update your Terraform configuration with the token

## VM Template Creation

For automated VM provisioning with Terraform, create a cloud-init enabled template:

### Ubuntu Cloud Image Template

```bash
# Download Ubuntu cloud image
wget https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img

# Create VM
qm create 9000 --memory 2048 --core 2 --name ubuntu-cloud --net0 virtio,bridge=vmbr0

# Import the disk
qm importdisk 9000 jammy-server-cloudimg-amd64.img local-lvm

# Attach the disk
qm set 9000 --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-9000-disk-0

# Add cloud-init drive
qm set 9000 --ide2 local-lvm:cloudinit

# Set boot order
qm set 9000 --boot c --bootdisk scsi0

# Add serial console
qm set 9000 --serial0 socket --vga serial0

# Enable QEMU guest agent
qm set 9000 --agent enabled=1

# Convert to template
qm template 9000
```

## Network Configuration

### Default Network Bridge (vmbr0)

The default bridge `vmbr0` is created during installation and connected to your physical network interface.

### Additional Networks

Create additional bridges in `/etc/network/interfaces`:

```bash
auto vmbr1
iface vmbr1 inet static
    address 10.0.1.1/24
    bridge-ports none
    bridge-stp off
    bridge-fd 0
```

## Backup Configuration

Configure automatic backups:

1. Navigate to Datacenter → Backup
2. Click "Add"
3. Configure schedule and retention
4. Select storage location
5. Select VMs to backup

## Resources

- [Proxmox VE Documentation](https://pve.proxmox.com/pve-docs/)
- [Proxmox VE Wiki](https://pve.proxmox.com/wiki/Main_Page)
- [Proxmox Community Forum](https://forum.proxmox.com/)
