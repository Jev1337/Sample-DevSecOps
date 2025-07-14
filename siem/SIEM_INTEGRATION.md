# SIEM Integration Documentation

## Overview

This document provides details on the Security Information and Event Management (SIEM) integration for the DevSecOps project. The SIEM system is designed to collect, analyze, correlate, and visualize security events from various sources within the DevSecOps environment.

## Architecture

The SIEM solution is built upon the existing monitoring stack with additional security-focused components:

```
┌─────────────────────────────────────────┐
│                                         │
│         Security Event Sources          │
│                                         │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ │
│  │  System  │ │   SSH    │ │   APT    │ │
│  │   Logs   │ │   Logs   │ │   Logs   │ │
│  └────┬─────┘ └────┬─────┘ └────┬─────┘ │
│       │            │            │       │
│  ┌────▼─────┐ ┌────▼─────┐ ┌────▼─────┐ │
│  │  Auditd  │ │ Fail2Ban │ │ Webhook  │ │
│  │          │ │          │ │ Receiver │ │
│  └────┬─────┘ └────┬─────┘ └────┬─────┘ │
│       │            │            │       │
└───────┼────────────┼────────────┼───────┘
        │            │            │        
┌───────▼────────────▼────────────▼───────┐
│                                         │
│           Log Collection                │
│                                         │
│  ┌───────────────────────────────────┐  │
│  │              Alloy                │  │
│  │  (with security-focused config)   │  │
│  └────────────────┬──────────────────┘  │
│                   │                     │
└───────────────────┼─────────────────────┘
                    │                      
┌───────────────────▼─────────────────────┐
│                                         │
│           Log Storage                   │
│                                         │
│  ┌───────────────────────────────────┐  │
│  │               Loki                │  │
│  │   (indexed by security labels)    │  │
│  └────────────────┬──────────────────┘  │
│                   │                     │
└───────────────────┼─────────────────────┘
                    │                      
┌───────────────────▼─────────────────────┐
│                                         │
│        Visualization & Alerting         │
│                                         │
│  ┌───────────────────────────────────┐  │
│  │             Grafana               │  │
│  │     (SIEM Dashboard + Alerts)     │  │
│  └───────────────────────────────────┘  │
│                                         │
└─────────────────────────────────────────┘
```

## Components Details

### Log Collection (Alloy)

Alloy is configured to collect and process security events with specialized configurations:

1. **Custom River Configuration**: Enhanced logging configuration in `alloy-security-config.river`
2. **Host System Access**: Mounts host log directories (/var/log, /var/log/audit)
3. **Security Event Labeling**: Adds security-specific metadata to logs
4. **Pattern Matching**: Regular expressions to identify security events

### Security Event Sources

1. **auditd**: Linux Audit Framework that monitors system calls and security events
   - File access monitoring
   - Command execution auditing
   - User and group modifications tracking

2. **SSH Monitoring**: Tracks SSH authentication attempts
   - Failed login detection
   - Source IP tracking
   - Brute force attempt identification

3. **Package Management**: Monitors software installation and updates
   - APT/DPKG activity logging
   - Package modification tracking
   - Software update monitoring

4. **Webhook Receiver**: Custom service for Git event monitoring
   - Repository activity logging
   - Authentication validation
   - Webhook payload analysis

5. **Kubernetes Audit Logging**: API server event monitoring
   - RBAC changes
   - Secret access tracking
   - ConfigMap modifications
   - Privilege escalation detection

6. **Fail2Ban**: Intrusion prevention system
   - Automatic IP blocking
   - SSH protection
   - Webhook protection

### Visualization (Grafana)

1. **SIEM Dashboard**: Comprehensive security monitoring dashboard
   - Authentication failure metrics
   - System file change tracking
   - Package management visualization
   - SSH activity monitoring
   - Top attack sources

2. **Alert Rules**: Security-focused alerting
   - Multiple authentication failures
   - System file changes
   - Privilege escalation
   - High application error rates
   - Package modification alerts

## Data Flow

1. Security events are generated across the environment
2. Auditd, Rsyslog, and other services record events to log files
3. Alloy collects logs with security-focused configuration
4. Logs are processed, labeled, and streamed to Loki
5. Loki indexes logs with security metadata
6. Grafana visualizes security events in the SIEM dashboard
7. Alert rules trigger notifications for suspicious activities

## Security Event Types

