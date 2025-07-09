# DevSecOps Ansible Automation

This directory contains Ansible playbooks and configurations to automate the deployment of a comprehensive DevSecOps environment on Linux systems. It converts the functionality from `setup.sh` into declarative Ansible automation.

## 🎯 Overview

The Ansible automation provides:
- **Kubernetes DevSecOps Environment**: Complete setup with MicroK8s
- **CI/CD Pipeline**: Jenkins with custom DevSecOps image
- **Code Quality**: SonarQube with PostgreSQL backend
- **Monitoring Stack**: Grafana, Loki, and Alloy for observability
- **Application Deployment**: Flask application with security scanning
- **External Access**: Azure-ready LoadBalancer and Ingress configurations

## 📁 Directory Structure

```
ansible/
├── README.md                    # This file
├── ansible.cfg                  # Ansible configuration
├── inventory/
│   ├── hosts.yml               # Inventory file
│   └── group_vars/
│       ├── all.yml             # Global variables
│       └── devsecops.yml       # DevSecOps specific variables
├── playbooks/
│   ├── site.yml                # Main playbook
│   ├── prerequisites.yml       # Prerequisites installation
│   ├── docker.yml              # Docker installation
│   ├── microk8s.yml             # MicroK8s setup
│   ├── jenkins.yml              # Jenkins deployment
│   ├── sonarqube.yml            # SonarQube deployment
│   ├── monitoring.yml           # Monitoring stack
│   ├── application.yml          # Flask app deployment
│   ├── azure-access.yml         # Azure external access
│   └── cleanup.yml              # Cleanup operations
├── roles/
│   ├── common/                  # Common tasks
│   ├── docker/                  # Docker installation role
│   ├── microk8s/                # MicroK8s setup role
│   ├── jenkins/                 # Jenkins deployment role
│   ├── sonarqube/               # SonarQube deployment role
│   ├── monitoring/              # Monitoring stack role
│   ├── flask-app/               # Flask application role
│   └── azure-access/            # Azure access configuration role
├── templates/
│   ├── k8s/                     # Kubernetes manifest templates
│   ├── helm/                    # Helm values templates
│   └── configs/                 # Configuration file templates
├── files/
│   ├── jenkins/                 # Jenkins related files
│   └── scripts/                 # Utility scripts
└── docs/
    ├── installation.md          # Installation guide
    ├── configuration.md         # Configuration guide
    ├── troubleshooting.md       # Troubleshooting guide
    └── examples.md              # Usage examples
```

## 🚀 Quick Start

### 1. Prerequisites

- **Ansible Control Node**: Linux/macOS with Ansible 2.12+
- **Target Server**: Ubuntu 20.04+ or CentOS 8+
- **Network Access**: Internet connectivity for package downloads
- **Resources**: Minimum 4GB RAM, 2 CPU cores, 50GB disk space

### 2. Installation

```bash
# Clone the repository
cd ansible/

# Install Ansible (if not already installed)
pip3 install ansible

# Verify installation
ansible --version
```

### 3. Configuration

```bash
# Edit inventory file
vi inventory/hosts.yml

# Edit variables
vi inventory/group_vars/all.yml
vi inventory/group_vars/devsecops.yml
```

### 4. Run Full Deployment

```bash
# Run the complete deployment
ansible-playbook -i inventory/hosts.yml playbooks/site.yml

# Or run with verbose output
ansible-playbook -i inventory/hosts.yml playbooks/site.yml -v
```

## 📋 Available Playbooks

### Core Playbooks

- **`site.yml`**: Complete DevSecOps environment deployment
- **`prerequisites.yml`**: Install system prerequisites
- **`docker.yml`**: Install and configure Docker
- **`microk8s.yml`**: Setup MicroK8s Kubernetes cluster

### Service Playbooks

- **`jenkins.yml`**: Deploy Jenkins with custom DevSecOps image
- **`sonarqube.yml`**: Deploy SonarQube with PostgreSQL
- **`monitoring.yml`**: Deploy Grafana, Loki, and Alloy
- **`application.yml`**: Deploy Flask application

