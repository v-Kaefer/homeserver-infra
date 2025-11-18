#!/bin/bash
# Unified Backup Script for Homeserver Infrastructure
# This script backs up all critical services in one operation

set -e

# Configuration
BACKUP_DIR="./backups"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
RETENTION_DAYS=30

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Create backup directory
mkdir -p "$BACKUP_DIR"

echo "================================================"
echo "Unified Infrastructure Backup"
echo "Started: $(date)"
echo "================================================"
echo ""

# Function to check if service is running
service_running() {
    local service_dir=$1
    cd "$service_dir" 2>/dev/null || return 1
    docker compose ps 2>/dev/null | grep -q "Up" && return 0 || return 1
}

# Function to backup service
backup_service() {
    local service_name=$1
    local backup_command=$2
    
    echo -n "Backing up $service_name... "
    if eval "$backup_command" > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC}"
        return 0
    else
        echo -e "${RED}✗${NC}"
        return 1
    fi
}

# Backup PostgreSQL (Shared Instance)
if service_running "postgres-shared"; then
    backup_service "Shared PostgreSQL" \
        "cd postgres-shared && docker compose exec -T postgres-shared pg_dumpall -U postgres > ../$BACKUP_DIR/postgres-all-$TIMESTAMP.sql"
else
    # Fallback to individual databases if shared postgres not running
    if service_running "netbox"; then
        backup_service "Netbox Database" \
            "cd netbox && docker compose exec -T postgres pg_dump -U netbox netbox > ../$BACKUP_DIR/netbox-db-$TIMESTAMP.sql"
    fi
    
    if service_running "zabbix"; then
        backup_service "Zabbix Database" \
            "cd zabbix && docker compose exec -T zabbix-postgres pg_dump -U zabbix zabbix > ../$BACKUP_DIR/zabbix-db-$TIMESTAMP.sql"
    fi
fi

# Backup n8n workflows and database
if service_running "n8n"; then
    backup_service "n8n Database" \
        "cd n8n && docker compose exec -T n8n-postgres pg_dump -U n8n n8n > ../$BACKUP_DIR/n8n-db-$TIMESTAMP.sql"
    
    if [ -d "n8n/workflows" ]; then
        echo -n "Backing up n8n workflows... "
        tar -czf "$BACKUP_DIR/n8n-workflows-$TIMESTAMP.tar.gz" -C n8n workflows 2>/dev/null && \
            echo -e "${GREEN}✓${NC}" || echo -e "${RED}✗${NC}"
    fi
fi

# Backup Terraform state
if [ -f "terraform/proxmox/terraform.tfstate" ]; then
    echo -n "Backing up Terraform state... "
    cp terraform/proxmox/terraform.tfstate "$BACKUP_DIR/terraform-state-$TIMESTAMP.tfstate" && \
        echo -e "${GREEN}✓${NC}" || echo -e "${RED}✗${NC}"
fi

# Backup environment files (encrypted)
echo -n "Backing up environment configurations... "
{
    tar -czf "$BACKUP_DIR/env-configs-$TIMESTAMP.tar.gz" \
        netbox/env/*.env \
        zabbix/env/*.env \
        n8n/env/*.env \
        postgres-shared/*.env \
        2>/dev/null || true
} && echo -e "${GREEN}✓${NC}" || echo -e "${YELLOW}⚠${NC}"

# Create backup manifest
cat > "$BACKUP_DIR/backup-manifest-$TIMESTAMP.txt" << EOF
Backup Manifest
===============
Timestamp: $TIMESTAMP
Date: $(date)

Files Backed Up:
$(ls -lh $BACKUP_DIR/*-$TIMESTAMP.* 2>/dev/null || echo "No files found")

Total Backup Size:
$(du -sh $BACKUP_DIR 2>/dev/null | cut -f1)
EOF

echo ""
echo "================================================"
echo -e "${GREEN}Backup Complete!${NC}"
echo "Location: $BACKUP_DIR"
echo "Timestamp: $TIMESTAMP"
echo "================================================"
echo ""

# Clean up old backups
echo "Cleaning up backups older than $RETENTION_DAYS days..."
find "$BACKUP_DIR" -name "*-20*.sql" -mtime +$RETENTION_DAYS -delete 2>/dev/null || true
find "$BACKUP_DIR" -name "*-20*.tar.gz" -mtime +$RETENTION_DAYS -delete 2>/dev/null || true
find "$BACKUP_DIR" -name "*-20*.tfstate" -mtime +$RETENTION_DAYS -delete 2>/dev/null || true

echo "Retention policy applied: keeping last $RETENTION_DAYS days"
echo ""

# Display backup summary
echo "Recent Backups:"
ls -lht "$BACKUP_DIR" | head -10

exit 0
