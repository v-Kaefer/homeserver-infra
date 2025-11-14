# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
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
