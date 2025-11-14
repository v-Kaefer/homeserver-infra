# Netbox Management Makefile
# 
# This Makefile provides commands for managing the Netbox instance
# Can be used from the main Makefile or directly from the netbox directory

.PHONY: help netbox-up netbox-down netbox-restart netbox-logs netbox-status netbox-backup netbox-restore netbox-shell netbox-create-superuser netbox-setup-site

help: ## Show this help message
	@echo "Netbox Management Commands"
	@echo ""
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-25s %s\n", $$1, $$2}'

netbox-up: ## Start Netbox containers
	@echo "Starting Netbox..."
	@docker compose up -d
	@echo "Netbox is starting. Access it at http://localhost:8000"
	@echo "Run 'make netbox-logs' to view logs"

netbox-down: ## Stop Netbox containers
	@echo "Stopping Netbox..."
	@docker compose down
	@echo "Netbox stopped"

netbox-restart: ## Restart Netbox containers
	@echo "Restarting Netbox..."
	@docker compose restart
	@echo "Netbox restarted"

netbox-logs: ## Show Netbox logs (follow mode)
	@docker compose logs -f

netbox-status: ## Show Netbox container status
	@docker compose ps

netbox-shell: ## Open a shell in the Netbox container
	@docker compose exec netbox /bin/bash

netbox-create-superuser: ## Create a Netbox superuser
	@echo "Creating Netbox superuser..."
	@docker compose exec netbox python /opt/netbox/netbox/manage.py createsuperuser

netbox-backup: ## Backup Netbox database
	@echo "Backing up Netbox database..."
	@mkdir -p ../backups
	@docker compose exec -T postgres pg_dump -U netbox netbox > ../backups/netbox-backup-$$(date +%Y%m%d-%H%M%S).sql
	@echo "Backup completed in ../backups/"

netbox-restore: ## Restore Netbox database from backup (usage: make netbox-restore BACKUP_FILE=path/to/backup.sql)
	@if [ -z "$(BACKUP_FILE)" ]; then \
		echo "Error: BACKUP_FILE not specified"; \
		echo "Usage: make netbox-restore BACKUP_FILE=../backups/netbox-backup-YYYYMMDD-HHMMSS.sql"; \
		exit 1; \
	fi
	@echo "Restoring Netbox database from $(BACKUP_FILE)..."
	@cat $(BACKUP_FILE) | docker compose exec -T postgres psql -U netbox netbox
	@echo "Restore completed"

netbox-migrate: ## Run database migrations
	@echo "Running database migrations..."
	@docker compose exec netbox python /opt/netbox/netbox/manage.py migrate
	@echo "Migrations completed"

netbox-collectstatic: ## Collect static files
	@echo "Collecting static files..."
	@docker compose exec netbox python /opt/netbox/netbox/manage.py collectstatic --no-input
	@echo "Static files collected"

netbox-clearcache: ## Clear Netbox cache
	@echo "Clearing cache..."
	@docker compose exec netbox python /opt/netbox/netbox/manage.py clearcache
	@echo "Cache cleared"

netbox-setup-site: ## Automated initial Netbox site setup (run after creating API token)
	@echo "Running automated Netbox site setup..."
	@if [ -z "$(NETBOX_TOKEN)" ]; then \
		echo "Error: NETBOX_TOKEN not set"; \
		echo "Usage: make netbox-setup-site NETBOX_TOKEN=your-api-token"; \
		echo ""; \
		echo "To get your API token:"; \
		echo "1. Login to Netbox at http://localhost:8000"; \
		echo "2. Go to your profile -> API Tokens"; \
		echo "3. Create a new token"; \
		echo "4. Run: make netbox-setup-site NETBOX_TOKEN=<your-token>"; \
		exit 1; \
	fi
	@python3 ../scripts/setup-netbox-site.py $(NETBOX_TOKEN)

netbox-update: ## Update Netbox to latest version
	@echo "Updating Netbox..."
	@docker compose pull
	@docker compose up -d
	@echo "Running migrations..."
	@docker compose exec netbox python /opt/netbox/netbox/manage.py migrate
	@echo "Collecting static files..."
	@docker compose exec netbox python /opt/netbox/netbox/manage.py collectstatic --no-input
	@echo "Update completed"
