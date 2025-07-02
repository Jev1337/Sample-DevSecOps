# Usage Examples

This guide provides practical examples for using the DevSecOps Ansible automation.

## 🚀 Basic Usage Examples

### Complete Environment Deployment

Deploy the entire DevSecOps environment:

```bash
# Full production deployment
ansible-playbook -i inventory/hosts.yml playbooks/site.yml

# With verbose output for troubleshooting
ansible-playbook -i inventory/hosts.yml playbooks/site.yml -vv

# Dry run to see what would be changed
ansible-playbook -i inventory/hosts.yml playbooks/site.yml --check
```

### Component-Specific Deployments

Deploy individual components:

```bash
# Install only prerequisites and Docker
ansible-playbook -i inventory/hosts.yml playbooks/site.yml --tags "prerequisites,docker"

# Deploy only Jenkins
ansible-playbook -i inventory/hosts.yml playbooks/jenkins.yml

# Deploy monitoring stack only
ansible-playbook -i inventory/hosts.yml playbooks/monitoring.yml

# Configure external access only
ansible-playbook -i inventory/hosts.yml playbooks/azure-access.yml
```

## 🎯 Environment-Specific Examples

### Development Environment

```bash
# Override variables for development
ansible-playbook -i inventory/hosts.yml playbooks/site.yml \
  -e "environment_type=development" \
  -e "deployment_mode=docker-compose" \
  --tags development

# Use smaller resource limits
ansible-playbook -i inventory/hosts.yml playbooks/site.yml \
  -e "jenkins_storage_size=2Gi" \
  -e "postgresql_storage_size=5Gi"
```

### Production Environment

```bash
# Production deployment with custom passwords
ansible-playbook -i inventory/hosts.yml playbooks/site.yml \
  -e "jenkins_admin_password=SecureJenkinsPass123!" \
  -e "sonarqube_admin_password=SecureSonarPass123!" \
  -e "grafana_admin_password=SecureGrafanaPass123!"

# Production with external IP
ansible-playbook -i inventory/hosts.yml playbooks/site.yml \
  -e "external_ip=203.0.113.10" \
  -e "domain_suffix=company.com"
```

### Multi-Node Setup

For multiple servers, update your inventory:

```yaml
# inventory/hosts.yml
---
all:
  children:
    devsecops:
      hosts:
        jenkins-server:
          ansible_host: 192.168.1.10
          ansible_user: ubuntu
          node_role: jenkins
        sonar-server:
          ansible_host: 192.168.1.11
          ansible_user: ubuntu
          node_role: sonarqube
        monitoring-server:
          ansible_host: 192.168.1.12
          ansible_user: ubuntu
          node_role: monitoring
```

Then deploy components to specific servers:

```bash
# Deploy Jenkins only to jenkins-server
ansible-playbook -i inventory/hosts.yml playbooks/jenkins.yml --limit jenkins-server

# Deploy SonarQube only to sonar-server
ansible-playbook -i inventory/hosts.yml playbooks/sonarqube.yml --limit sonar-server

# Deploy monitoring only to monitoring-server
ansible-playbook -i inventory/hosts.yml playbooks/monitoring.yml --limit monitoring-server
```

## 🔧 Configuration Examples

### Custom Resource Configuration

Create custom resource configuration:

```yaml
# inventory/group_vars/custom.yml
---
resources:
  jenkins:
    requests:
      cpu: "2000m"
      memory: "4Gi"
    limits:
      cpu: "4000m"
      memory: "8Gi"
  
  sonarqube:
    requests:
      cpu: "1000m"
      memory: "2Gi"
    limits:
      cpu: "2000m"
      memory: "4Gi"

storage:
  jenkins_storage_size: "50Gi"
  postgresql_storage_size: "100Gi"
  grafana_storage_size: "10Gi"
```

Deploy with custom configuration:

```bash
ansible-playbook -i inventory/hosts.yml playbooks/site.yml \
  -e "@inventory/group_vars/custom.yml"
```

### SSL/TLS Configuration

Enable SSL redirects and HTTPS:

```bash
ansible-playbook -i inventory/hosts.yml playbooks/site.yml \
  -e "features.ssl_redirect=true" \
  -e "domain_suffix=secure.company.com"
```

### Network Configuration

Configure custom network settings:

```bash
# Custom service ports
ansible-playbook -i inventory/hosts.yml playbooks/site.yml \
  -e "service_ports.jenkins=9080" \
  -e "service_ports.sonarqube=9090" \
  -e "service_ports.grafana=3030"

# Custom external access
ansible-playbook -i inventory/hosts.yml playbooks/azure-access.yml \
  -e "external_ip=manual" \
  -e "manual_external_ip=203.0.113.10" \
  -e "use_nip_io=false"
```

