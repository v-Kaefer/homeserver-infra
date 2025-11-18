.PHONY: help validate init-terraform plan-terraform apply-terraform status clean setup
.PHONY: netbox-up netbox-down netbox-restart netbox-logs netbox-status netbox-backup netbox-shell netbox-create-superuser
.PHONY: zabbix-up zabbix-down zabbix-restart zabbix-logs zabbix-status zabbix-backup zabbix-shell

help: ## Show this help message
	@echo "Homeserver Infrastructure Management"
	@echo ""
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-20s %s\n", $$1, $$2}'
	@echo ""
	@echo "For more Netbox commands, run: make -C netbox help"
	@echo "For more Zabbix commands, run: make -C zabbix help"

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

# Netbox Management (delegates to netbox/Makefile)
netbox-up: ## Start Netbox containers
	@$(MAKE) -C netbox netbox-up

netbox-down: ## Stop Netbox containers
	@$(MAKE) -C netbox netbox-down

netbox-restart: ## Restart Netbox containers
	@$(MAKE) -C netbox netbox-restart

netbox-logs: ## Show Netbox logs
	@$(MAKE) -C netbox netbox-logs

netbox-status: ## Show Netbox status
	@$(MAKE) -C netbox netbox-status

netbox-backup: ## Backup Netbox database
	@$(MAKE) -C netbox netbox-backup

netbox-shell: ## Open shell in Netbox container
	@$(MAKE) -C netbox netbox-shell

netbox-create-superuser: ## Create Netbox superuser
	@$(MAKE) -C netbox netbox-create-superuser

# Zabbix Management (delegates to zabbix/Makefile)
zabbix-up: ## Start Zabbix containers
	@$(MAKE) -C zabbix zabbix-up

zabbix-down: ## Stop Zabbix containers
	@$(MAKE) -C zabbix zabbix-down

zabbix-restart: ## Restart Zabbix containers
	@$(MAKE) -C zabbix zabbix-restart

zabbix-logs: ## Show Zabbix logs
	@$(MAKE) -C zabbix zabbix-logs

zabbix-status: ## Show Zabbix status
	@$(MAKE) -C zabbix zabbix-status

zabbix-backup: ## Backup Zabbix database
	@$(MAKE) -C zabbix zabbix-backup

zabbix-shell: ## Open shell in Zabbix container
	@$(MAKE) -C zabbix zabbix-shell

status: ## Show status of all services
	@echo "=== Netbox Status ==="
	@$(MAKE) -C netbox netbox-status 2>/dev/null || echo "Netbox not running"
	@echo ""
	@echo "=== Zabbix Status ==="
	@$(MAKE) -C zabbix zabbix-status 2>/dev/null || echo "Zabbix not running"
	@echo ""
	@echo "=== Terraform Status ==="
	@if [ -d terraform/proxmox/.terraform ]; then \
		echo "Terraform initialized ✓"; \
		cd terraform/proxmox && terraform show 2>/dev/null | head -n 5 || echo "No state found"; \
	else \
		echo "Terraform not initialized ✗"; \
	fi

backup-netbox: netbox-backup ## Backup Netbox database (alias)

backup-zabbix: zabbix-backup ## Backup Zabbix database (alias)

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
	@if [ ! -f zabbix/env/zabbix.env ]; then \
		cp zabbix/env/zabbix.env.example zabbix/env/zabbix.env; \
		echo "Created zabbix.env - Please edit with your configuration"; \
	fi
	@if [ ! -f zabbix/env/postgres.env ]; then \
		cp zabbix/env/postgres.env.example zabbix/env/postgres.env; \
		echo "Created zabbix postgres.env - Please edit with your configuration"; \
	fi
	@if [ ! -f zabbix/env/zabbix-agent.env ]; then \
		cp zabbix/env/zabbix-agent.env.example zabbix/env/zabbix-agent.env; \
		echo "Created zabbix-agent.env - Please edit with your configuration"; \
	fi
	@mkdir -p backups
	@echo ""
	@echo "Setup complete! Next steps:"
	@echo "1. Edit terraform/proxmox/terraform.tfvars with your Proxmox credentials"
	@echo "2. Edit netbox/env/*.env with your Netbox configuration"
	@echo "3. Edit zabbix/env/*.env with your Zabbix configuration"
	@echo "4. Run 'make init-terraform' to initialize Terraform"
	@echo "5. Run 'make netbox-up' to start Netbox"
	@echo "6. Run 'make zabbix-up' to start Zabbix"

clean: ## Clean up temporary files
	@echo "Cleaning up..."
	@find . -type f -name "*.tfstate.backup" -delete
	@find . -type d -name ".terraform" -exec rm -rf {} + 2>/dev/null || true
	@echo "Clean complete"
