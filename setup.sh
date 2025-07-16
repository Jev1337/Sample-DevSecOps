#!/bin/bash

set -e

echo "🚀 DevSecOps Environment Setup Script"
echo "======================================"
echo "| Comprehensive Kubernetes DevSecOps |"
echo "| Deployment with Monitoring & CI/CD |"
echo "======================================"

# Global variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/tmp/devsecops-setup.log"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${2:-$NC}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}" | tee -a "$LOG_FILE"
}

# Function to check if a command exists
check_command() {
    if ! command -v $1 &> /dev/null; then
        return 1
    fi
    return 0
}

# Function to install Ansible if not present
install_ansible() {
    if check_command ansible-playbook; then
        log "✅ Ansible is already installed." "$GREEN"
        return 0
    fi
    
    log "📦 Installing Ansible..." "$BLUE"
    sudo apt-get update
    sudo apt-get install -y software-properties-common
    sudo add-apt-repository --yes --update ppa:ansible/ansible
    sudo apt-get install -y ansible
    
    if check_command ansible-playbook; then
        log "✅ Ansible installed successfully." "$GREEN"
    else
        log "❌ Failed to install Ansible." "$RED"
        return 1
    fi
}

# Function to check prerequisites
check_prerequisites() {
    log "📝 Checking prerequisites..." "$BLUE"
    
    local missing_tools=()
    
    if ! check_command snap; then
        missing_tools+=("snap")
    fi
    
    if ! check_command git; then
        missing_tools+=("git")
    fi
    
    if ! check_command docker; then
        log "⚠️  Docker not found. Will be installed via Ansible." "$YELLOW"
    fi
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        log "❌ Missing required tools: ${missing_tools[*]}" "$RED"
        log "Please install missing tools and re-run the script." "$RED"
        exit 1
    fi
    
    log "✅ Prerequisites check completed." "$GREEN"
}

# Function to run Ansible playbook with error handling
run_ansible_playbook() {
    local playbook=$1
    local description=$2
    local tags=${3:-""}
    local become_flag="" # Variable to hold the --ask-become flag

    log "🎭 Running Ansible playbook: $description..." "$BLUE"

    cd "$SCRIPT_DIR/ansible"

    # Check for passwordless sudo on the remote host(s)
    log "INFO: Checking for passwordless sudo access..." "$YELLOW"
    if ansible all -i inventory -m raw -a "sudo -n true" &>/dev/null; then
        log "INFO: Passwordless sudo detected. Proceeding without --ask-become." "$CYAN"
    else
        log "INFO: Passwordless sudo not available or requires a password." "$CYAN"
        become_flag="--ask-become"
    fi

    local cmd="ansible-playbook -i inventory $playbook $become_flag"
    if [ -n "$tags" ]; then
        cmd="$cmd --tags=$tags"
    fi

    if $cmd; then
        log "✅ $description completed successfully." "$GREEN"
        cd "$SCRIPT_DIR"
        return 0
    else
        log "❌ $description failed." "$RED"
        cd "$SCRIPT_DIR"
        return 1
    fi
}

# Function to deploy full production environment
deploy_full_production() {
    log "🚀 Starting Full Production Deployment..." "$PURPLE"
    
    # Ensure Ansible is available
    install_ansible
    
    # Run all playbooks in sequence
    run_ansible_playbook "main.yml" "Complete DevSecOps Environment" || {
        log "❌ Production deployment failed. Check logs for details." "$RED"
        return 1
    }
    
    # Deploy SIEM stack
    run_ansible_playbook "siem.yml" "SIEM Security Monitoring" || {
        log "⚠️  SIEM deployment failed, but core environment is ready." "$YELLOW"
    }
    
    show_access_info
    log "✅ Full production deployment completed!" "$GREEN"
}

# Function to deploy individual components
deploy_component() {
    local component=$1
    
    case $component in
        "prerequisites")
            run_ansible_playbook "main.yml" "Prerequisites Setup" "prerequisites"
            ;;
        "docker")
            run_ansible_playbook "main.yml" "Docker Installation" "docker"
            ;;
        "microk8s")
            run_ansible_playbook "main.yml" "MicroK8s Setup" "microk8s"
            ;;
        "core")
            run_ansible_playbook "main.yml" "Core Services (Jenkins, SonarQube)" "core_services"
            ;;
        "monitoring")
            run_ansible_playbook "main.yml" "Monitoring Stack" "monitoring"
            ;;
        "app")
            run_ansible_playbook "main.yml" "Flask Application" "flask_app"
            ;;
        "siem")
            run_ansible_playbook "siem.yml" "SIEM Security Monitoring"
            ;;
        "azure")
            run_ansible_playbook "main.yml" "Azure External Access" "azure_access"
            ;;
        *)
            log "❌ Unknown component: $component" "$RED"
            return 1
            ;;
    esac
}

