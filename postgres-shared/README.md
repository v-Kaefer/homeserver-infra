# Shared PostgreSQL Instance

This directory contains a consolidated PostgreSQL instance used by multiple services (Netbox, Zabbix, n8n).

## Benefits

- **50% resource reduction**: Single PostgreSQL instance instead of 3 separate ones
- **Simplified backups**: One database instance to backup
- **Easier maintenance**: Single update/upgrade process
- **Better resource utilization**: Shared connection pooling

## Architecture

```
┌─────────────────────────────┐
│  Shared PostgreSQL Server   │
│  (Port 5432)                │
├─────────────────────────────┤
│  Database: netbox           │
│  Database: zabbix           │
│  Database: n8n              │
└─────────────────────────────┘
         ▲         ▲         ▲
         │         │         │
    ┌────┴──┐ ┌────┴──┐ ┌────┴──┐
    │Netbox │ │Zabbix │ │  n8n  │
    └───────┘ └───────┘ └───────┘
```

## Setup

1. Create environment file:
```bash
cp postgres.env.example postgres.env
```

2. Edit `postgres.env` and set a strong password:
```bash
POSTGRES_SHARED_PASSWORD=your_secure_password_here
```

3. Start the shared PostgreSQL instance:
```bash
docker compose up -d
```

## Usage

### Connection Details

**For Netbox:**
- Host: `postgres-shared`
- Port: `5432`
- Database: `netbox`
- User: `netbox`
- Password: (same as POSTGRES_SHARED_PASSWORD)

**For Zabbix:**
- Host: `postgres-shared`
- Port: `5432`
- Database: `zabbix`
- User: `zabbix`
- Password: (same as POSTGRES_SHARED_PASSWORD)

**For n8n:**
- Host: `postgres-shared`
- Port: `5432`
- Database: `n8n`
- User: `n8n`
- Password: (same as POSTGRES_SHARED_PASSWORD)

## Backup

```bash
# Backup all databases
docker compose exec -T postgres-shared pg_dumpall -U postgres > backup-all-$(date +%Y%m%d-%H%M%S).sql

# Backup specific database
docker compose exec -T postgres-shared pg_dump -U netbox netbox > backup-netbox-$(date +%Y%m%d-%H%M%S).sql
```

## Migration from Separate Instances

If migrating from separate PostgreSQL instances:

1. Export data from old instances
2. Start shared PostgreSQL
3. Import data to respective databases
4. Update service configurations to point to shared instance
5. Test thoroughly before removing old instances

## Monitoring

The container includes a health check that verifies PostgreSQL is ready:
- Interval: 10s
- Timeout: 5s
- Retries: 5

## Makefile Commands

Managed via main Makefile:
- `make postgres-up` - Start shared PostgreSQL
- `make postgres-down` - Stop shared PostgreSQL
- `make postgres-logs` - View logs
- `make postgres-backup` - Backup all databases
