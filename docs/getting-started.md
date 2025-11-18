# Getting Started with Your Homeserver Infrastructure

This guide will walk you through setting up your complete homeserver infrastructure using Proxmox, Terraform, and Netbox.

## Prerequisites

- Physical server or compatible hardware for Proxmox
- Basic understanding of virtualization concepts
- Command line familiarity
- USB drive for Proxmox installation (2GB minimum)

## Step-by-Step Setup

### Phase 1: Install Proxmox VE (The Foundation)

1. **Download Proxmox VE**
   - Visit https://www.proxmox.com/en/downloads
   - Download the latest Proxmox VE ISO

2. **Create Bootable USB**
   - Use balenaEtcher (recommended for beginners)
   - Or use `dd` on Linux/macOS

3. **Install Proxmox**
   - Boot from USB
   - Follow installation wizard
   - Configure network (note the IP address!)
   - Set root password

4. **Access Proxmox Web Interface**
   - Open browser to `https://YOUR_IP:8006`
   - Login as `root`
   - Accept the certificate warning (self-signed)

5. **Post-Installation**
   - Update system: `apt update && apt upgrade -y`
   - Configure storage (if needed)
   - Create API token for Terraform:
     - Datacenter → Permissions → API Tokens
     - Add token for `root@pam`
     - Save the secret (shown only once!)

📖 **Detailed Guide**: [Proxmox Setup Guide](proxmox-setup.md)

### Phase 2: Set Up Netbox (Network Source of Truth)

1. **Clone This Repository**
   ```bash
   git clone https://github.com/v-Kaefer/homeserver-infra.git
   cd homeserver-infra/netbox
   ```

2. **Configure Environment**
   ```bash
   cp env/postgres.env.example env/postgres.env
   cp env/netbox.env.example env/netbox.env
   ```

3. **Edit Configuration Files**
   - `env/postgres.env`: Set a strong database password
   - `env/netbox.env`: 
     - Match DB_PASSWORD to postgres password
     - Generate SECRET_KEY: `python3 -c 'from secrets import token_urlsafe; print(token_urlsafe(50))'`
     - Set the SECRET_KEY value

4. **Start Netbox**
   ```bash
   docker-compose up -d
   ```

5. **Create Superuser**
   ```bash
   docker-compose exec netbox python /opt/netbox/netbox/manage.py createsuperuser
   ```

6. **Access Netbox**
   - Open browser to http://localhost:8000
   - Login with your superuser credentials
   - Create API token (Profile → API Tokens)
   - Save the token for Terraform integration

7. **Initial Configuration**
   - Create a Site (Organization → Sites)
   - Add Device Roles (Devices → Device Roles)
   - Configure IP Prefixes (IPAM → Prefixes)

📖 **Detailed Guide**: [Netbox Setup Guide](netbox-setup.md)

### Phase 3: Set Up Terraform (Infrastructure as Code)

1. **Install Terraform**
   
   **Linux:**
   ```bash
   wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
   echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
   sudo apt update && sudo apt install terraform
   ```
   
   **macOS:**
   ```bash
   brew install terraform
   ```
   
   **Windows:**
   - Download from https://www.terraform.io/downloads
   - Or use: `choco install terraform`

2. **Configure Terraform**
   ```bash
   cd ../terraform/proxmox
   cp terraform.tfvars.example terraform.tfvars
   ```

3. **Edit terraform.tfvars**
   ```hcl
   proxmox_api_url          = "https://YOUR_PROXMOX_IP:8006/api2/json"
   proxmox_api_token_id     = "root@pam!terraform"
   proxmox_api_token_secret = "YOUR_API_TOKEN_SECRET"
   proxmox_tls_insecure     = true
   proxmox_node             = "pve"
   ```

4. **Initialize Terraform**
   ```bash
   terraform init
   ```

5. **Create Your First VM Template** (on Proxmox)
   ```bash
   # SSH to your Proxmox server
   ssh root@YOUR_PROXMOX_IP
   
   # Download Ubuntu cloud image
   wget https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img
   
   # Create template (VM ID 9000)
   qm create 9000 --memory 2048 --core 2 --name ubuntu-cloud --net0 virtio,bridge=vmbr0
   qm importdisk 9000 jammy-server-cloudimg-amd64.img local-lvm
   qm set 9000 --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-9000-disk-0
   qm set 9000 --ide2 local-lvm:cloudinit
   qm set 9000 --boot c --bootdisk scsi0
   qm set 9000 --serial0 socket --vga serial0
   qm set 9000 --agent enabled=1
   qm template 9000
   ```