## 🛠️ Maintenance Examples

### Updating Services

Update Jenkins configuration:

```bash
# Update Jenkins with new resource limits
ansible-playbook -i inventory/hosts.yml playbooks/jenkins.yml \
  -e "resources.jenkins.limits.memory=6Gi"

# Upgrade Jenkins image
ansible-playbook -i inventory/hosts.yml playbooks/jenkins.yml \
  -e "jenkins.image.tag=latest-v2"
```

Update application deployment:

```bash
# Update Flask app with new image
ansible-playbook -i inventory/hosts.yml playbooks/application.yml \
  -e "app_version=2.0.0"

# Scale application replicas
ansible-playbook -i inventory/hosts.yml playbooks/application.yml \
  -e "flask_app.replicas=5"
```

### Backup Operations

Create backups before major changes:

```bash
# Backup configurations
ansible -i inventory/hosts.yml devsecops -m shell \
  -a "microk8s kubectl get all -A -o yaml > /tmp/k8s-backup-$(date +%Y%m%d).yaml"

# Backup Jenkins data
ansible -i inventory/hosts.yml devsecops -m command \
  -a "tar -czf /tmp/jenkins-backup-$(date +%Y%m%d).tar.gz /var/snap/microk8s/common/default-storage/jenkins-*"

# Backup SonarQube database
ansible -i inventory/hosts.yml devsecops -m shell \
  -a "microk8s kubectl exec -n sonarqube postgresql-0 -- pg_dump -U sonarqube sonarqube > /tmp/sonar-backup-$(date +%Y%m%d).sql"
```

### Health Checks

Perform health checks:

```bash
# Check all pod status
ansible -i inventory/hosts.yml devsecops -m command \
  -a "microk8s kubectl get pods -A"

# Check service endpoints
ansible -i inventory/hosts.yml devsecops -m command \
  -a "microk8s kubectl get endpoints -A"

# Check resource usage
ansible -i inventory/hosts.yml devsecops -m command \
  -a "microk8s kubectl top nodes"

# Check storage usage
ansible -i inventory/hosts.yml devsecops -m command \
  -a "microk8s kubectl get pvc -A"
```

## 🧹 Cleanup Examples

### Selective Cleanup

Remove specific components:

```bash
# Remove only Jenkins
ansible-playbook -i inventory/hosts.yml playbooks/cleanup.yml --tags jenkins

# Remove monitoring stack
ansible-playbook -i inventory/hosts.yml playbooks/cleanup.yml --tags monitoring

# Remove application deployment
ansible-playbook -i inventory/hosts.yml playbooks/cleanup.yml --tags application

# Remove external access configuration
ansible-playbook -i inventory/hosts.yml playbooks/cleanup.yml --tags external-access
```

### Complete Environment Cleanup

```bash
# Remove everything
ansible-playbook -i inventory/hosts.yml playbooks/cleanup.yml --tags all

# Cleanup with confirmation
ansible-playbook -i inventory/hosts.yml playbooks/cleanup.yml --tags all \
  --extra-vars "confirm_cleanup=yes"
```

### Development Environment Reset

```bash
# Stop Docker Compose services
ansible-playbook -i inventory/hosts.yml playbooks/cleanup.yml --tags docker-compose

# Clean up Docker images and volumes
ansible -i inventory/hosts.yml devsecops -m command -a "docker system prune -a --volumes"
```

## 🔍 Debugging Examples

### Verbose Deployment

Run with maximum verbosity for debugging:

```bash
# Maximum verbosity
ansible-playbook -i inventory/hosts.yml playbooks/site.yml -vvvv

# Debug specific tasks
ansible-playbook -i inventory/hosts.yml playbooks/jenkins.yml -vvv --step

# Debug variable values
ansible -i inventory/hosts.yml devsecops -m debug \
  -a "var=hostvars[inventory_hostname]"
```

### Service Debugging

Debug specific services:

```bash
# Check Jenkins pod logs
ansible -i inventory/hosts.yml devsecops -m shell \
  -a "microk8s kubectl logs -n jenkins -l app.kubernetes.io/instance=jenkins --tail=50"

# Debug SonarQube connectivity
ansible -i inventory/hosts.yml devsecops -m shell \
  -a "microk8s kubectl exec -n sonarqube sonarqube-sonarqube-0 -- curl -I http://postgresql:5432"

# Test Grafana datasource
ansible -i inventory/hosts.yml devsecops -m shell \
  -a "microk8s kubectl exec -n monitoring <grafana-pod> -- curl -I http://loki:3100/ready"
```

