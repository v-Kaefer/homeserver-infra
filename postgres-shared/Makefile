# Shared PostgreSQL Makefile
.PHONY: help postgres-up postgres-down postgres-logs postgres-status postgres-backup

help: ## Show this help message
	@echo "Shared PostgreSQL Management"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-20s %s\n", $$1, $$2}'

postgres-up: ## Start shared PostgreSQL
	@docker compose up -d
	@echo "Shared PostgreSQL started on port 5432"

postgres-down: ## Stop shared PostgreSQL
	@docker compose down

postgres-logs: ## View PostgreSQL logs
	@docker compose logs -f

postgres-status: ## Show PostgreSQL status
	@docker compose ps

postgres-backup: ## Backup all databases
	@mkdir -p ../backups
	@docker compose exec -T postgres-shared pg_dumpall -U postgres > ../backups/postgres-all-backup-$$(date +%Y%m%d-%H%M%S).sql
	@echo "Backup completed in ../backups/"
