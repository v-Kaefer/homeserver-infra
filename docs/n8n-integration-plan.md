# n8n Integration Plan

## Overview

This document outlines the integration of n8n workflow automation into the homeserver infrastructure to orchestrate and automate infrastructure management tasks.

---

## What is n8n?

n8n is a fair-code licensed workflow automation tool that allows you to connect different services and automate tasks. It's self-hosted and provides a visual workflow editor.

### Key Features
- **Visual Workflow Editor**: Drag-and-drop interface
- **200+ Integrations**: APIs, databases, webhooks
- **Self-hosted**: Full control over data
- **Extensible**: Custom nodes and JavaScript code
- **Event-driven**: Webhooks, cron schedules, triggers

---

## Integration Architecture

### High-Level Design

```
┌─────────────────────────────────────────────┐
│              n8n Workflows                   │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  │
│  │VM Lifecycle│ │Monitoring│ │ Backup  │  │
│  │  Workflow │  │ Workflow │ │Workflow │  │
│  └──────────┘  └──────────┘  └──────────┘  │
└────────┬────────────┬──────────────┬────────┘
         │            │              │
    ┌────┴────┐  ┌────┴────┐  ┌─────┴────┐
    ▼         ▼  ▼         ▼  ▼          ▼
┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐
│Terraform│ │Netbox │ │Zabbix │ │External│
│  API   │ │  API  │ │  API  │ │Services│
└────────┘ └────────┘ └────────┘ └────────┘
```

---

## Deployment Setup

### Docker Compose Configuration

Create `n8n/docker-compose.yml`:

```yaml
services:
  n8n:
    image: n8nio/n8n:latest
    restart: unless-stopped
    ports:
      - "5678:5678"
    environment:
      - N8N_BASIC_AUTH_ACTIVE=true
      - N8N_BASIC_AUTH_USER=${N8N_USER}
      - N8N_BASIC_AUTH_PASSWORD=${N8N_PASSWORD}
      - N8N_HOST=${N8N_HOST:-localhost}
      - N8N_PORT=5678
      - N8N_PROTOCOL=http
      - NODE_ENV=production
      - WEBHOOK_URL=http://${N8N_HOST:-localhost}:5678/
      - GENERIC_TIMEZONE=UTC
      - DB_TYPE=postgresdb
      - DB_POSTGRESDB_DATABASE=n8n
      - DB_POSTGRESDB_HOST=n8n-postgres
      - DB_POSTGRESDB_PORT=5432
      - DB_POSTGRESDB_USER=n8n
      - DB_POSTGRESDB_PASSWORD=${POSTGRES_PASSWORD}
    volumes:
      - n8n-data:/home/node/.n8n
      - ./workflows:/home/node/.n8n/workflows
    depends_on:
      - n8n-postgres
    networks:
      - n8n-net

  n8n-postgres:
    image: postgres:15-alpine
    restart: unless-stopped
    environment:
      - POSTGRES_USER=n8n
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
      - POSTGRES_DB=n8n
    volumes:
      - n8n-postgres-data:/var/lib/postgresql/data
    networks:
      - n8n-net

volumes:
  n8n-data:
  n8n-postgres-data:

networks:
  n8n-net:
    driver: bridge
```

### Makefile Integration

Add to `n8n/Makefile`:

```makefile
.PHONY: help n8n-up n8n-down n8n-logs n8n-status n8n-backup

n8n-up: ## Start n8n
	@docker compose up -d
	@echo "n8n is starting at http://localhost:5678"

n8n-down: ## Stop n8n
	@docker compose down

n8n-logs: ## Show n8n logs
	@docker compose logs -f

n8n-status: ## Show n8n status
	@docker compose ps

n8n-backup: ## Backup n8n workflows and database
	@mkdir -p ../backups
	@docker compose exec -T n8n-postgres pg_dump -U n8n n8n > ../backups/n8n-backup-$(date +%Y%m%d-%H%M%S).sql
	@cp -r workflows ../backups/n8n-workflows-$(date +%Y%m%d-%H%M%S)
```

---

## Workflow Templates

### 1. VM Provisioning Workflow

