# Infrastructure Diagram - Draw.io Format

## Diagram Description for Draw.io AI

This document provides structured descriptions for creating infrastructure diagrams in Draw.io.

---

## Main Architecture Diagram

### Components to Draw

#### Layer 1: Physical Infrastructure
```
Rectangle: "Physical Server"
- Label: "Proxmox Hypervisor"
- Color: Blue (#2196F3)
- Properties:
  * CPU: Multi-core processor
  * RAM: 32-128GB
  * Storage: HDD/SSD Arrays
  * Network: Dual NICs
```

#### Layer 2: Virtualization Platform
```
Container: "Proxmox VE Cluster"
Inside Physical Server
- Node: "pve (Primary Node)"
- Storage Pools:
  * local-lvm (VM disks)
  * local (ISO images, backups)
```

#### Layer 3: Management Services (Docker Containers)

**Netbox Stack**
```
Group Container: "Netbox Services"
- Container: "netbox-web" (Port 8000)
- Container: "netbox-worker" 
- Container: "netbox-postgres"
- Container: "netbox-redis"
- Container: "netbox-housekeeping"
Connect with arrows showing data flow
```

**Zabbix Stack**
```
Group Container: "Zabbix Services"
- Container: "zabbix-server" (Port 10051)
- Container: "zabbix-web" (Port 8080)
- Container: "zabbix-postgres"
- Container: "zabbix-agent"
Connect with arrows showing monitoring flow
```

**n8n Stack (Planned)**
```
Group Container: "n8n Services"
- Container: "n8n" (Port 5678)
- Container: "n8n-postgres"
Connect with arrows to all other services
```

#### Layer 4: Infrastructure as Code
```
Cloud Shape: "Terraform"
- Label: "IaC Automation"
- Connects to: Proxmox API
- Connects to: Netbox API
- Connects to: Zabbix API
Arrow: Bidirectional to Proxmox
```

#### Layer 5: Virtual Machines
```
Group: "Production VMs"
- VM: "web-server-01" (Ubuntu)
- VM: "db-server-01" (PostgreSQL)
- VM: "app-server-01" (Docker)
Each VM connects to:
- Proxmox (creation)
- Netbox (inventory)
- Zabbix (monitoring)
```

### Network Topology

#### Networks
```
Rectangle: "Management Network"
- Subnet: 10.0.0.0/24
- Gateway: 10.0.0.1
- Connected devices:
  * Proxmox: 10.0.0.1
  * Netbox: 10.0.0.10
  * Zabbix: 10.0.0.11
  * n8n: 10.0.0.12

Rectangle: "VM Network"
- Subnet: 10.0.1.0/24
- Gateway: 10.0.1.1
- Connected VMs: 10.0.1.100-254

Rectangle: "Container Network"
- Subnet: 10.0.2.0/24
- For isolated containers
```

### Data Flow Arrows

```
1. User → Terraform
   Label: "Define Infrastructure"
   Style: Solid, Blue

2. Terraform → Proxmox API
   Label: "Create/Modify VMs"
   Style: Solid, Green

3. Terraform → Netbox API
   Label: "Register VM"
   Style: Dashed, Orange

4. Netbox → Zabbix API
   Label: "Add to Monitoring"
   Style: Dashed, Red

5. Zabbix Agent → Zabbix Server
   Label: "Metrics"
   Style: Solid, Purple

6. n8n → All Services
   Label: "Orchestration"
   Style: Dashed, Yellow
```

---

## Simplified Component Diagram

### For Quick Reference

```
┌─────────────────────────────────────────────┐
│         Physical Server (Proxmox)           │
│  ┌─────────────────────────────────────┐   │
│  │   Management Containers (Docker)    │   │
│  │  ┌──────────┐  ┌──────────┐        │   │
│  │  │ Netbox   │  │ Zabbix   │        │   │
│  │  │ Stack    │  │ Stack    │        │   │
│  │  └──────────┘  └──────────┘        │   │
│  │  ┌──────────┐                      │   │
│  │  │   n8n    │                      │   │
│  │  └──────────┘                      │   │
│  └─────────────────────────────────────┘   │
│  ┌─────────────────────────────────────┐   │
│  │      Virtual Machines (VMs)         │   │
│  │  ┌────┐ ┌────┐ ┌────┐ ┌────┐       │   │
│  │  │VM1 │ │VM2 │ │VM3 │ │VM4 │       │   │
│  │  └────┘ └────┘ └────┘ └────┘       │   │
│  └─────────────────────────────────────┘   │
└─────────────────────────────────────────────┘
         ▲                 │
         │                 ▼
    ┌─────────┐      ┌──────────┐
    │Terraform│      │Developer │
    │  (IaC)  │      │Workstation│
    └─────────┘      └──────────┘
```

---

## Detailed Network Diagram

### Network Segments

