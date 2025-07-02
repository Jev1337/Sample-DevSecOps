# Installation Guide

This guide covers the complete installation and setup of the DevSecOps environment using Ansible.

## 📋 Prerequisites

### System Requirements

**Target Server (Linux):**
- Ubuntu 20.04+ or CentOS 8+
- Minimum 4GB RAM (8GB recommended)
- Minimum 2 CPU cores (4 cores recommended)
- Minimum 50GB disk space (100GB recommended)
- Internet connectivity

**Ansible Control Node:**
- Linux, macOS, or WSL2 on Windows
- Python 3.8+
- Ansible 2.12+
- SSH access to target servers

### Network Requirements

- SSH access (port 22) to target servers
- Internet access for package downloads
- Outbound HTTPS access for container registries

## 🔧 Installation Steps

### 1. Prepare Control Node

```bash
# Install Python and pip (if not already installed)
sudo apt update
sudo apt install python3 python3-pip python3-venv -y

# Create virtual environment (recommended)
python3 -m venv ~/ansible-env
source ~/ansible-env/bin/activate

# Install Ansible
pip install ansible

# Install additional collections
ansible-galaxy collection install kubernetes.core
ansible-galaxy collection install community.docker
```

### 2. Prepare SSH Access

```bash
# Generate SSH key pair (if not exists)
ssh-keygen -t rsa -b 4096 -C "your-email@example.com"

# Copy public key to target servers
ssh-copy-id ubuntu@<target-server-ip>

# Test SSH connection
ssh ubuntu@<target-server-ip>
```

### 3. Clone and Configure

```bash
# Navigate to ansible directory
cd ansible/

# Copy and edit inventory file
cp inventory/hosts.yml.example inventory/hosts.yml
vi inventory/hosts.yml

# Update the target server IP and SSH user
```

**Example `inventory/hosts.yml`:**
```yaml
---
all:
  children:
    devsecops:
      hosts:
        devsecops-server:
          ansible_host: 192.168.1.100  # Your server IP
          ansible_user: ubuntu         # Your SSH user
          ansible_ssh_private_key_file: ~/.ssh/id_rsa
```

### 4. Configure Variables

```bash
# Edit global variables
vi inventory/group_vars/all.yml

# Key configurations to review:
# - external_ip: "auto" or specific IP
# - domain_suffix: "local" or your domain
# - Passwords and security settings
# - Resource limits
```

**Important Variables to Set:**
```yaml
# Change default passwords
jenkins_admin_password: "your-secure-password"
sonarqube_admin_password: "your-secure-password"
grafana_admin_password: "your-secure-password"

# Set external IP handling
external_ip: "auto"  # or specify IP address

# Configure domain
domain_suffix: "local"  # or your domain
```

### 5. Test Connectivity

```bash
# Test Ansible connectivity
ansible -i inventory/hosts.yml devsecops -m ping

# Expected output:
# devsecops-server | SUCCESS => {
#     "ansible_facts": {
#         "discovered_interpreter_python": "/usr/bin/python3"
#     },
#     "changed": false,
#     "ping": "pong"
# }
```

### 6. Run Deployment

```bash
# Full deployment
ansible-playbook -i inventory/hosts.yml playbooks/site.yml

# Or run step by step
ansible-playbook -i inventory/hosts.yml playbooks/prerequisites.yml
ansible-playbook -i inventory/hosts.yml playbooks/docker.yml
ansible-playbook -i inventory/hosts.yml playbooks/microk8s.yml
ansible-playbook -i inventory/hosts.yml playbooks/jenkins.yml
ansible-playbook -i inventory/hosts.yml playbooks/sonarqube.yml
ansible-playbook -i inventory/hosts.yml playbooks/monitoring.yml
ansible-playbook -i inventory/hosts.yml playbooks/application.yml
ansible-playbook -i inventory/hosts.yml playbooks/azure-access.yml
```

## 🕒 Deployment Timeline

Expected deployment times:
- **Prerequisites:** 5-10 minutes
- **Docker:** 5-10 minutes
- **MicroK8s:** 10-15 minutes
- **Jenkins:** 10-15 minutes
- **SonarQube:** 10-15 minutes
- **Monitoring:** 10-15 minutes
- **Application:** 5-10 minutes
- **External Access:** 2-5 minutes

**Total: 60-120 minutes** (depending on network speed and server performance)

## ✅ Verification

### 1. Check Services Status

```bash
# Check all pods
ansible -i inventory/hosts.yml devsecops -a "microk8s kubectl get pods -A"

# Check services
ansible -i inventory/hosts.yml devsecops -a "microk8s kubectl get svc -A"

# Check ingress
ansible -i inventory/hosts.yml devsecops -a "microk8s kubectl get ingress -A"
```

### 2. Access Services

Add to your `/etc/hosts` file (on your local machine):
```
<target-server-ip> jenkins.local
<target-server-ip> sonarqube.local
<target-server-ip> grafana.local
<target-server-ip> flask-app.local
```

Then access:
- Jenkins: http://jenkins.local
- SonarQube: http://sonarqube.local
- Grafana: http://grafana.local
- Flask App: http://flask-app.local

### 3. Check Logs

```bash
# View deployment logs on target server
ansible -i inventory/hosts.yml devsecops -a "tail -f /var/log/devsecops/deployment.log"

# Check specific service logs
ansible -i inventory/hosts.yml devsecops -a "microk8s kubectl logs -n jenkins -l app.kubernetes.io/instance=jenkins"
```

## 🔧 Post-Installation

### 1. Security Configuration

- Change all default passwords
- Configure firewall rules
- Set up SSL certificates
- Enable authentication

### 2. Jenkins Configuration

- Access Jenkins web interface
- Install additional plugins if needed
- Configure Git repositories
- Set up build pipelines

### 3. SonarQube Configuration

- Access SonarQube web interface
- Create projects
- Configure quality gates
- Set up authentication

### 4. Grafana Configuration

- Access Grafana web interface
- Verify Loki datasource
- Import dashboards
- Configure alerts

## 🆘 Troubleshooting

### Common Issues

**SSH Connection Failed:**
```bash
# Check SSH connectivity
ssh -v ubuntu@<target-server-ip>

# Verify SSH key permissions
chmod 600 ~/.ssh/id_rsa
chmod 644 ~/.ssh/id_rsa.pub
```

**Ansible Module Not Found:**
```bash
# Install required collections
ansible-galaxy collection install kubernetes.core
ansible-galaxy collection install community.docker
```

**Permission Denied:**
```bash
# Ensure user has sudo privileges
# Add to /etc/sudoers on target server:
ubuntu ALL=(ALL) NOPASSWD:ALL
```

**Pod Not Starting:**
```bash
# Check pod events
ansible -i inventory/hosts.yml devsecops -a "microk8s kubectl describe pod <pod-name> -n <namespace>"

# Check logs
ansible -i inventory/hosts.yml devsecops -a "microk8s kubectl logs <pod-name> -n <namespace>"
```

### Getting Help

1. Check the [troubleshooting guide](troubleshooting.md)
2. Review Ansible logs with `-vvv` flag
3. Check service logs and events
4. Verify network connectivity and firewall rules

## 📚 Next Steps

After successful installation:
1. Review [Configuration Guide](configuration.md)
2. Read [Usage Examples](examples.md)
3. Set up CI/CD pipelines
4. Configure monitoring and alerting
5. Implement security best practices