**Trigger**: Webhook or Manual
**Purpose**: Automate complete VM creation process

```
Steps:
1. Receive VM request (webhook)
2. Validate request parameters
3. Call Terraform Cloud/API to provision VM
4. Wait for VM creation
5. Register VM in Netbox
   - Create virtual machine
   - Assign IP address
   - Add to cluster
6. Add VM to Zabbix monitoring
   - Create host
   - Link templates
   - Configure triggers
7. Send notifications
   - Slack/Email with VM details
   - Update ticket system
8. Generate documentation
   - Update inventory
   - Create VM runbook
```

### 2. Alert Management Workflow

**Trigger**: Zabbix webhook
**Purpose**: Intelligent alert handling

```
Steps:
1. Receive alert from Zabbix
2. Determine severity
3. Check if known issue
   - Query Netbox for maintenance windows
   - Check previous incidents
4. Attempt auto-remediation
   - Restart service
   - Clear disk space
   - Scale resources
5. If remediation fails:
   - Create incident ticket
   - Send escalated notification
   - Page on-call engineer
6. Log all actions
```

### 3. Backup Orchestration Workflow

**Trigger**: Scheduled (daily at 2 AM)
**Purpose**: Centralized backup management

```
Steps:
1. Trigger backup for all services
   - Netbox database
   - Zabbix database
   - n8n workflows
   - Proxmox VM snapshots
2. Wait for completion
3. Verify backup integrity
4. Upload to cloud storage (S3/B2)
5. Clean old backups (retention policy)
6. Send backup report
   - Success/failure status
   - Backup sizes
   - Storage usage
```

### 4. Infrastructure Health Check

**Trigger**: Scheduled (every hour)
**Purpose**: Proactive monitoring

```
Steps:
1. Query all services
   - Proxmox API health
   - Netbox API health
   - Zabbix API health
2. Check resource usage
   - Disk space
   - Memory usage
   - CPU load
3. Validate configurations
   - Check for drift
   - Verify backups exist
4. Generate health report
5. Alert if issues found
```

### 5. Self-Service VM Portal

**Trigger**: Webhook from web form
**Purpose**: Allow users to request VMs

```
Steps:
1. Receive VM request
2. Validate user permissions
3. Check quota/limits
4. Provision VM via Terraform
5. Configure VM
   - Install software
   - Configure monitoring
   - Apply security policies
6. Send credentials to user
7. Add to cost tracking
```

---

## API Integration Details

### Terraform Integration

**Option 1: Terraform Cloud API**
```javascript
// n8n HTTP Request node
{
  "method": "POST",
  "url": "https://app.terraform.io/api/v2/runs",
  "headers": {
    "Authorization": "Bearer {{$env.TF_TOKEN}}",
    "Content-Type": "application/vnd.api+json"
  },
  "body": {
    "data": {
      "type": "runs",
      "attributes": {
        "workspace": "proxmox-infra"
      }
    }
  }
}
```

**Option 2: Local Terraform Execution**
```javascript
// n8n Execute Command node
{
  "command": "terraform apply -auto-approve",
  "cwd": "/path/to/terraform"
}
```

### Netbox Integration

```javascript
// n8n HTTP Request node - Create VM
{
  "method": "POST",
  "url": "http://netbox:8000/api/virtualization/virtual-machines/",
  "headers": {
    "Authorization": "Token {{$env.NETBOX_TOKEN}}",
    "Content-Type": "application/json"
  },
  "body": {
    "name": "{{$node.terraform.vm_name}}",
    "cluster": 1,
    "status": "active",
    "vcpus": 2,
    "memory": 4096
  }
}
```

### Zabbix Integration

```javascript
// n8n HTTP Request node - Create Host
{
  "method": "POST",
  "url": "http://zabbix:8080/api_jsonrpc.php",
  "headers": {
    "Content-Type": "application/json-rpc"
  },
  "body": {
    "jsonrpc": "2.0",
    "method": "host.create",
    "params": {
      "host": "{{$node.terraform.vm_name}}",
      "interfaces": [{
        "type": 1,
        "main": 1,
        "ip": "{{$node.terraform.vm_ip}}",
        "port": "10050"
      }],
      "groups": [{"groupid": "2"}],
      "templates": [{"templateid": "10001"}]
    },
    "auth": "{{$env.ZABBIX_TOKEN}}",
    "id": 1
  }
}
```

