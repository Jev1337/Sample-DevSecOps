# Configuration Guide

This guide covers detailed configuration options for the DevSecOps environment.

## 🎛️ Configuration Files

### Primary Configuration Files

1. **`inventory/hosts.yml`** - Target servers and connection details
2. **`inventory/group_vars/all.yml`** - Global configuration variables
3. **`inventory/group_vars/devsecops.yml`** - DevSecOps specific settings
4. **`ansible.cfg`** - Ansible behavior configuration

## 🌐 Infrastructure Configuration

### External IP Configuration

```yaml
# Auto-detect external IP
external_ip: "auto"

# Manually specify IP
external_ip: "1.2.3.4"

# Use manual configuration
external_ip: "manual"
manual_external_ip: "1.2.3.4"
```

### Domain Configuration

```yaml
# Local development
domain_suffix: "local"

# Custom domain
domain_suffix: "example.com"

# Enable nip.io for external access
use_nip_io: true
```

### Storage Configuration

```yaml
storage:
  microk8s_registry_size: "20Gi"
  jenkins_storage_size: "8Gi"
  postgresql_storage_size: "8Gi"
  grafana_storage_size: "2Gi"
  loki_storage_size: "5Gi"
```

## 🔐 Security Configuration

### Passwords and Secrets

```yaml
# Change these in production!
jenkins_admin_password: "your-secure-jenkins-password"
sonarqube_admin_password: "your-secure-sonar-password"
grafana_admin_password: "your-secure-grafana-password"
postgresql_password: "your-secure-db-password"

# Base64 encoded secrets
secrets:
  flask_secret_key: "base64-encoded-secret"
  database_password: "base64-encoded-password"
  api_token: "base64-encoded-token"
```

**To generate base64 encoded secrets:**
```bash
echo -n "your-secret" | base64
```

### Service Account Configuration

```yaml
jenkins:
  rbac:
    create: true
    cluster_admin: true  # Set to false for restricted access
  security:
    run_as_user: 0       # 0 for root, 1000+ for non-root
    run_as_non_root: false
```

## 🚀 Service Configuration

### Jenkins Configuration

```yaml
jenkins:
  namespace: jenkins
  image:
    registry: "localhost:32000"
    repository: "jenkins-devsecops"
    tag: "latest"
  service:
    type: "ClusterIP"        # Options: ClusterIP, NodePort, LoadBalancer
    port: 8080
  executor_count: 2          # Number of build executors
  plugins_install: false    # Our custom image has plugins
```

### SonarQube Configuration

```yaml
sonarqube:
  namespace: sonarqube
  community:
    enabled: true            # Use community edition
  persistence:
    enabled: false           # Use external PostgreSQL
  postgresql:
    host: "postgresql.sonarqube.svc.cluster.local"
    port: 5432
    database: "sonarqube"
    username: "sonarqube"
```

### Monitoring Configuration

```yaml
monitoring:
  namespace: monitoring
  loki:
    deployment_mode: "SingleBinary"  # For single-node deployment
    auth_enabled: false
    storage:
      type: "filesystem"
  grafana:
    admin_password: "your-password"
    datasources:
      - name: "Loki"
        type: "loki"
        url: "http://loki.monitoring.svc.cluster.local:3100"
        default: true
```

### Application Configuration

```yaml
flask_app:
  namespace: flask-app
  replicas: 3
  config:
    flask_env: "production"   # Options: development, production
    log_level: "INFO"         # Options: DEBUG, INFO, WARNING, ERROR
  autoscaling:
    enabled: true
    min_replicas: 2
    max_replicas: 10
    cpu_threshold: 70
    memory_threshold: 80
```

## 💾 Resource Management

### Resource Limits

```yaml
resources:
  jenkins:
    requests:
      cpu: "500m"
      memory: "1Gi"
    limits:
      cpu: "2000m"
      memory: "4Gi"
  
  sonarqube:
    requests:
      cpu: "500m"
      memory: "1024Mi"
    limits:
      cpu: "1000m"
      memory: "2048Mi"
```

### CPU and Memory Units

- **CPU:** Use millicores (m) or full cores
  - `100m` = 0.1 CPU core
  - `1000m` = 1 CPU core
  - `2` = 2 CPU cores

- **Memory:** Use standard units
  - `128Mi` = 128 Mebibytes
  - `1Gi` = 1 Gibibyte
  - `2048Mi` = 2 Gibibytes

## 🌐 Network Configuration

### Service Ports

```yaml
service_ports:
  jenkins: 8080
  sonarqube: 9000
  grafana: 3000
  flask_app: 5000
  loki: 3100

external_ports:
  jenkins: 8080
  sonarqube: 9000
  grafana: 3000
  flask_app: 80
```

### Ingress Configuration

```yaml
# Per-service ingress settings
jenkins:
  ingress:
    enabled: true
    hostname: "jenkins.local"
    class: "public"

# Global SSL settings
features:
  ssl_redirect: false  # Set to true for HTTPS redirect
```

## 🔄 Deployment Modes

### Production Mode (Default)

```yaml
environment_type: "production"
deployment_mode: "kubernetes"
features:
  azure_external_access: true
  monitoring_enabled: true
  security_scanning: true
  auto_scaling: true
```

