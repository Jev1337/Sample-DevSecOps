# Quick Start Guide

Get the DevSecOps environment up and running in minutes!

## 🚀 Prerequisites

- Ubuntu 20.04+ server with 4GB+ RAM
- SSH access to the server
- Ansible installed on your control machine

## ⚡ Quick Setup

### 1. Install Ansible (Control Machine)

```bash
# Ubuntu/Debian
sudo apt update && sudo apt install -y python3-pip
pip3 install ansible

# Install required collections
ansible-galaxy collection install kubernetes.core community.docker
```

### 2. Configure Target Server

```bash
# Edit inventory file
cd ansible/
cp inventory/hosts.yml.example inventory/hosts.yml
nano inventory/hosts.yml
```

Update with your server details:
```yaml
---
all:
  children:
    devsecops:
      hosts:
        devsecops-server:
          ansible_host: YOUR_SERVER_IP     # Replace with actual IP
          ansible_user: ubuntu             # Replace with your SSH user
```

### 3. Test Connection

```bash
# Test SSH connectivity
ansible -i inventory/hosts.yml devsecops -m ping
```

Expected output: `devsecops-server | SUCCESS => { ... "ping": "pong" }`

### 4. Deploy Everything

```bash
# Full deployment (60-120 minutes)
ansible-playbook -i inventory/hosts.yml playbooks/site.yml
```

### 5. Access Services

Add to your local `/etc/hosts` file:
```
YOUR_SERVER_IP jenkins.local
YOUR_SERVER_IP sonarqube.local
YOUR_SERVER_IP grafana.local
YOUR_SERVER_IP flask-app.local
```

Then access:
- **Jenkins**: http://jenkins.local (admin/check-logs-for-password)
- **SonarQube**: http://sonarqube.local (admin/admin)
- **Grafana**: http://grafana.local (admin/admin123)
- **Flask App**: http://flask-app.local

## 🎯 Quick Commands

```bash
# Deploy specific components
ansible-playbook -i inventory/hosts.yml playbooks/jenkins.yml
ansible-playbook -i inventory/hosts.yml playbooks/monitoring.yml

# Check status
ansible -i inventory/hosts.yml devsecops -a "microk8s kubectl get pods -A"

# Configure external access
ansible-playbook -i inventory/hosts.yml playbooks/azure-access.yml

# Cleanup everything
ansible-playbook -i inventory/hosts.yml playbooks/cleanup.yml --tags all
```

## 🆘 Quick Troubleshooting

**Connection Failed?**
```bash
# Test SSH manually
ssh ubuntu@YOUR_SERVER_IP

# Check SSH keys
ssh-copy-id ubuntu@YOUR_SERVER_IP
```

**Deployment Failed?**
```bash
# Run with verbose output
ansible-playbook -i inventory/hosts.yml playbooks/site.yml -vvv

# Check system resources
ansible -i inventory/hosts.yml devsecops -a "free -h && df -h"
```

**Services Not Starting?**
```bash
# Check pod status
ansible -i inventory/hosts.yml devsecops -a "microk8s kubectl get pods -A"

# Check logs
ansible -i inventory/hosts.yml devsecops -a "microk8s kubectl logs -n jenkins <pod-name>"
```

## 📚 Next Steps

1. Change default passwords
2. Configure CI/CD pipelines in Jenkins
3. Set up projects in SonarQube
4. Import Grafana dashboards
5. Review [Full Documentation](README.md)

---

**Need Help?** Check the [troubleshooting guide](docs/troubleshooting.md) or [examples](docs/examples.md).
