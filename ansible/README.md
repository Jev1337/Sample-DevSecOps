# DevSecOps Ansible Playbooks

This directory contains Ansible playbooks and roles for setting up a complete DevSecOps environment on a single MicroK8s node.

## Prerequisites

- Ubuntu 20.04 or later
- Python 3.8 or later
- Ansible 2.15 or later

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

### Full Production Setup
Complete DevSecOps environment with all services:
```bash
ansible-playbook playbooks/main.yml
```

### Development Mode
Docker Compose based development environment:
```bash
ansible-playbook playbooks/development.yml
```

### Partial Deployments
Core services only (Jenkins, SonarQube, PostgreSQL):
```bash
ansible-playbook playbooks/core_services.yml
```

Monitoring stack only (Loki, Grafana, Alloy):
```bash
ansible-playbook playbooks/monitoring.yml
```

Flask application only:
```bash
ansible-playbook playbooks/flask_app.yml
```

### Cleanup
Remove all deployed services:
```bash
ansible-playbook playbooks/cleanup.yml
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
ansible-playbook playbooks/main.yml -e @vars/custom.yml
```

### Inventory
The inventory file defines localhost as the target host. Modify if needed for remote deployments.

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

1. **Group permissions**: Log out and log in again after first install
2. **MicroK8s status**: Check with `microk8s status --wait-ready`
3. **Docker permissions**: Ensure user is in docker group
4. **Logs**: Check `/tmp/ansible.log` for detailed execution logs

## Service Access

After successful deployment:
- Jenkins: `http://jenkins.local` (admin/generated_password)
- SonarQube: `http://sonarqube.local` (admin/admin)
- Grafana: `http://grafana.local` (admin/admin123)
- Flask App: `http://flask-app.local`

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