### Network Debugging

Debug network connectivity:

```bash
# Test pod-to-pod communication
ansible -i inventory/hosts.yml devsecops -m shell \
  -a "microk8s kubectl exec -n jenkins <jenkins-pod> -- curl -I http://sonarqube-sonarqube.sonarqube.svc.cluster.local:9000"

# Check DNS resolution
ansible -i inventory/hosts.yml devsecops -m shell \
  -a "microk8s kubectl exec -n default <pod> -- nslookup jenkins.jenkins.svc.cluster.local"

# Test ingress connectivity
ansible -i inventory/hosts.yml devsecops -m shell \
  -a "curl -I http://jenkins.local -H 'Host: jenkins.local'"
```

## 🎛️ Advanced Usage Examples

### Custom Helm Values

Deploy with custom Helm values:

```yaml
# custom-jenkins-values.yml
controller:
  numExecutors: 4
  resources:
    requests:
      cpu: "1000m"
      memory: "2Gi"
    limits:
      cpu: "3000m"
      memory: "6Gi"
  adminPassword: "CustomPassword123!"
```

```bash
# Deploy with custom values file
ansible-playbook -i inventory/hosts.yml playbooks/jenkins.yml \
  -e "jenkins_custom_values_file=custom-jenkins-values.yml"
```

### Integration with External Systems

Configure external integrations:

```bash
# Configure external database
ansible-playbook -i inventory/hosts.yml playbooks/sonarqube.yml \
  -e "sonarqube.postgresql.host=external-db.company.com" \
  -e "sonarqube.postgresql.port=5432" \
  -e "sonarqube.postgresql.database=sonarqube_prod"

# Configure external monitoring
ansible-playbook -i inventory/hosts.yml playbooks/monitoring.yml \
  -e "monitoring.grafana.datasources[0].url=http://external-loki.company.com:3100"
```

### Scaling Examples

Scale services horizontally:

```bash
# Scale Flask application
ansible-playbook -i inventory/hosts.yml playbooks/application.yml \
  -e "flask_app.replicas=6" \
  -e "flask_app.autoscaling.max_replicas=15"

# Scale Jenkins agents
ansible-playbook -i inventory/hosts.yml playbooks/jenkins.yml \
  -e "jenkins_executor_count=4"
```

## 🔐 Security Examples

### Security Hardening

Apply security configurations:

```bash
# Enable security features
ansible-playbook -i inventory/hosts.yml playbooks/site.yml \
  -e "features.security_scanning=true" \
  -e "features.ssl_redirect=true" \
  -e "jenkins.security.run_as_non_root=true"

# Configure network policies
ansible-playbook -i inventory/hosts.yml playbooks/site.yml \
  -e "enable_network_policies=true"
```

### Secrets Management

Use Ansible Vault for secrets:

```bash
# Create encrypted secrets file
ansible-vault create secrets.yml

# Deploy with encrypted secrets
ansible-playbook -i inventory/hosts.yml playbooks/site.yml \
  -e "@secrets.yml" --ask-vault-pass

# Use password file
ansible-playbook -i inventory/hosts.yml playbooks/site.yml \
  -e "@secrets.yml" --vault-password-file vault-pass.txt
```

## 📊 Monitoring Examples

### Custom Monitoring Configuration

Configure custom monitoring:

```bash
# Enable Prometheus metrics
ansible-playbook -i inventory/hosts.yml playbooks/monitoring.yml \
  -e "prometheus_enabled=true" \
  -e "metrics_path=/custom-metrics"

# Configure log retention
ansible-playbook -i inventory/hosts.yml playbooks/monitoring.yml \
  -e "log_retention=168h"  # 7 days
```

### Health Check Automation

Automate health checks:

```bash
# Create health check script
cat << 'EOF' > health-check.yml
---
- name: DevSecOps Health Check
  hosts: devsecops
  tasks:
    - name: Check pod status
      command: microk8s kubectl get pods -A --field-selector=status.phase!=Running
      register: unhealthy_pods
      failed_when: unhealthy_pods.stdout_lines | length > 0
    
    - name: Check service endpoints
      command: microk8s kubectl get endpoints -A -o jsonpath='{.items[?(@.subsets[0].addresses[0])].metadata.name}'
      register: active_endpoints
    
    - name: Display health status
      debug:
        msg: "All services healthy. Active endpoints: {{ active_endpoints.stdout.split() | length }}"
EOF

# Run health check
ansible-playbook -i inventory/hosts.yml health-check.yml
```

This examples guide provides practical usage patterns for the DevSecOps Ansible automation. Choose the examples that best fit your use case and adapt them as needed for your specific environment.