The SIEM system monitors and categorizes these security event types:

| Event Type | Source | Description |
|------------|--------|-------------|
| Authentication Failure | SSH, Web Apps | Failed login attempts |
| Privilege Escalation | sudo, su | Elevation to root/admin access |
| System File Change | auditd | Critical file modifications |
| Package Event | apt, dpkg | Software installation/removal |
| SSH Activity | sshd | Connection attempts and sessions |
| Git Webhook | webhook-receiver | Repository activity events |
| System Audit | auditd | System call monitoring |
| K8s Security | kube-apiserver | API server security events |

## Implementation Details

### 1. Host System Configuration

The setup script configures these core security tools:

```bash
# Install core security tools
sudo apt-get install -y auditd audispd-plugins rsyslog fail2ban

# Configure auditd with security rules
sudo cp -f siem/configs/auditd-config.yaml /etc/audit/rules.d/audit.rules

# Configure rsyslog for security logging
sudo cp -f siem/configs/rsyslog-config.yaml /etc/rsyslog.d/99-siem.conf

# Configure fail2ban for intrusion prevention
sudo cp -f siem/configs/fail2ban-config.yaml /etc/fail2ban/jail.local
```

### 2. Kubernetes Audit Logging

MicroK8s is configured for audit logging:

```bash
# Create audit directory
sudo mkdir -p /var/snap/microk8s/current/audit

# Configure audit policy
sudo cp -f siem/configs/k8s-audit-policy.yaml /var/snap/microk8s/current/audit/audit-policy.yaml

# Update kube-apiserver configuration
sudo sed -i '/^CERT_ARGS/ a AUDIT_ARGS="--audit-log-path=/var/snap/microk8s/current/audit/audit.log --audit-log-maxage=30 --audit-log-maxbackup=10 --audit-log-maxsize=100 --audit-policy-file=/var/snap/microk8s/current/audit/audit-policy.yaml"' /var/snap/microk8s/current/args/kube-apiserver
```

### 3. Alloy Security Configuration

The Alloy configuration includes specialized processing:

```river
# Process to add security labels based on log content
loki.process "security_label" {
  forward_to = [loki.write.default.receiver]
  
  # Authentication failures detection
  stage.regex {
    expression = "(?i)(failed password|authentication failure|invalid user)"
    source     = "message"
    labels = {
      security_event_type = "authentication_failure"
    }
  }
  
  # Additional patterns for other security events
  // ...
}
```

### 4. Webhook Receiver

A lightweight Nginx-based service processes Git webhooks:

```yaml
server {
  listen 8080;
  
  location /webhook {
    # Log the request body and headers
    access_log /var/log/nginx/webhook.log '{"timestamp":"$time_iso8601", "client":"$remote_addr", "method":"$request_method", "github_event":"$http_x_github_event", "delivery_id":"$http_x_github_delivery"}';
    
    # Security validation and processing
    // ...
  }
}
```

## Testing the SIEM

Use the provided test script to validate SIEM functionality:

```bash
# Run the SIEM test script
./siem/test-siem.sh
```

This script:
1. Generates simulated SSH failures
2. Creates system file modification events
3. Logs package management activities
4. Simulates privilege escalation
5. Tests the webhook endpoint

## Maintenance and Operations

### Regular Maintenance Tasks

1. **Log Rotation**: Configure log rotation to manage storage
   ```bash
   sudo logrotate -f /etc/logrotate.d/audit
   ```

2. **Dashboard Updates**: Keep dashboards updated with new threat patterns
   ```bash
   # Update dashboard ConfigMap
   kubectl create configmap siem-dashboard -n monitoring --from-file=siem-dashboard.json=siem/dashboards/siem-dashboard.json -o yaml --dry-run=client | kubectl apply -f -
   ```

3. **Rule Tuning**: Adjust Fail2Ban rules based on false positives
   ```bash
   sudo fail2ban-client set sshd unbanip 192.168.1.100
   ```

### Alert Response Procedures

1. **Authentication Failures**: Investigate source IPs and usernames
2. **System File Changes**: Compare changes with expected maintenance
3. **Privilege Escalation**: Verify authorized admin activity
4. **Package Events**: Cross-reference with change management

## Conclusion

The integrated SIEM solution provides comprehensive security monitoring across the DevSecOps environment, enabling early detection of security incidents, enhanced visibility into system activity, and automated response capabilities through alerting and intrusion prevention.
