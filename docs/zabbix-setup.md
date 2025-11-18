# Zabbix Monitoring Setup Guide

This guide covers setting up and using Zabbix for monitoring your homeserver infrastructure.

## What is Zabbix?

Zabbix is an open-source enterprise-class monitoring solution for networks and applications. It provides:

- **Infrastructure Monitoring**: Servers, VMs, containers, network devices
- **Application Monitoring**: Services, processes, custom metrics
- **Alerting**: Email, SMS, webhooks for proactive notifications
- **Visualization**: Dashboards, graphs, maps
- **Automation**: Auto-discovery, auto-registration
- **Scalability**: Can monitor thousands of devices

## Installation

### Using Docker Compose (Recommended)

1. Navigate to the zabbix directory:
   ```bash
   cd zabbix
   ```

2. Create environment files:
   ```bash
   cp env/postgres.env.example env/postgres.env
   cp env/zabbix.env.example env/zabbix.env
   cp env/zabbix-agent.env.example env/zabbix-agent.env
   ```

3. Edit `env/postgres.env` and set a strong password:
   ```bash
   POSTGRES_PASSWORD=your_secure_password_here
   ```

4. Edit `env/zabbix.env`:
   - Update `POSTGRES_PASSWORD` to match postgres password
   - Set `PHP_TZ` to your timezone (e.g., `America/New_York`, `Europe/London`)

5. Edit `env/zabbix-agent.env`:
   - Update `ZBX_HOSTNAME` if needed

6. Start Zabbix:
   ```bash
   docker compose up -d
   ```

7. Access Zabbix at http://localhost:8080

## Initial Configuration

### 1. Login

Default credentials:
- **Username**: Admin
- **Password**: zabbix

⚠️ **Change the default password immediately after first login!**

To change password:
1. Click on user icon (top right) → User settings
2. Click "Change password"
3. Set a strong new password

### 2. Configure Time Zone

1. Navigate to Administration → General → GUI
2. Set your time zone
3. Click "Update"

### 3. Set Up Email Notifications (Optional)

1. Navigate to Administration → Media types
2. Click on "Email" or create new media type
3. Configure SMTP settings:
   - SMTP server
   - SMTP port (usually 587 for TLS)
   - Authentication credentials
4. Test the configuration

## Monitoring Proxmox

### Method 1: SNMP Monitoring

1. **Enable SNMP on Proxmox**:
   ```bash
   apt-get install snmpd
   systemctl enable snmpd
   systemctl start snmpd
   ```

2. **Configure SNMP** in `/etc/snmp/snmpd.conf`:
   ```
   rocommunity public
   syslocation "Home Datacenter"
   syscontact admin@example.com
   ```

3. **Add Host in Zabbix**:
   - Configuration → Hosts → Create host
   - Host name: proxmox-01
   - Groups: Linux servers
   - Interfaces: SNMP (port 161)
   - Templates: Template OS Linux SNMP

### Method 2: Zabbix Agent

1. **Install Zabbix Agent on Proxmox**:
   ```bash
   wget https://repo.zabbix.com/zabbix/6.4/debian/pool/main/z/zabbix-release/zabbix-release_6.4-1+debian12_all.deb
   dpkg -i zabbix-release_6.4-1+debian12_all.deb
   apt update
   apt install zabbix-agent2
   ```

2. **Configure Agent** in `/etc/zabbix/zabbix_agent2.conf`:
   ```
   Server=ZABBIX_SERVER_IP
   ServerActive=ZABBIX_SERVER_IP
   Hostname=proxmox-01
   ```

3. **Start Agent**:
   ```bash
   systemctl enable zabbix-agent2
   systemctl start zabbix-agent2
   ```

4. **Add Host in Zabbix**:
   - Configuration → Hosts → Create host
   - Host name: proxmox-01
   - Groups: Linux servers
   - Interfaces: Agent (port 10050)
   - Templates: Template OS Linux by Zabbix agent

## Monitoring VMs

### Auto-Discovery

