# SIEM Integration Documentation

## Overview
This document describes the Security Information and Event Management (SIEM) capabilities integrated into the DevSecOps environment.

## Components

### 1. Kubernetes Audit Logging
- **Location**: `/var/log/kubernetes/audit.log`
- **Policy**: `siem/configs/audit-policy.yaml`
- **Configuration**: Automatically configured in MicroK8s API server
- **Events Logged**:
  - Secret and ServiceAccount access
  - RBAC changes
  - Pod and deployment modifications
  - ConfigMap access in sensitive namespaces
  - Namespace operations
  - Network policy changes

### 2. SSH and System Log Collection
- **Sources**: 
  - `/var/log/auth.log` - SSH authentication events
  - `/var/log/secure` - Security-related events
  - `/var/log/messages` - General system messages
- **Collection Method**: Alloy with host volume mounts
- **Processing**: Automated log parsing and labeling

### 3. Webhook Receiver Service
- **Purpose**: Collect Git/SCM webhook events
- **Endpoint**: `http://webhook.{EXTERNAL_IP}.nip.io/webhook`
- **Supported Sources**: GitHub, GitLab, and generic webhooks
- **Data Format**: JSON logs sent to Loki
- **Features**:
  - Event type detection
  - Source IP logging
  - Repository and user extraction
  - Structured logging to Loki

### 4. SIEM Dashboard
- **Location**: Grafana → Dashboards → "SIEM - Security Monitoring Dashboard"
- **Panels**:
  - SSH Authentication Events counter
  - Failed SSH Attempts table
  - Kubernetes API Audit Events log view
  - Webhook Events log view
  - Security Events Timeline graph
  - Critical Security Events alerts
  - User Activity table

## Deployment

### Automated Deployment
```bash
# Run the setup script and choose option 9
./setup.sh
# Select option: 9) Deploy SIEM Stack (Security Monitoring)
```

### Manual Deployment with Ansible
```bash
cd ansible
ansible-playbook -i inventory playbooks/siem.yml
```

### Manual Deployment Steps
1. **Setup Kubernetes audit logging**:
   ```bash
   sudo mkdir -p /etc/kubernetes/siem
   sudo cp siem/configs/audit-policy.yaml /etc/kubernetes/siem/
   # Configure MicroK8s (done automatically by setup script)
   ```

2. **Deploy webhook service**:
   ```bash
   cd webhook
   docker build -t webhook-receiver:latest .
   docker tag webhook-receiver:latest localhost:32000/webhook-receiver:latest
   docker push localhost:32000/webhook-receiver:latest
   microk8s kubectl apply -f webhook-deployment.yaml
   ```

3. **Update Alloy configuration**:
   ```bash
   microk8s helm3 upgrade alloy grafana/alloy -n monitoring -f helm/alloy/values.yaml
   ```

## Access URLs

### Local Access (with /etc/hosts configuration)
- Security Dashboard: `http://grafana.local` → SIEM Dashboard
- Webhook Endpoint: `http://webhook.local/webhook`

### External Access (nip.io domains)
- Security Dashboard: `http://grafana.{EXTERNAL_IP}.nip.io`
- Webhook Endpoint: `http://webhook.{EXTERNAL_IP}.nip.io/webhook`

## LogQL Query Examples

### SSH Security Events
```logql
# Failed SSH attempts
{job="node-logs"} |~ "Failed password|authentication failure|Invalid user"

# Successful SSH logins
{job="node-logs"} |~ "Accepted password|Accepted publickey"

# SSH from specific IP
{job="node-logs"} |~ "ssh" | json | source_ip="192.168.1.100"
```

### Kubernetes Audit Events
```logql
# All audit events
{job="kubernetes-audit"} | json

# Secret access events
{job="kubernetes-audit"} | json | objectRef_resource="secrets"

# RBAC changes
{job="kubernetes-audit"} | json | objectRef_resource=~"roles|rolebindings|clusterroles|clusterrolebindings"

# Pod exec events
{job="kubernetes-audit"} | json | objectRef_subresource="exec"

# Events by specific user
{job="kubernetes-audit"} | json | user_username="admin"
```

