#!/bin/bash

# Validation script for homeserver infrastructure setup
# This script checks if all required components are properly configured

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "================================================"
echo "Homeserver Infrastructure Validation Script"
echo "================================================"
echo ""

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to print status
print_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓${NC} $2"
    else
        echo -e "${RED}✗${NC} $2"
    fi
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Check Terraform
echo "Checking Terraform..."
if command_exists terraform; then
    VERSION=$(terraform version -json 2>/dev/null | grep -o '"terraform_version":"[^"]*"' | cut -d'"' -f4 || terraform version | head -n1 | awk '{print $2}')
    print_status 0 "Terraform is installed (version: $VERSION)"
else
    print_status 1 "Terraform is not installed"
    print_warning "Install from: https://www.terraform.io/downloads"
fi
echo ""

# Check Docker
echo "Checking Docker..."
if command_exists docker; then
    VERSION=$(docker --version | awk '{print $3}' | sed 's/,//')
    print_status 0 "Docker is installed (version: $VERSION)"
    
    # Check if Docker is running
    if docker info >/dev/null 2>&1; then
        print_status 0 "Docker daemon is running"
    else
        print_status 1 "Docker daemon is not running"
    fi
else
    print_status 1 "Docker is not installed"
    print_warning "Install from: https://docs.docker.com/get-docker/"
fi
echo ""

# Check Docker Compose
echo "Checking Docker Compose..."
if command_exists docker && docker compose version >/dev/null 2>&1; then
    VERSION=$(docker compose version | awk '{print $4}')
    print_status 0 "Docker Compose is installed (version: $VERSION)"
elif command_exists docker-compose; then
    VERSION=$(docker-compose --version | awk '{print $4}' | sed 's/,//')
    print_status 0 "Docker Compose is installed (version: $VERSION)"
else
    print_status 1 "Docker Compose is not installed"
fi
echo ""

# Check Terraform configuration
echo "Checking Terraform configuration..."
if [ -f "terraform/proxmox/terraform.tfvars" ]; then
    print_status 0 "terraform.tfvars exists"
else
    print_status 1 "terraform.tfvars not found"
    print_warning "Copy terraform.tfvars.example to terraform.tfvars and configure it"
fi

if [ -d "terraform/proxmox/.terraform" ]; then
    print_status 0 "Terraform has been initialized"
else
    print_status 1 "Terraform not initialized"
    print_warning "Run 'cd terraform/proxmox && terraform init'"
fi
echo ""

# Check Netbox configuration
echo "Checking Netbox configuration..."
if [ -f "netbox/env/netbox.env" ]; then
    print_status 0 "netbox.env exists"
else
    print_status 1 "netbox.env not found"
    print_warning "Copy netbox/env/netbox.env.example to netbox/env/netbox.env and configure it"
fi

if [ -f "netbox/env/postgres.env" ]; then
    print_status 0 "postgres.env exists"
else
    print_status 1 "postgres.env not found"
    print_warning "Copy netbox/env/postgres.env.example to netbox/env/postgres.env and configure it"
fi
echo ""

# Check if Netbox is running
echo "Checking Netbox status..."
if command_exists docker && docker compose version >/dev/null 2>&1; then
    cd netbox 2>/dev/null || true
    if docker compose ps 2>/dev/null | grep -q "netbox"; then
        if docker compose ps 2>/dev/null | grep "netbox" | grep -q "Up"; then
            print_status 0 "Netbox is running"
        else
            print_status 1 "Netbox containers exist but are not running"
            print_warning "Run 'cd netbox && docker compose up -d'"
        fi
    else
        print_status 1 "Netbox is not running"
        print_warning "Run 'cd netbox && docker compose up -d'"
    fi
    cd .. 2>/dev/null || true
else
    print_warning "Cannot check Netbox status (Docker Compose not available)"
fi
echo ""

# Summary
echo "================================================"
echo "Validation Complete"
echo "================================================"
echo ""
echo "Next Steps:"
echo "1. Review any failed checks above"
echo "2. Follow the Getting Started guide: docs/getting-started.md"
echo "3. Configure terraform.tfvars with your Proxmox credentials"
echo "4. Configure Netbox environment files"
echo "5. Start Netbox: cd netbox && docker compose up -d"
echo "6. Initialize Terraform: cd terraform/proxmox && terraform init"
echo ""