# Function to run development mode
run_development_mode() {
    log "🧪 Starting Development Mode..." "$BLUE"
    
    if ! check_command docker-compose && ! docker compose version &>/dev/null; then
        log "❌ Docker Compose not found. Installing Docker first..." "$RED"
        deploy_component "docker"
    fi
    
    log "Starting development environment with Docker Compose..." "$YELLOW"
    docker compose up -d
    
    log "⏳ Waiting for services to start..." "$YELLOW"
    sleep 10
    
    log "✅ Development environment started!" "$GREEN"
    log "🔗 Development Access URLs:" "$CYAN"
    log "   - Flask App: http://localhost:5000" "$CYAN"
    log "   - SonarQube: http://localhost:9000" "$CYAN"
    log "   - Grafana:   http://localhost:3000" "$CYAN"
    log "   - Loki:      http://localhost:3100" "$CYAN"
}

# Function to run cleanup
run_cleanup() {
    log "🧹 Running Cleanup..." "$BLUE"
    
    while true; do
        echo ""
        log "Select cleanup action:" "$YELLOW"
        echo "  1) Cleanup Core Services (Jenkins, SonarQube)"
        echo "  2) Cleanup Monitoring Stack"
        echo "  3) Cleanup Application Deployment"
        echo "  4) Cleanup SIEM Stack"
        echo "  5) Cleanup Development Environment (Docker Compose)"
        echo "  6) Cleanup Azure External Access"
        echo "  7) Cleanup ALL"
        echo "  8) Return to main menu"
        read -p "Enter your choice [1-8]: " cleanup_choice
        
        case $cleanup_choice in
            1)
                run_ansible_playbook "cleanup.yml" "Core Services Cleanup" "core_services"
                ;;
            2)
                run_ansible_playbook "cleanup.yml" "Monitoring Stack Cleanup" "monitoring"
                ;;
            3)
                run_ansible_playbook "cleanup.yml" "Application Cleanup" "flask_app"
                ;;
            4)
                run_ansible_playbook "cleanup.yml" "SIEM Stack Cleanup" "siem"
                ;;
            5)
                log "Stopping Docker Compose services..." "$YELLOW"
                docker compose down -v
                log "✅ Development environment cleanup complete." "$GREEN"
                ;;
            6)
                run_ansible_playbook "cleanup.yml" "Azure External Access Cleanup" "azure_access"
                ;;
            7)
                run_ansible_playbook "cleanup.yml" "Complete Environment Cleanup"
                docker compose down -v || true
                log "✅ Full cleanup completed!" "$GREEN"
                ;;
            8)
                return 0
                ;;
            *)
                log "Invalid option. Please try again." "$RED"
                ;;
        esac
    done
}

# Function to display access information
show_access_info() {
    log "🔗 Service Access Information" "$CYAN"
    log "=============================" "$CYAN"
    
    # Get external IP
    EXTERNAL_IP=$(curl -s ifconfig.me || curl -s ipinfo.io/ip || curl -s icanhazip.com || echo "Unable to detect")
    
    # Get Jenkins password if available
    JENKINS_PASS="admin123"
    if command -v microk8s &> /dev/null; then
        JENKINS_PASS=$(microk8s kubectl get secret jenkins -n jenkins -o jsonpath="{.data.jenkins-admin-password}" 2>/dev/null | base64 --decode || echo "admin123")
    fi
    
    echo ""
    log "🌐 External Access URLs (nip.io domains):" "$YELLOW"
    log "   - Jenkins:   http://jenkins.$EXTERNAL_IP.nip.io" "$CYAN"
    log "   - SonarQube: http://sonarqube.$EXTERNAL_IP.nip.io" "$CYAN"
    log "   - Grafana:   http://grafana.$EXTERNAL_IP.nip.io" "$CYAN"
    log "   - Flask App: http://app.$EXTERNAL_IP.nip.io" "$CYAN"
    log "   - Webhook:   http://webhook.$EXTERNAL_IP.nip.io/webhook" "$CYAN"
    echo ""
    
    log "🔑 Default Credentials:" "$YELLOW"
    log "   - Jenkins:   admin / $JENKINS_PASS" "$CYAN"
    log "   - SonarQube: admin / admin" "$CYAN"
    log "   - Grafana:   admin / admin123" "$CYAN"
    echo ""
    
    log "🛡️  SIEM Access:" "$YELLOW"
    log "   - Security Dashboard: Grafana → 'SIEM - Security Monitoring'" "$CYAN"
    log "   - LogQL Examples available in documentation" "$CYAN"
    echo ""
    
    log "📝 Add to /etc/hosts for local access:" "$YELLOW"
    echo "127.0.0.1 jenkins.local sonarqube.local grafana.local flask-app.local webhook.local"
}

