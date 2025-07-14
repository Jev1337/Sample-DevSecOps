# SIEM Integration for DevSecOps Project

This directory contains Security Information and Event Management (SIEM) components for the DevSecOps project.

## Overview

The SIEM integration enhances the security monitoring capabilities of the DevSecOps environment by collecting, analyzing, and visualizing security-related events from various sources:

- Host-level system logs (auth.log, syslog)
- SSH login attempts
- Package management activities
- Webhook events from Git repositories
- Application security events
- Kubernetes audit logs
- System file changes

## Components

### Configuration Files

- **auditd-config.yaml**: Configures Linux audit daemon to monitor security-relevant events
- **rsyslog-config.yaml**: Configures system logging with enhanced security focus
- **fail2ban-config.yaml**: Sets up intrusion prevention by blocking suspicious IPs
- **alloy-security-config.river**: Configures Alloy for security log collection
- **k8s-audit-policy.yaml**: Defines Kubernetes API server audit policy
- **webhook-receiver.yaml**: Kubernetes manifest for Git webhook receiver

### Dashboards

- **siem-dashboard.json**: Comprehensive security monitoring dashboard for Grafana
- **alert-rules.json**: Security alerting rules for Grafana

## Setup

The SIEM components are deployed as part of the main setup script. To deploy just the SIEM components:

```bash
./setup.sh
# Select option 9 from the menu: "Deploy SIEM Components"
```

For a complete SecOps setup including all components:

```bash
./setup.sh
# Select option 11 from the menu: "Complete SecOps Setup (3-9)"
```

## Features

1. **SSH Login Monitoring**:
   - Captures authentication attempts
   - Visualizes successful/failed logins
   - Alerts on multiple failed attempts

2. **Webhook Security**:
   - Dedicated webhook endpoint for Git events
   - Request logging and validation
   - Event correlation with source code changes

3. **System Logs Collection**:
   - Central collection of auth.log, syslog, kernel logs
   - Pattern matching for security events
   - Timeline visualization of system events

4. **Application Logs Monitoring**:
   - Error rate tracking for Flask, Jenkins, SonarQube
   - Authentication failure monitoring
   - API security event detection

5. **Package Management**:
   - Tracking of apt/dpkg activities
   - Visualization of installed, updated, removed packages
   - Alerting on unexpected package changes

6. **Audit Logging**:
   - Kernel-level system call monitoring
   - File access tracking for sensitive files
   - Command execution logging

7. **Kubernetes Security**:
   - API server audit logging
   - RBAC changes monitoring
   - Secret and ConfigMap access tracking

## Dashboard Access

Access the SIEM dashboard through Grafana:

- URL: http://grafana.EXTERNAL_IP.nip.io (or http://grafana.local)
- Dashboard: Navigate to "SIEM Dashboard" in the dashboard list

## Webhook Configuration

To configure GitHub/GitLab webhooks:

1. Get webhook URL: http://webhook.EXTERNAL_IP.nip.io/webhook
2. Add webhook to GitHub/GitLab repository settings
3. Select events to monitor (push, pull requests, etc.)

## Security Best Practices

1. Regularly review security alerts in the SIEM dashboard
2. Configure notification channels in Grafana for alerts
3. Review and update fail2ban rules based on false positives
4. Regularly audit system users and permissions
5. Update auditd rules as new security requirements emerge

## Troubleshooting

Common issues and solutions:

- **Missing logs**: Ensure Alloy has proper volume mounts to /var/log
- **No Kubernetes audit logs**: Verify audit policy is correctly applied to kube-apiserver
- **Webhook not receiving events**: Check ingress and network connectivity