```
Internet
    │
    ▼
┌────────────┐
│  Firewall  │
└─────┬──────┘
      │
      ▼
┌──────────────────────┐
│   Management VLAN    │
│    10.0.0.0/24       │
│  ┌────────────────┐  │
│  │ Proxmox Web UI │  │
│  │   10.0.0.1     │  │
│  └────────────────┘  │
│  ┌────────────────┐  │
│  │ Netbox         │  │
│  │   10.0.0.10    │  │
│  └────────────────┘  │
│  ┌────────────────┐  │
│  │ Zabbix         │  │
│  │   10.0.0.11    │  │
│  └────────────────┘  │
└──────────────────────┘
      │
      ├────────────────┐
      │                │
      ▼                ▼
┌──────────────┐ ┌──────────────┐
│  VM VLAN     │ │Container VLAN│
│10.0.1.0/24   │ │10.0.2.0/24   │
│              │ │              │
│ [VMs here]   │ │[Containers]  │
└──────────────┘ └──────────────┘
```

---

## Workflow Diagram

### VM Provisioning Flow

```
[Developer] 
    │
    │ 1. Write terraform code
    ▼
[Terraform]
    │
    │ 2. Apply configuration
    ▼
[Proxmox API]
    │
    │ 3. Create VM
    ▼
[New VM Created]
    │
    ├─── 4a. Register ───▶ [Netbox]
    │                         │
    │                         │ 5. Update inventory
    │                         ▼
    │                    [IPAM Updated]
    │
    └─── 4b. Add host ───▶ [Zabbix]
                             │
                             │ 6. Configure monitoring
                             ▼
                        [Monitoring Active]
    
[n8n Orchestration]
    │
    │ Coordinates all above steps
    │ Sends notifications
    │ Creates documentation
    ▼
[Complete]
```

---

## Monitoring Flow Diagram

```
┌──────────────┐
│  Proxmox VMs │
└──────┬───────┘
       │
       │ Zabbix Agent installed
       ▼
┌──────────────────┐
│  Zabbix Agent    │
│  (on each VM)    │
└──────┬───────────┘
       │
       │ Metrics (CPU, RAM, Disk, Network)
       ▼
┌──────────────────┐
│  Zabbix Server   │
│  - Collects data │
│  - Evaluates     │
│  - Triggers      │
└──────┬───────────┘
       │
       ├─── Store ───▶ [PostgreSQL Database]
       │
       ├─── Display ──▶ [Zabbix Web UI]
       │                (Port 8080)
       │
       └─── Alert ────▶ [n8n Workflows]
                            │
                            ├─▶ Email
                            ├─▶ Slack
                            ├─▶ SMS
                            └─▶ Auto-remediation
```

---

## Data Backup Flow

```
┌────────────────┐
│ Backup Trigger │ (Cron/n8n)
└───────┬────────┘
        │
        ▼
┌───────────────────────────┐
│  Unified Backup Script    │
└───┬───────────┬───────┬───┘
    │           │       │
    ▼           ▼       ▼
┌────────┐ ┌────────┐ ┌────────┐
│Netbox  │ │Zabbix  │ │Proxmox │
│DB Dump │ │DB Dump │ │VM Snap │
└───┬────┘ └───┬────┘ └───┬────┘
    │          │          │
    └──────┬───┴──────────┘
           ▼
    ┌─────────────┐
    │ Backup Dir  │
    │ /backups/   │
    └──────┬──────┘
           │
           ├─▶ Local Storage
           ├─▶ NAS/NFS
           └─▶ Cloud (S3/B2)
```

---

## Draw.io Quick Start Instructions

### Method 1: Using Draw.io AI
1. Open Draw.io (app.diagrams.net)
2. Click "Arrange" → "Insert" → "Advanced" → "From Text"
3. Paste the component descriptions above
4. AI will auto-generate diagram
5. Adjust layout and styling

### Method 2: Manual Creation
1. Create new blank diagram
2. Use shapes from left panel:
   - Rectangles for servers/containers
   - Cylinders for databases
   - Clouds for external services
   - Arrows for data flow
3. Group related components
4. Add colors:
   - Blue for infrastructure
   - Green for management
   - Orange for automation
   - Red for monitoring
   - Yellow for orchestration

### Recommended Layers
1. Background Layer: Network topology
2. Infrastructure Layer: Proxmox, physical servers
3. Services Layer: Docker containers
4. Application Layer: VMs
5. Automation Layer: Terraform, n8n
6. Arrows Layer: Data flows

---

## Export Formats

After creating diagram:
- PNG: For documentation
- SVG: For web/presentations
- XML: For version control
- PDF: For sharing

---

## Color Scheme

```
Physical Infrastructure:    #2196F3 (Blue)
Virtualization:            #4CAF50 (Green)
Management Services:        #FF9800 (Orange)
Monitoring:                #F44336 (Red)
Automation/Orchestration:  #FFC107 (Yellow)
Databases:                 #9C27B0 (Purple)
Networks:                  #00BCD4 (Cyan)
```

---

## Icons to Use

- Server: Standard server rack icon
- Container: Docker logo or box icon
- Database: Cylinder icon
- Network: Cloud or switch icon
- User: Person icon
- API: Gear/cog icon
- Workflow: Process flow icon