1. Navigate to Configuration → Discovery
2. Create discovery rule:
   - IP range: Your VM network (e.g., 10.0.1.1-254)
   - Checks: Zabbix agent, ICMP ping
   - Device uniqueness criteria: IP address

### Manual Host Addition

1. Configuration → Hosts → Create host
2. Fill in details:
   - Host name: vm-name
   - Groups: Virtual machines
   - Interfaces: Agent or SNMP
3. Link templates:
   - Template OS Linux by Zabbix agent
   - Template Module ICMP Ping

## Integration with Terraform

You can automate Zabbix host creation when deploying VMs with Terraform.

### Using Zabbix Terraform Provider

Add to your Terraform configuration:

```hcl
terraform {
  required_providers {
    zabbix = {
      source  = "claranet/zabbix"
      version = "~> 1.0"
    }
  }
}

provider "zabbix" {
  username = var.zabbix_user
  password = var.zabbix_password
  url      = "http://localhost:8080/api_jsonrpc.php"
}

# Create host in Zabbix when VM is created
resource "zabbix_host" "vm" {
  host = module.web_server.vm_name
  
  groups = [
    data.zabbix_hostgroup.linux.id
  ]
  
  interfaces {
    type = "agent"
    main = true
    ip   = module.web_server.vm_ip
    port = 10050
  }
  
  templates = [
    data.zabbix_template.linux.id
  ]
}
```

## Monitoring Containers

### Docker Monitoring

1. Install Zabbix agent in containers
2. Configure agent to report to Zabbix server
3. Use Template App Docker template

### LXC Monitoring

1. Install Zabbix agent in LXC containers
2. Configure similar to VMs
3. Create custom templates for specific services

## Creating Dashboards

1. Navigate to Monitoring → Dashboards
2. Click "Create dashboard"
3. Add widgets:
   - System information
   - Problems
   - Graphs (CPU, Memory, Network)
   - Maps
4. Customize layout and save

## Setting Up Alerts

### Create Trigger

1. Configuration → Hosts → Select host → Triggers
2. Create trigger:
   - Name: "High CPU usage"
   - Expression: `avg(/host/system.cpu.util,5m)>90`
   - Severity: Warning

### Create Action

1. Configuration → Actions → Trigger actions
2. Create action:
   - Name: "Notify on high CPU"
   - Conditions: Trigger matches pattern
   - Operations: Send message to user group

## Best Practices

1. **Regular Backups**: Use `make zabbix-backup` to backup configuration
2. **Template Usage**: Use templates for consistent monitoring
3. **Auto-Discovery**: Leverage auto-discovery for dynamic environments
4. **Alerting**: Set appropriate thresholds to avoid alert fatigue
5. **Maintenance Periods**: Use maintenance periods during updates
6. **Custom Scripts**: Create custom monitoring scripts for specific needs
7. **Performance**: Monitor Zabbix server performance itself
8. **Security**: Use encrypted connections for agents

## Maintenance

### Backup

```bash
# From zabbix directory
make zabbix-backup

# Or using main Makefile
make zabbix-backup
```

### Restore

```bash
make zabbix-restore BACKUP_FILE=../backups/zabbix-backup-20231114-120000.sql
```

### Update

```bash
make zabbix-update
```

### View Logs

```bash
make zabbix-logs
```

## Troubleshooting

### Cannot Access Web Interface

- Check containers are running: `make zabbix-status`
- Check logs: `make zabbix-logs`
- Verify port 8080 is not in use

### Agent Not Connecting

- Verify firewall allows port 10050
- Check agent configuration
- Verify agent is running: `systemctl status zabbix-agent2`

### Database Connection Issues

- Check postgres container is running
- Verify credentials in env files match
- Check database logs

## Resources

- [Zabbix Documentation](https://www.zabbix.com/documentation/current/)
- [Zabbix Templates](https://www.zabbix.com/integrations)
- [Zabbix Community](https://www.zabbix.com/forum)
- [Docker Images](https://hub.docker.com/u/zabbix)
