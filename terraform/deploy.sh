#!/bin/bash
# =============================================================================
# Terraform Deployment Script for OpenStack 3-Tier Web API
# =============================================================================
# Usage: ./deploy.sh [init|plan|apply|destroy|output]
#
# Prerequisites:
#   - Terraform installed
#   - OpenStack credentials sourced: source ~/duratm-openrc.sh
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
print_header() {
    echo -e "${BLUE}=============================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}=============================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

check_prerequisites() {
    print_header "Checking Prerequisites"

    # Check Terraform
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed. Please install it first."
        exit 1
    fi
    print_success "Terraform is installed: $(terraform version -json | grep -o '"terraform_version":"[^"]*"' | cut -d'"' -f4)"

    # Check OpenStack credentials
    if [ -z "$OS_AUTH_URL" ]; then
        print_warning "OpenStack credentials not sourced."
        echo -e "${YELLOW}Please run: source ~/duratm-openrc.sh${NC}"
        read -p "Would you like to source it now? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            if [ -f ~/duratm-openrc.sh ]; then
                source ~/duratm-openrc.sh
                print_success "OpenStack credentials sourced"
            else
                print_error "File ~/duratm-openrc.sh not found"
                exit 1
            fi
        else
            exit 1
        fi
    else
        print_success "OpenStack credentials configured (Project: ${OS_PROJECT_NAME:-unknown})"
    fi

    # Check for tfvars file
    if [ ! -f "terraform.tfvars" ]; then
        print_warning "terraform.tfvars not found. Using default values."
        echo "You can copy terraform.tfvars.example to terraform.tfvars to customize."
    else
        print_success "terraform.tfvars found"
    fi
}

init() {
    print_header "Initializing Terraform"
    terraform init
    print_success "Terraform initialized successfully"
}

plan() {
    print_header "Planning Infrastructure"
    terraform plan -out=tfplan
    print_success "Plan saved to tfplan"
}

apply() {
    print_header "Applying Infrastructure"

    if [ -f "tfplan" ]; then
        terraform apply tfplan
        rm -f tfplan
    else
        terraform apply
    fi

    print_success "Infrastructure deployed successfully"
    echo ""
    print_header "Deployment Outputs"
    terraform output
}

destroy() {
    print_header "Destroying Infrastructure"
    print_warning "This will destroy all resources created by Terraform!"
    read -p "Are you sure you want to continue? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        terraform destroy
        print_success "Infrastructure destroyed"
    else
        print_warning "Destroy cancelled"
    fi
}

output() {
    print_header "Current Outputs"
    terraform output
}

validate() {
    print_header "Validating Configuration"
    terraform validate
    print_success "Configuration is valid"
}

format() {
    print_header "Formatting Terraform Files"
    terraform fmt
    print_success "Files formatted"
}

show_help() {
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  init      Initialize Terraform (download providers)"
    echo "  validate  Validate Terraform configuration"
    echo "  plan      Create execution plan"
    echo "  apply     Apply the infrastructure changes"
    echo "  destroy   Destroy all infrastructure"
    echo "  output    Show current outputs"
    echo "  format    Format Terraform files"
    echo "  help      Show this help message"
    echo ""
    echo "Quick deployment:"
    echo "  $0 init && $0 plan && $0 apply"
}

# Main
case "${1:-help}" in
    init)
        check_prerequisites
        init
        ;;
    validate)
        validate
        ;;
    plan)
        check_prerequisites
        plan
        ;;
    apply)
        check_prerequisites
        apply
        ;;
    destroy)
        check_prerequisites
        destroy
        ;;
    output)
        output
        ;;
    format)
        format
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        print_error "Unknown command: $1"
        show_help
        exit 1
        ;;
esac

