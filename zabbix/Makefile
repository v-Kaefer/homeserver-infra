# Zabbix Management Makefile
# 
# This Makefile provides commands for managing the Zabbix monitoring instance
# Can be used from the main Makefile or directly from the zabbix directory

.PHONY: help zabbix-up zabbix-down zabbix-restart zabbix-logs zabbix-status zabbix-backup zabbix-restore zabbix-shell

help: ## Show this help message
	@echo "Zabbix Management Commands"
	@echo ""
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-25s %s\n", $$1, $$2}'

zabbix-up: ## Start Zabbix containers
	@echo "Starting Zabbix..."
	@docker compose up -d
	@echo "Zabbix is starting. Access the web interface at http://localhost:8080"
	@echo "Default credentials: Admin / zabbix"
	@echo "Run 'make zabbix-logs' to view logs"

zabbix-down: ## Stop Zabbix containers
	@echo "Stopping Zabbix..."
	@docker compose down
	@echo "Zabbix stopped"

zabbix-restart: ## Restart Zabbix containers
	@echo "Restarting Zabbix..."
	@docker compose restart
	@echo "Zabbix restarted"

zabbix-logs: ## Show Zabbix logs (follow mode)
	@docker compose logs -f

zabbix-status: ## Show Zabbix container status
	@docker compose ps

zabbix-shell: ## Open a shell in the Zabbix server container
	@docker compose exec zabbix-server /bin/bash

zabbix-backup: ## Backup Zabbix database
	@echo "Backing up Zabbix database..."
	@mkdir -p ../backups
	@docker compose exec -T zabbix-postgres pg_dump -U zabbix zabbix > ../backups/zabbix-backup-$$(date +%Y%m%d-%H%M%S).sql
	@echo "Backup completed in ../backups/"

zabbix-restore: ## Restore Zabbix database from backup (usage: make zabbix-restore BACKUP_FILE=path/to/backup.sql)
	@if [ -z "$(BACKUP_FILE)" ]; then \
		echo "Error: BACKUP_FILE not specified"; \
		echo "Usage: make zabbix-restore BACKUP_FILE=../backups/zabbix-backup-YYYYMMDD-HHMMSS.sql"; \
		exit 1; \
	fi
	@echo "Restoring Zabbix database from $(BACKUP_FILE)..."
	@cat $(BACKUP_FILE) | docker compose exec -T zabbix-postgres psql -U zabbix zabbix
	@echo "Restore completed"

zabbix-update: ## Update Zabbix to latest version
	@echo "Updating Zabbix..."
	@docker compose pull
	@docker compose up -d
	@echo "Update completed"