### Utility Playbooks

- **`azure-access.yml`**: Configure external access for Azure
- **`cleanup.yml`**: Clean up deployed resources

## 🎛️ Playbook Execution Examples

### Individual Components

```bash
# Install prerequisites only
ansible-playbook -i inventory/hosts.yml playbooks/prerequisites.yml

# Setup Docker only
ansible-playbook -i inventory/hosts.yml playbooks/docker.yml

# Deploy monitoring stack only
ansible-playbook -i inventory/hosts.yml playbooks/monitoring.yml

# Configure Azure external access
ansible-playbook -i inventory/hosts.yml playbooks/azure-access.yml
```

### Production Deployment

```bash
# Full production deployment
ansible-playbook -i inventory/hosts.yml playbooks/site.yml --tags production

# Development deployment (Docker Compose)
ansible-playbook -i inventory/hosts.yml playbooks/site.yml --tags development
```

### Cleanup Operations

```bash
# Clean specific components
ansible-playbook -i inventory/hosts.yml playbooks/cleanup.yml --tags jenkins
ansible-playbook -i inventory/hosts.yml playbooks/cleanup.yml --tags monitoring
ansible-playbook -i inventory/hosts.yml playbooks/cleanup.yml --tags application

# Complete cleanup
ansible-playbook -i inventory/hosts.yml playbooks/cleanup.yml --tags all
```

## 🔧 Configuration Variables

Key variables in `inventory/group_vars/all.yml`:

```yaml
# Infrastructure
external_ip: "auto"              # Auto-detect or specify IP
domain_suffix: "local"           # Domain suffix for services

# Security
jenkins_admin_password: "admin123"
sonarqube_admin_password: "admin"
grafana_admin_password: "admin123"

# Resource limits
microk8s_storage_size: "20Gi"
postgres_storage_size: "8Gi"
jenkins_storage_size: "8Gi"
```

## 🌐 Service Access

After deployment, services are accessible at:

### Local Access (with /etc/hosts entries)
- **Jenkins**: http://jenkins.local
- **SonarQube**: http://sonarqube.local  
- **Grafana**: http://grafana.local
- **Flask App**: http://flask-app.local

### External Access (Azure/Cloud)
- **Jenkins**: http://jenkins.{EXTERNAL_IP}.nip.io
- **SonarQube**: http://sonarqube.{EXTERNAL_IP}.nip.io
- **Grafana**: http://grafana.{EXTERNAL_IP}.nip.io
- **Flask App**: http://app.{EXTERNAL_IP}.nip.io

## 🔐 Default Credentials

- **Jenkins**: admin / (generated password)
- **SonarQube**: admin / admin
- **Grafana**: admin / admin123

## 📊 Monitoring and Observability

The deployment includes:
- **Loki**: Log aggregation
- **Grafana**: Dashboards and visualization
- **Alloy**: Log collection agent
- **Prometheus metrics**: From Flask application

## 🛠️ CI/CD Pipeline

1. **Code Quality**: SonarQube integration
2. **Security Scanning**: Trivy for container vulnerabilities
3. **Container Building**: Kaniko for secure image builds
4. **Deployment**: Automated Kubernetes deployments
5. **Monitoring**: Integrated observability stack

## 📚 Documentation

- [Installation Guide](docs/installation.md)
- [Configuration Guide](docs/configuration.md)
- [Troubleshooting Guide](docs/troubleshooting.md)
- [Usage Examples](docs/examples.md)

## 🆘 Support

For issues and troubleshooting:
1. Check the [troubleshooting guide](docs/troubleshooting.md)
2. Review Ansible logs: `ansible-playbook ... -vvv`
3. Check service status: `microk8s kubectl get pods -A`

## 🤝 Contributing

1. Follow Ansible best practices
2. Test changes in development environment
3. Update documentation
4. Submit pull requests

## 📄 License

This project is licensed under the MIT License.
