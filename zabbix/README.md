# Zabbix Monitoring

This directory contains the Docker Compose configuration for Zabbix monitoring.

## Overview

Zabbix monitors your homeserver infrastructure including:
- Proxmox hypervisor
- Virtual machines
- Containers
- Network devices
- Applications and services

## Quick Start

```bash
# Setup environment files
cp env/postgres.env.example env/postgres.env
cp env/zabbix.env.example env/zabbix.env
cp env/zabbix-agent.env.example env/zabbix-agent.env

# Edit env files with your configuration
# Important: Change passwords in postgres.env and zabbix.env

# Start Zabbix
docker compose up -d

# Access web interface
# URL: http://localhost:8080
# Default login: Admin / zabbix
```

## Using Makefile

```bash
make zabbix-up         # Start Zabbix
make zabbix-down       # Stop Zabbix
make zabbix-logs       # View logs
make zabbix-status     # Show container status
make zabbix-backup     # Backup database
```

## Components

- **zabbix-postgres**: PostgreSQL database for Zabbix data
- **zabbix-server**: Zabbix monitoring server
- **zabbix-web**: Web interface (Nginx + PHP)
- **zabbix-agent**: Agent for monitoring the Docker host

## Ports

- **8080**: Web interface
- **10051**: Zabbix server (trapper)

## Documentation

See [Zabbix Setup Guide](../docs/zabbix-setup.md) for detailed instructions on:
- Initial configuration
- Monitoring Proxmox
- Monitoring VMs and containers
- Setting up alerts
- Creating dashboards
- Integration with Terraform

## Resources

- [Zabbix Documentation](https://www.zabbix.com/documentation/current/)
- [Zabbix Docker Images](https://hub.docker.com/u/zabbix)
