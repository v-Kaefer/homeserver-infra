.PHONY: help validate init-terraform start-netbox stop-netbox status clean

help: ## Show this help message
	@echo "Homeserver Infrastructure Management"
	@echo ""
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-20s %s\n", $$1, $$2}'

validate: ## Validate the setup
	@./validate-setup.sh

init-terraform: ## Initialize Terraform
	@echo "Initializing Terraform..."
	@cd terraform/proxmox && terraform init

plan-terraform: ## Plan Terraform changes
	@echo "Planning Terraform changes..."
	@cd terraform/proxmox && terraform plan

apply-terraform: ## Apply Terraform changes
	@echo "Applying Terraform changes..."
	@cd terraform/proxmox && terraform apply

start-netbox: ## Start Netbox containers
	@echo "Starting Netbox..."
	@cd netbox && docker compose up -d
	@echo "Netbox is starting. Access it at http://localhost:8000"

stop-netbox: ## Stop Netbox containers
	@echo "Stopping Netbox..."
	@cd netbox && docker compose down

restart-netbox: ## Restart Netbox containers
	@echo "Restarting Netbox..."
	@cd netbox && docker compose restart

logs-netbox: ## Show Netbox logs
	@cd netbox && docker compose logs -f

status: ## Show status of all services
	@echo "=== Netbox Status ==="
	@cd netbox && docker compose ps 2>/dev/null || echo "Netbox not running"
	@echo ""
	@echo "=== Terraform Status ==="
	@if [ -d terraform/proxmox/.terraform ]; then \
		echo "Terraform initialized ✓"; \
		cd terraform/proxmox && terraform show 2>/dev/null | head -n 5 || echo "No state found"; \
	else \
		echo "Terraform not initialized ✗"; \
	fi

backup-netbox: ## Backup Netbox database
	@echo "Backing up Netbox database..."
	@cd netbox && docker compose exec -T postgres pg_dump -U netbox netbox > ../backups/netbox-backup-$$(date +%Y%m%d-%H%M%S).sql
	@echo "Backup completed"

setup: ## Initial setup (copy example files)
	@echo "Setting up configuration files..."
	@if [ ! -f terraform/proxmox/terraform.tfvars ]; then \
		cp terraform/proxmox/terraform.tfvars.example terraform/proxmox/terraform.tfvars; \
		echo "Created terraform.tfvars - Please edit with your Proxmox credentials"; \
	fi
	@if [ ! -f netbox/env/netbox.env ]; then \
		cp netbox/env/netbox.env.example netbox/env/netbox.env; \
		echo "Created netbox.env - Please edit with your configuration"; \
	fi
	@if [ ! -f netbox/env/postgres.env ]; then \
		cp netbox/env/postgres.env.example netbox/env/postgres.env; \
		echo "Created postgres.env - Please edit with your configuration"; \
	fi
	@mkdir -p backups
	@echo ""
	@echo "Setup complete! Next steps:"
	@echo "1. Edit terraform/proxmox/terraform.tfvars with your Proxmox credentials"
	@echo "2. Edit netbox/env/*.env with your Netbox configuration"
	@echo "3. Run 'make init-terraform' to initialize Terraform"
	@echo "4. Run 'make start-netbox' to start Netbox"

clean: ## Clean up temporary files
	@echo "Cleaning up..."
	@find . -type f -name "*.tfstate.backup" -delete
	@find . -type d -name ".terraform" -exec rm -rf {} + 2>/dev/null || true
	@echo "Clean complete"