### Webhook Events
```logql
# All webhook events
{job="webhook-receiver"} | json

# GitHub events
{job="webhook-receiver"} | json | source="github"

# Push events
{job="webhook-receiver"} | json | event_type="push"

# Events from specific IP
{job="webhook-receiver"} | json | source_ip="203.0.113.1"
```

### Combined Security Queries
```logql
# All security-related events
{job=~"node-logs|kubernetes-audit|webhook-receiver"} |~ "(?i)(failed|error|denied|unauthorized|forbidden)"

# High-priority security events
{job=~".*"} |~ "(?i)(attack|breach|malware|virus|intrusion|compromise)"
```

## Security Best Practices

### 1. Log Protection
- Audit logs are stored with restricted permissions (640)
- Logs are automatically rotated to prevent disk space issues
- Consider implementing log encryption at rest

### 2. Access Control
- Webhook endpoint should be secured in production
- Implement authentication for webhook endpoint if needed
- Restrict access to audit log files

### 3. Monitoring and Alerting
- Set up Grafana alerts for suspicious activities
- Monitor for unusual patterns in SSH attempts
- Alert on sensitive Kubernetes API operations

### 4. Compliance
- Audit logs help meet compliance requirements
- Implement proper log retention policies
- Ensure logs are tamper-evident

## Troubleshooting

### Common Issues

1. **Audit logs not generated**:
   ```bash
   # Check if audit policy is configured
   cat /var/snap/microk8s/current/args/kube-apiserver | grep audit
   
   # Check audit log file exists
   ls -la /var/log/kubernetes/audit.log
   
   # Restart MicroK8s if needed
   microk8s stop && microk8s start
   ```

2. **Webhook service not receiving events**:
   ```bash
   # Check webhook deployment status
   microk8s kubectl get deployment webhook-receiver -n monitoring
   
   # Check logs
   microk8s kubectl logs -n monitoring -l app=webhook-receiver
   
   # Test webhook endpoint
   curl -X POST http://webhook.{EXTERNAL_IP}.nip.io/webhook -H "Content-Type: application/json" -d '{"test": "data"}'
   ```

3. **Alloy not collecting logs**:
   ```bash
   # Check Alloy configuration
   microk8s kubectl get configmap alloy -n monitoring -o yaml
   
   # Check Alloy logs
   microk8s kubectl logs -n monitoring -l app.kubernetes.io/name=alloy
   
   # Restart Alloy
   microk8s kubectl rollout restart daemonset/alloy -n monitoring
   ```

### Log Volume Mounts
The Alloy configuration requires proper volume mounts to access host logs:
- `/var/log/auth.log` - SSH authentication logs
- `/var/log/secure` - Security logs (RHEL/CentOS)
- `/var/log/kubernetes/audit.log` - Kubernetes audit logs

### Dashboard Issues
If the SIEM dashboard doesn't show data:
1. Verify Loki data source is configured
2. Check that logs are flowing to Loki
3. Verify LogQL queries in Grafana Explore
4. Import the dashboard manually if needed

## Configuration Files

### Key Files
- `siem/configs/audit-policy.yaml` - Kubernetes audit policy
- `webhook/app.py` - Webhook receiver service
- `helm/alloy/values.yaml` - Log collection configuration
- `monitoring/grafana/dashboards/siem-security.json` - SIEM dashboard
- `ansible/playbooks/siem.yml` - SIEM deployment playbook

### Ansible Roles
- `ansible/roles/siem_audit/` - Kubernetes audit logging setup
- `ansible/roles/siem_webhook/` - Webhook service deployment
- `ansible/roles/siem_monitoring/` - Dashboard and monitoring setup

## Integration with External Systems

### Git Webhook Configuration
Configure your Git repositories to send webhooks to:
- URL: `http://webhook.{EXTERNAL_IP}.nip.io/webhook`
- Method: POST
- Content-Type: application/json

### SIEM Integration
The logs can be forwarded to external SIEM systems:
- Configure Alloy to send logs to external endpoints
- Use Loki's remote write capabilities
- Export logs via LogQL API

### Alerting Integration
- Configure Grafana alerts to send to external systems
- Use webhooks for alert notifications
- Integrate with PagerDuty, Slack, or other alerting platforms
