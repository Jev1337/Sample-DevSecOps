# DevSecOps Ansible Playbooks with SIEM

This directory contains Ansible playbooks and roles for setting up a complete DevSecOps environment with **enhanced SIEM (Security Information and Event Management)** capabilities on a single MicroK8s node.

## 🔒 SIEM Features

### Security Event Monitoring
- **SSH Authentication Monitoring**: Failed and successful login attempts
- **Git Webhook Processing**: Repository events with security analysis
- **Kubernetes Audit Logging**: API server security events
- **Container Security Monitoring**: Application-level security events
- **System Log Analysis**: OS-level security events and anomalies

### Security Tools Integrated
- **fail2ban**: SSH brute-force protection with IP banning
- **chkrootkit**: Rootkit detection and scanning
- **rkhunter**: Additional security vulnerability scanning
- **Real-time Monitoring**: Automated security checks every 5 minutes

### SIEM Dashboard
- Comprehensive Grafana dashboard for security event visualization
- Real-time security metrics and alerts
- Log correlation and threat detection
- Webhook event analysis and commit security scanning

## Prerequisites

- Ubuntu 20.04 or later
- Python 3.8 or later
- Ansible 2.15 or later
- sudo privileges for security tool installation

## Installation

1. Install Ansible:
   ```bash
   sudo apt update
   sudo apt install ansible
   ```

2. Install required collections:
   ```bash
   ansible-galaxy collection install -r requirements.yml
   ```

## Playbooks

### Full Production Setup with SIEM
Complete DevSecOps environment with all services and SIEM monitoring:
```bash
ansible-playbook playbooks/main.yml --ask-become-pass
```

### SIEM-Only Deployment
Deploy SIEM capabilities on existing monitoring stack:
```bash
ansible-playbook playbooks/siem.yml --ask-become-pass
```

### Development Mode
Docker Compose based development environment:
```bash
ansible-playbook playbooks/development.yml --ask-become-pass
```

### Partial Deployments
Core services only (Jenkins, SonarQube, PostgreSQL):
```bash
ansible-playbook playbooks/core_services.yml --ask-become-pass
```

Monitoring stack only (Loki, Grafana, Alloy):
```bash
ansible-playbook playbooks/monitoring.yml --ask-become-pass
```

Flask application only:
```bash
ansible-playbook playbooks/flask_app.yml --ask-become-pass
```

### Cleanup
Remove all deployed services:
```bash
ansible-playbook playbooks/cleanup.yml --ask-become-pass
```

## Configuration

### Variables
Default variables are defined in `vars/main.yml`. You can override these by creating your own variables file:

```yaml
# vars/custom.yml
microk8s_channel: "1.30/stable"
docker_gid: 999
flask_app_image: "localhost:32000/flask-k8s-app:latest"
jenkins_image: "localhost:32000/jenkins-devsecops:latest"
```

Then use it with:
```bash
ansible-playbook playbooks/main.yml --ask-become-pass -e @vars/custom.yml
```

### Inventory
The inventory file defines localhost as the target host. Modify if needed for remote deployments.

### Sudo Permissions
All playbooks require sudo permissions for package installation and system configuration. You can either:

1. **Use `--ask-become-pass` flag** (recommended):
   ```bash
   ansible-playbook playbooks/main.yml --ask-become-pass
   ```

2. **Setup passwordless sudo** (for automation):
   ```bash
   sudo visudo
   # Add: your_username ALL=(ALL) NOPASSWD:ALL
   ```

## Roles

- **prerequisites**: Install required packages (snap, git, curl)
- **docker**: Install and configure Docker
- **microk8s**: Install and configure MicroK8s with addons
- **jenkins_image**: Build custom Jenkins image
- **core_services**: Deploy Jenkins, SonarQube, PostgreSQL via Helm
- **monitoring_stack**: Deploy Loki, Grafana, Alloy via Helm
- **flask_app**: Build and deploy Flask application
- **azure_access**: Configure external access (LoadBalancer + Ingress)
- **access_info**: Display service access information
- **development**: Start Docker Compose development environment

## Templates

Jinja2 templates for dynamic K8s resource creation:
- LoadBalancer services for external access
- Ingress resources with nip.io domains

## Security Notes

- Default credentials are used for demo purposes
- Configure proper SSL/TLS certificates for production
- Ensure proper firewall rules for external access
- Review and update security settings before production use

## Troubleshooting

1. **Sudo permissions**: Use `--ask-become-pass` flag or setup passwordless sudo
2. **Package manager locks**: The playbook handles `unattended-upgr` automatically
3. **Group permissions**: Log out and log in again after first install
4. **MicroK8s status**: Check with `microk8s status --wait-ready`
5. **Docker permissions**: Ensure user is in docker group
6. **Logs**: Check `/tmp/ansible.log` for detailed execution logs
7. **Template errors**: Ensure all templates are in `ansible/templates/` directory

### Common Issues

- **"sudo: a password is required"**: Add `--ask-become-pass` flag
- **"Could not get lock /var/lib/dpkg/lock"**: Wait for system updates or run playbook again
- **"Could not find template"**: Templates are referenced from `ansible/templates/`
- **MicroK8s group permissions**: Run `newgrp microk8s` after first install

## Service Access

After successful deployment:
- Jenkins: `http://jenkins.local` (admin/generated_password)
- SonarQube: `http://sonarqube.local` (admin/admin)
- Grafana: `http://grafana.local` (admin/admin123)
- Flask App: `http://flask-app.local`

### External Access (Azure/Cloud)
The playbook also configures external access via:
- LoadBalancer services for direct IP access
- Ingress with nip.io domains (e.g., `jenkins.YOUR_IP.nip.io`)

### Local Access
Add to `/etc/hosts`:
```
127.0.0.1 jenkins.local
127.0.0.1 sonarqube.local
127.0.0.1 grafana.local
127.0.0.1 flask-app.local
```

## CI/CD Pipeline

1. Configure a new 'Pipeline' job in Jenkins
2. Point it to your Git repository
3. Set 'Script Path' to 'jenkins/Jenkinsfile'