# Function to show system status
show_status() {
    log "📊 System Status" "$CYAN"
    log "================" "$CYAN"
    
    # Check if tools are installed
    log "🔧 Tools Status:" "$YELLOW"
    check_command docker && log "   ✅ Docker: Installed" "$GREEN" || log "   ❌ Docker: Not installed" "$RED"
    check_command microk8s && log "   ✅ MicroK8s: Installed" "$GREEN" || log "   ❌ MicroK8s: Not installed" "$RED"
    check_command ansible-playbook && log "   ✅ Ansible: Installed" "$GREEN" || log "   ❌ Ansible: Not installed" "$RED"
    
    # Check if MicroK8s is running
    if check_command microk8s; then
        log "☸️  Kubernetes Status:" "$YELLOW"
        if microk8s status --wait-ready --timeout 5 &>/dev/null; then
            log "   ✅ MicroK8s: Running" "$GREEN"
            
            # Check deployments
            log "📦 Deployments:" "$YELLOW"
            microk8s kubectl get deployments -A --no-headers 2>/dev/null | while read ns name ready uptodate available age; do
                if [[ "$ready" == *"/"* ]]; then
                    current=$(echo $ready | cut -d'/' -f1)
                    desired=$(echo $ready | cut -d'/' -f2)
                    if [ "$current" == "$desired" ] && [ "$current" != "0" ]; then
                        log "   ✅ $ns/$name: Ready ($ready)" "$GREEN"
                    else
                        log "   ⚠️  $ns/$name: Not ready ($ready)" "$YELLOW"
                    fi
                fi
            done
        else
            log "   ❌ MicroK8s: Not running" "$RED"
        fi
    fi
    
    # Check Docker Compose services
    if docker compose ps &>/dev/null; then
        log "🐳 Docker Compose Services:" "$YELLOW"
        docker compose ps --format "table {{.Service}}\t{{.Status}}" | tail -n +2 | while read service status; do
            if [[ "$status" == *"Up"* ]]; then
                log "   ✅ $service: $status" "$GREEN"
            else
                log "   ❌ $service: $status" "$RED"
            fi
        done
    fi
}

# Main menu function
show_main_menu() {
    while true; do
        echo ""
        log "🚀 DevSecOps Setup Menu" "$PURPLE"
        log "======================" "$PURPLE"
        echo "  1) Check Prerequisites"
        echo "  2) Install Ansible (if needed)"
        echo "  3) Deploy Individual Components"
        echo "  4) Deploy Full Production Environment"
        echo "  5) Deploy SIEM Security Monitoring"
        echo "  6) Development Mode (Docker Compose)"
        echo "  7) Show System Status"
        echo "  8) Show Access Information"
        echo "  9) Cleanup Options"
        echo " 10) Exit"
        echo ""
        read -p "Enter your choice [1-10]: " choice
        
        case $choice in
            1)
                check_prerequisites
                ;;
            2)
                install_ansible
                ;;
            3)
                show_component_menu
                ;;
            4)
                deploy_full_production
                ;;
            5)
                install_ansible
                deploy_component "siem"
                ;;
            6)
                run_development_mode
                ;;
            7)
                show_status
                ;;
            8)
                show_access_info
                ;;
            9)
                run_cleanup
                ;;
            10)
                log "👋 Exiting DevSecOps Setup. Goodbye!" "$GREEN"
                exit 0
                ;;
            *)
                log "❌ Invalid option. Please try again." "$RED"
                ;;
        esac
    done
}

# Component selection submenu
show_component_menu() {
    while true; do
        echo ""
        log "🧩 Component Deployment Menu" "$BLUE"
        log "============================" "$BLUE"
        echo "  1) Prerequisites & Docker"
        echo "  2) MicroK8s Setup"
        echo "  3) Core Services (Jenkins, SonarQube)"
        echo "  4) Monitoring Stack (Loki, Grafana)"
        echo "  5) Flask Application"
        echo "  6) SIEM Security Monitoring"
        echo "  7) Azure External Access"
        echo "  8) Return to main menu"
        echo ""
        read -p "Enter your choice [1-8]: " comp_choice
        
        case $comp_choice in
            1)
                install_ansible
                deploy_component "prerequisites"
                deploy_component "docker"
                ;;
            2)
                install_ansible
                deploy_component "microk8s"
                ;;
            3)
                install_ansible
                deploy_component "core"
                ;;
            4)
                install_ansible
                deploy_component "monitoring"
                ;;
            5)
                install_ansible
                deploy_component "app"
                ;;
            6)
                install_ansible
                deploy_component "siem"
                ;;
            7)
                install_ansible
                deploy_component "azure"
                ;;
            8)
                return 0
                ;;
            *)
                log "❌ Invalid option. Please try again." "$RED"
                ;;
        esac
    done
}

# Start the script
log "🎬 Starting DevSecOps Setup Script..." "$PURPLE"
log "Log file: $LOG_FILE" "$CYAN"

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    log "⚠️  This script should not be run as root. Please run as a regular user." "$YELLOW"
    log "Some commands will prompt for sudo when needed." "$YELLOW"
fi

# Show main menu
show_main_menu
