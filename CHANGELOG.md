# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **Infrastructure Analysis & Planning Documentation**:
  - Comprehensive infrastructure analysis (`docs/infrastructure-analysis.md`)
    - Analysis of current stack strengths and weaknesses
    - Identification of redundancies (dual PostgreSQL, monitoring overlap)
    - Improvement recommendations (consolidate DB, unified backups, integration)
    - SquirrelServersManager evaluation (recommendation: keep current stack)
    - Prioritized action items with effort estimates
  - Infrastructure diagram documentation (`docs/infrastructure-diagram.md`)
    - Draw.io AI-compatible descriptions
    - Multi-layer architecture diagrams
    - Network topology visualizations
    - Workflow and data flow diagrams
    - Color scheme and icon guidelines
  - n8n workflow automation integration plan (`docs/n8n-integration-plan.md`)
    - Complete deployment configuration
    - 5 pre-designed workflow templates
    - API integration details for all services
    - Security and monitoring configuration
    - 3-phase implementation roadmap
    - ROI analysis and best practices
- Documentation section restructured with Planning & Architecture subsection

### Recommendations Summary
**High Priority** (Do Now):
  1. Consolidate PostgreSQL instances (reduce resource usage 50%)
  2. Implement unified backup system
  3. Add Terraform-Netbox-Zabbix integration

**Future** (Planned):
  - n8n for workflow orchestration
  - Health checks for all services
  - Infrastructure diagram creation

**Not Recommended**:
  - SquirrelServersManager replacement (current stack more flexible)

### Previous Additions
- **Zabbix monitoring integration**:
  - Docker Compose stack for Zabbix server, web interface, PostgreSQL, and agent
  - Separate Zabbix Makefile (`zabbix/Makefile`) with dedicated commands:
    - `zabbix-up` and `zabbix-down` for service management
    - `zabbix-shell`, `zabbix-logs`, `zabbix-status` for debugging
    - `zabbix-backup` and `zabbix-restore` for data management
    - `zabbix-update` for version upgrades
  - Environment file templates for Zabbix configuration
  - Comprehensive Zabbix setup documentation (`docs/zabbix-setup.md`)
  - Integration guide for monitoring Proxmox and VMs
  - Zabbix README with quick start instructions
- Main Makefile updated with Zabbix commands
- `.gitignore` updated to exclude Zabbix environment files

### Changed
- README.md updated to include Zabbix in technology stack
- Project structure documentation updated to include Zabbix directory
- Setup command now includes Zabbix configuration files
- Status command now shows Zabbix service status

### Previous Changes
- CHANGELOG.md for tracking project changes
- Separate Netbox Makefile (`netbox/Makefile`) with dedicated commands:
  - `netbox-up` and `netbox-down` for service management
  - `netbox-shell`, `netbox-logs`, `netbox-status` for debugging
  - `netbox-backup` and `netbox-restore` for data management
  - `netbox-setup-site` for automated initial configuration
  - `netbox-migrate`, `netbox-collectstatic`, `netbox-clearcache` for maintenance
  - `netbox-update` for version upgrades
- Python automation script (`scripts/setup-netbox-site.py`) for automated Netbox site setup:
  - Creates default site and device roles
  - Sets up IP prefixes for common networks
  - Configures Proxmox cluster type and cluster
  - Supports custom Netbox URL via environment variable
- `requirements.txt` for Python dependencies (pynetbox)
- `scripts/README.md` with documentation for automation scripts

### Changed
- README.md restructured to be more concise and quick-start focused
- Removed verbose "journal-like" content from README
- Main Makefile now delegates Netbox operations to `netbox/Makefile`
- Improved help messages with pointer to Netbox-specific commands

### Technical Details
- Complete Terraform configuration for Proxmox provider
  - API token authentication support
  - Reusable VM module with cloud-init support
  - DHCP and static IP configuration options
  - Example configurations for single and multi-VM deployments
- Netbox Docker Compose deployment
  - PostgreSQL, Redis, worker, and housekeeping services
  - Environment-based configuration templates
  - Volume management for data persistence
- Comprehensive documentation
  - Getting Started Guide with complete walkthrough
  - Proxmox Setup Guide for installation and configuration
  - Terraform Setup Guide with usage examples and best practices
  - Netbox Setup Guide for deployment and API integration
- Automation tools
  - Makefile with common operations (setup, validate, start/stop services, backup)
  - Validation script to verify environment prerequisites
- Security improvements
  - `.gitignore` configured to exclude secrets, state files, and environment configs
  - Separate environment file templates for sensitive data

### Changed
- README restructured for better quick-start experience
- Netbox operations moved to separate Makefile

## [0.1.0] - 2025-11-14

### Added
- Initial repository setup
- Basic README documentation