---

## Security Configuration

### API Tokens

Store in n8n credentials:
```
TERRAFORM_TOKEN: xxx
NETBOX_TOKEN: xxx
ZABBIX_TOKEN: xxx
PROXMOX_TOKEN: xxx
SLACK_WEBHOOK: xxx
```

### Network Security

```yaml
# Restrict n8n access
networks:
  n8n-net:
    internal: false  # Allow external webhooks
    
# Use internal network for service communication
  management-net:
    internal: true
```

### Access Control

```
1. Enable basic auth for n8n
2. Use strong passwords
3. Implement OAuth if needed
4. Restrict webhook endpoints
5. Use HTTPS in production
```

---

## Monitoring & Logging

### n8n Metrics

Monitor via Zabbix:
- Workflow execution count
- Failed workflow count
- Execution duration
- Database size
- Memory usage

### Logging

```javascript
// Add to all workflows
logger node:
{
  "level": "info",
  "message": "Workflow {{$workflow.name}} executed",
  "data": {
    "execution_id": "{{$execution.id}}",
    "status": "{{$execution.status}}",
    "duration": "{{$execution.duration}}"
  }
}
```

---

## Implementation Phases

### Phase 1: Setup (Week 1)
- [ ] Deploy n8n container
- [ ] Configure authentication
- [ ] Set up API credentials
- [ ] Create first test workflow
- [ ] Document access and usage

**Deliverables**:
- n8n running and accessible
- Basic workflow template
- Setup documentation

### Phase 2: Core Workflows (Week 2-3)
- [ ] VM provisioning workflow
- [ ] Backup orchestration
- [ ] Health check workflow
- [ ] Alert management workflow

**Deliverables**:
- 4 production-ready workflows
- Workflow documentation
- Testing reports

### Phase 3: Advanced Features (Week 4+)
- [ ] Self-service portal
- [ ] Cost tracking
- [ ] Resource optimization
- [ ] Custom integrations

**Deliverables**:
- Self-service system
- Dashboard
- Advanced workflows

---

## Best Practices

### Workflow Design
1. **Error Handling**: Always add error handlers
2. **Logging**: Log all important steps
3. **Idempotency**: Make workflows rerunnable
4. **Testing**: Test with sample data first
5. **Documentation**: Document each workflow

### Performance
1. Use async execution where possible
2. Implement rate limiting
3. Cache API responses
4. Optimize database queries
5. Monitor execution times

### Maintenance
1. Regular backups of workflows
2. Version control for workflow JSON
3. Update n8n regularly
4. Review and optimize workflows
5. Clean up old executions

---

## Troubleshooting

### Common Issues

**Issue**: Workflow execution timeout
**Solution**: Increase timeout in settings or use async execution

**Issue**: API rate limiting
**Solution**: Implement retry logic with exponential backoff

**Issue**: Webhook not triggering
**Solution**: Check firewall rules and webhook URL

**Issue**: Database connection errors
**Solution**: Verify postgres container is running and credentials

---

## Cost Analysis

### Resource Usage
- CPU: 0.5-1 core
- RAM: 512MB-1GB
- Storage: 2-5GB (workflows + database)
- Network: Minimal

### Time Savings (Estimated)
- VM provisioning: 15 min → 2 min (87% reduction)
- Alert response: 30 min → 5 min (83% reduction)
- Backup management: 45 min → 5 min (89% reduction)
- Health checks: Manual → Automated (100% time saved)

### ROI
- Initial setup: 8-16 hours
- Monthly time saved: 20-40 hours
- Break-even: 2-4 weeks

---

## Next Steps

1. Review this plan
2. Approve implementation
3. Set up n8n environment
4. Start with Phase 1
5. Iterate based on needs

---

## Resources

- [n8n Documentation](https://docs.n8n.io/)
- [n8n Community](https://community.n8n.io/)
- [Workflow Templates](https://n8n.io/workflows)
- [API Integration Guide](https://docs.n8n.io/integrations/)