6. **Test Terraform**
   ```bash
   terraform validate
   terraform plan
   ```

📖 **Detailed Guide**: [Terraform Setup Guide](terraform-setup.md)

### Phase 4: Deploy Your First VM

1. **Create a VM Configuration**
   
   Create `terraform/proxmox/vms.tf`:
   ```hcl
   module "test_vm" {
     source = "../modules/proxmox-vm"
     
     vm_name        = "test-vm-01"
     vm_id          = 100
     target_node    = var.proxmox_node
     clone_template = "ubuntu-cloud"
     
     cores     = 2
     memory    = 2048
     disk_size = "20G"
     
     network_bridge = "vmbr0"
     ip_address     = "dhcp"
   }
   
   output "test_vm_ip" {
     value = module.test_vm.vm_ip
   }
   ```

2. **Deploy the VM**
   ```bash
   terraform plan
   terraform apply
   ```

3. **Verify in Proxmox**
   - Open Proxmox web interface
   - Check that VM 100 appears
   - Start the VM
   - Check the console

4. **Register in Netbox** (optional, for now - can be automated later)
   - Login to Netbox
   - Navigate to Virtualization → Virtual Machines
   - Add the VM details

## Next Steps

### Expand Your Infrastructure

1. **Create Multiple VMs**
   - Use Terraform loops for multiple similar VMs
   - See examples in [Terraform Setup Guide](terraform-setup.md)

2. **Organize with Netbox**
   - Document all VMs and IPs
   - Create network diagrams
   - Set up device roles and types

3. **Automate Everything**
   - Use Terraform to manage all VMs
   - Integrate Netbox with Terraform for IP management
   - Set up automated backups

4. **Advanced Features**
   - Configure VLANs for network segmentation
   - Set up monitoring with Prometheus/Grafana
   - Implement automated configuration management (Ansible)
   - Configure high availability

### Learning Resources

- **Proxmox**: https://pve.proxmox.com/pve-docs/
- **Terraform**: https://learn.hashicorp.com/terraform
- **Netbox**: https://docs.netbox.dev/

### Common Issues and Solutions

#### Proxmox

**Issue**: Cannot access web interface
- **Solution**: Check firewall, verify IP address, ensure Proxmox service is running

**Issue**: VM won't start
- **Solution**: Check resource availability (CPU, RAM, storage), review VM logs

#### Terraform

**Issue**: Authentication error
- **Solution**: Verify API token, check token permissions, ensure API URL is correct

**Issue**: Resource already exists
- **Solution**: Import existing resource or change VM ID

#### Netbox

**Issue**: Cannot create superuser
- **Solution**: Ensure database is initialized, check container logs

**Issue**: 500 error in web interface
- **Solution**: Check SECRET_KEY is set, verify database connection, review logs

## Backup Strategy

⚠️ **Important**: Always maintain backups!

1. **Proxmox Backups**
   - Configure scheduled backups in Proxmox
   - Store backups on separate storage

2. **Netbox Backups**
   ```bash
   # Backup database
   docker-compose exec postgres pg_dump -U netbox netbox > netbox_backup.sql
   ```

3. **Terraform State**
   - Keep `terraform.tfstate` backed up
   - Consider using remote state (S3, Terraform Cloud)

## Security Considerations

1. **Proxmox**
   - Use strong passwords
   - Configure firewall
   - Keep system updated
   - Use API tokens instead of passwords

2. **Netbox**
   - Use strong SECRET_KEY
   - Change default passwords
   - Use HTTPS in production
   - Restrict network access

3. **Terraform**
   - Never commit `terraform.tfvars` to git
   - Use `.gitignore` (already configured)
   - Store secrets securely (environment variables, vault)

## Getting Help

- **Documentation**: Check the guides in the `docs/` directory
- **Proxmox Forum**: https://forum.proxmox.com/
- **Terraform Discussion**: https://discuss.hashicorp.com/c/terraform/
- **Netbox Slack**: https://netdev.chat/

## Summary

You now have:
- ✅ Proxmox VE as your hypervisor
- ✅ Netbox as your network source of truth
- ✅ Terraform for automated infrastructure deployment
- ✅ A working VM deployed via Infrastructure as Code

Welcome to modern infrastructure management! 🎉