### Development Mode

```yaml
environment_type: "development"
deployment_mode: "docker-compose"
features:
  development_mode: true
  monitoring_enabled: false
  security_scanning: false
  auto_scaling: false
```

## 🏗️ Custom Image Builds

### Jenkins Custom Image

```yaml
custom_images:
  - name: "jenkins-devsecops"
    dockerfile_path: "../jenkins/Dockerfile"
    context_path: "../jenkins"
    tags:
      - "jenkins-devsecops:latest"
      - "localhost:32000/jenkins-devsecops:latest"
```

### Application Image

```yaml
custom_images:
  - name: "flask-k8s-app"
    dockerfile_path: "../app/Dockerfile"
    context_path: "../app"
    build_args:
      BUILD_DATE: "{{ ansible_date_time.iso8601 }}"
      GIT_COMMIT: "{{ ansible_env.GIT_COMMIT | default('unknown') }}"
```

## 📊 Monitoring and Observability

### Log Retention

```yaml
log_retention: "72h"  # How long to keep logs

# Custom log patterns
log_patterns:
  - "/var/log/*.log"
  - "/opt/app/logs/*.log"
```

### Metrics Configuration

```yaml
prometheus_enabled: true
metrics_path: "/metrics"

# Custom metrics endpoints
metrics_endpoints:
  - name: "flask-app"
    path: "/metrics"
    port: 5000
```

## 🔧 Advanced Configuration

### Kubernetes Namespaces

```yaml
namespaces:
  - name: jenkins
    labels:
      app.kubernetes.io/name: jenkins
      app.kubernetes.io/component: ci-cd
  - name: sonarqube
    labels:
      app.kubernetes.io/name: sonarqube
      app.kubernetes.io/component: code-quality
```

### Helm Repositories

```yaml
helm_repos:
  - name: jenkins
    url: https://charts.jenkins.io
  - name: grafana
    url: https://grafana.github.io/helm-charts
  - name: custom-repo
    url: https://your-custom-helm-repo.com
```

### Feature Flags

```yaml
features:
  azure_external_access: true   # Enable LoadBalancer services
  development_mode: false       # Enable Docker Compose mode
  ssl_redirect: false           # Force HTTPS redirects
  monitoring_enabled: true      # Deploy monitoring stack
  security_scanning: true       # Enable Trivy scanning
  auto_scaling: true            # Enable HPA
```

## 🚀 Environment-Specific Configurations

### Production Environment

```yaml
# inventory/group_vars/production.yml
environment_type: "production"
resources:
  jenkins:
    requests:
      cpu: "1000m"
      memory: "2Gi"
    limits:
      cpu: "4000m"
      memory: "8Gi"
storage:
  jenkins_storage_size: "20Gi"
  postgresql_storage_size: "50Gi"
```

### Development Environment

```yaml
# inventory/group_vars/development.yml
environment_type: "development"
resources:
  jenkins:
    requests:
      cpu: "250m"
      memory: "512Mi"
    limits:
      cpu: "1000m"
      memory: "2Gi"
storage:
  jenkins_storage_size: "5Gi"
  postgresql_storage_size: "10Gi"
```

## 📝 Configuration Validation

### Check Configuration

```bash
# Validate Ansible syntax
ansible-playbook --syntax-check -i inventory/hosts.yml playbooks/site.yml

# Dry run to see what would change
ansible-playbook --check -i inventory/hosts.yml playbooks/site.yml

# List all variables for a host
ansible -i inventory/hosts.yml devsecops-server -m debug -a "var=hostvars[inventory_hostname]"
```

### Test Configuration

```bash
# Test specific components
ansible-playbook -i inventory/hosts.yml playbooks/site.yml --tags jenkins --check

# Test with different variables
ansible-playbook -i inventory/hosts.yml playbooks/site.yml -e "environment_type=development"
```

## 🔄 Configuration Updates

### Rolling Updates

```bash
# Update specific services
ansible-playbook -i inventory/hosts.yml playbooks/jenkins.yml

# Update with new configuration
ansible-playbook -i inventory/hosts.yml playbooks/site.yml --tags monitoring
```

### Configuration Backup

```bash
# Backup current configuration
kubectl get all -A -o yaml > backup-$(date +%Y%m%d).yaml

# Export Helm values
helm get values jenkins -n jenkins > jenkins-values-backup.yml
```

## 🆘 Configuration Troubleshooting

### Common Configuration Issues

1. **Invalid YAML syntax**
   ```bash
   # Check YAML syntax
   python -c "import yaml; yaml.safe_load(open('inventory/group_vars/all.yml'))"
   ```

2. **Variable not defined**
   ```bash
   # Check variable usage
   ansible -i inventory/hosts.yml devsecops -m debug -a "var=undefined_variable"
   ```

3. **Resource constraints**
   ```bash
   # Check resource usage
   kubectl top nodes
   kubectl top pods -A
   ```

### Best Practices

1. **Version Control:** Keep configuration in Git
2. **Environment Separation:** Use different inventory files for different environments
3. **Secrets Management:** Use Ansible Vault for sensitive data
4. **Validation:** Always test configuration changes in development first
5. **Documentation:** Document custom configurations and changes
