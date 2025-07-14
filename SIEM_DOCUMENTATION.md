# SIEM Integration Documentation

## Overview

This document describes the comprehensive Security Information and Event Management (SIEM) integration for the DevSecOps project. The SIEM solution provides real-time security monitoring, threat detection, and incident response capabilities using the existing Loki/Grafana stack.

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Host System   │    │   Kubernetes    │    │   Monitoring    │
│                 │    │     Cluster     │    │     Stack       │
├─────────────────┤    ├─────────────────┤    ├─────────────────┤
│ auditd          │────│ Security        │────│ Loki            │
│ fail2ban        │    │ Namespace       │    │ Grafana         │
│ rsyslog         │    │                 │    │ Alloy           │
│ /var/log/       │    │ DaemonSet       │    │                 │
│ /etc/audit/     │    │ Webhook         │    │ SIEM Dashboards│
└─────────────────┘    │ Receiver        │    │ Alerting        │
                       └─────────────────┘    └─────────────────┘
```

## Components

### 1. System-Level Security Tools

#### auditd (Linux Audit Daemon)
- **Purpose**: System call and file access monitoring
- **Configuration**: `/etc/audit/rules.d/siem.rules`
- **Key Monitoring Areas**:
  - Authentication events
  - File integrity (critical system files)
  - Process execution
  - Network configuration changes
  - Package management activities

#### fail2ban (Intrusion Prevention)
- **Purpose**: Automatic IP blocking for suspicious activities
- **Configuration**: `/etc/fail2ban/jail.local`
- **Protected Services**:
  - SSH (port 22)
  - HTTP/HTTPS (nginx)
  - Custom webhook endpoint
- **Actions**: Temporary IP bans, email notifications

#### rsyslog (Enhanced Logging)
- **Purpose**: Structured security log routing
- **Configuration**: `/etc/rsyslog.d/90-siem.conf`
- **Log Categories**:
  - Authentication failures: `/var/log/security/auth-failures.log`
  - SSH activity: `/var/log/security/ssh.log`
  - Sudo commands: `/var/log/security/sudo.log`
  - Package changes: `/var/log/security/package-changes.log`
  - Fail2ban activity: `/var/log/security/fail2ban.log`

### 2. Kubernetes Security Components

#### Security Monitoring DaemonSet
- **Name**: `security-monitor`
- **Namespace**: `security`
- **Purpose**: Advanced security monitoring across all nodes
- **Features**:
  - Package change detection
  - Suspicious process monitoring
  - File integrity checking
  - Network connection monitoring
  - Real-time log streaming to Loki

#### Webhook Receiver
- **Service**: `webhook-receiver`
- **Purpose**: Secure Git webhook processing
- **Features**:
  - HMAC signature verification
  - Rate limiting (10 requests/minute)
  - Security event logging
  - Large commit batch detection
  - Secret exposure detection

### 3. Enhanced Alloy Configuration

#### Security Log Collection
- **Host Volume Mounts**: Access to `/var/log/security/`, `/var/log/audit/`
- **Log Processing**: Pattern matching, field extraction, labeling
- **Security Event Types**:
  - `auth_event`: Authentication-related logs
  - `audit_event`: System audit logs
  - `intrusion_prevention`: Fail2ban activities
  - `package_management`: APT/dpkg operations
  - `git_activity`: Webhook events

### 4. Grafana SIEM Dashboards

#### SIEM Security Overview
- **Security Events Summary**: Real-time event counts
- **Authentication Failures**: Failed login attempts
- **SSH Security**: Connection attempts and failures
- **Intrusion Prevention**: Fail2ban bans and blocks
- **Timeline Views**: Security events over time
- **Top Threats**: IP addresses with most failures

#### Audit Log Monitoring
- **System Call Monitoring**: execve, file access events
- **File Integrity**: Changes to critical system files
- **User Account Management**: passwd, shadow, group changes
- **Configuration Monitoring**: /etc/ directory changes

#### Network Security Monitoring
- **Blocked IPs**: Fail2ban banned addresses
- **SSH Analysis**: Connection patterns and attempts
- **Geographic Analysis**: Failed login source countries
- **Connection Monitoring**: Suspicious port listeners

## Installation and Setup

### Automated Setup (Recommended)

1. **Using setup.sh script**:
   ```bash
   ./setup.sh
   # Choose option 8: Deploy SIEM Stack
   # Or option 11: Full Production + SIEM Setup
   ```

2. **Using Ansible**:
   ```bash
   cd ansible
   ansible-playbook -i inventory playbooks/main.yml
   ```

### Manual Setup

1. **Install system tools**:
   ```bash
   sudo apt update
   sudo apt install -y auditd audispd-plugins fail2ban rsyslog
   ```

2. **Deploy Kubernetes components**:
   ```bash
   kubectl apply -f k8s/security-monitoring.yaml
   ```

3. **Configure system services**:
   ```bash
   sudo systemctl enable auditd fail2ban rsyslog
   sudo systemctl start auditd fail2ban rsyslog
   ```

## Access and Usage

### Dashboard Access
- **Grafana URL**: `http://grafana.{EXTERNAL_IP}.nip.io`
- **Credentials**: admin/admin123
- **SIEM Dashboards**:
  - SIEM Security Overview
  - Audit Log Monitoring  
  - Network Security Monitoring

### Webhook Configuration
- **Endpoint**: `http://webhook.{EXTERNAL_IP}.nip.io/webhook`
- **Secret**: `devsecops-webhook-secret`
- **Headers**: `X-Hub-Signature-256` (GitHub format)

### Log Analysis
- **Grafana Explore**: Use Loki datasource for ad-hoc queries
- **Example Queries**:
  ```logql
  # Authentication failures
  {job="auth-logs"} |~ "authentication failure"
  
  # Failed SSH logins
  {job="auth-logs"} |~ "Failed password"
  
  # Sudo commands
  {job="auth-logs"} |~ "sudo.*COMMAND"
  
  # Package installations
  {job="package-logs"} |~ "install"
  
  # Fail2ban bans
  {job="fail2ban-logs"} |~ "Ban"
  ```

## Security Features

### Real-Time Monitoring
- **SSH Login Attempts**: All successful/failed authentication attempts
- **System File Changes**: Critical configuration file modifications
- **Process Execution**: Monitoring of suspicious process patterns
- **Network Activity**: Unusual port listeners and connections
- **Package Management**: All software installations and updates

### Automated Response
- **Fail2ban Protection**: Automatic IP blocking for brute force attempts
- **Rate Limiting**: Webhook endpoint protection
- **Alerting**: Grafana alerts for threshold breaches
- **Log Retention**: 31-day security log retention

### Threat Detection
- **Brute Force Attacks**: SSH, HTTP authentication failures
- **Privilege Escalation**: Sudo command monitoring
- **File Integrity**: Unauthorized system file changes
- **Malicious Processes**: Suspicious command patterns
- **Data Exfiltration**: Large file transfers, unusual network activity

## Troubleshooting

### Common Issues

1. **Auditd not starting**:
   ```bash
   sudo systemctl status auditd
   sudo auditctl -l  # Check rules
   ```

2. **Fail2ban not blocking**:
   ```bash
   sudo fail2ban-client status
   sudo fail2ban-client status sshd
   ```

3. **Logs not appearing in Grafana**:
   ```bash
   kubectl logs -n monitoring -l app.kubernetes.io/name=alloy
   kubectl logs -n security -l app=security-monitor
   ```

### Log File Locations
- **Security Logs**: `/var/log/security/`
- **Audit Logs**: `/var/log/audit/audit.log`
- **System Logs**: `/var/log/auth.log`, `/var/log/syslog`
- **Application Logs**: Kubernetes pod logs

### Monitoring Commands
```bash
# Check security service status
sudo systemctl status auditd fail2ban rsyslog

# View real-time security logs
sudo tail -f /var/log/security/*.log

# Check fail2ban status
sudo fail2ban-client status sshd

# View audit rules
sudo auditctl -l

# Check banned IPs
sudo fail2ban-client status sshd

# Monitor package changes
sudo tail -f /var/log/security/package-changes.log
```

## Performance Considerations

### Resource Usage
- **Auditd**: Minimal CPU, moderate I/O
- **Fail2ban**: Low resource usage
- **Security Monitor DaemonSet**: 200Mi memory, 200m CPU per node
- **Log Storage**: ~500MB/day for typical workload

### Optimization Tips
1. **Tune auditd rules**: Remove unnecessary monitoring
2. **Adjust log retention**: Balance security needs with storage
3. **Configure fail2ban timeouts**: Prevent excessive blocking
4. **Monitor Loki storage**: Ensure adequate disk space

## Security Best Practices

### Access Control
- **Grafana Authentication**: Change default passwords
- **Webhook Security**: Use strong HMAC secrets
- **RBAC**: Proper Kubernetes role assignments
- **Network Policies**: Restrict pod-to-pod communication

### Log Management
- **Log Rotation**: Configure logrotate for security logs
- **Centralized Storage**: Export logs to external SIEM if needed
- **Backup**: Regular backup of security logs
- **Retention**: Comply with regulatory requirements

### Monitoring
- **Dashboard Review**: Regular security dashboard analysis
- **Alert Tuning**: Adjust thresholds to reduce false positives
- **Incident Response**: Document security incident procedures
- **Regular Updates**: Keep security tools updated

## Integration with External Systems

### SIEM Integration
- **Log Export**: Configure Alloy to forward logs to external SIEM
- **API Access**: Use Loki API for programmatic log access
- **Webhook Integration**: Connect to security orchestration platforms

### Compliance
- **Audit Trail**: Complete audit logging for compliance
- **Log Integrity**: Cryptographic log signing (optional)
- **Reporting**: Automated compliance reports from Grafana

This SIEM integration provides comprehensive security monitoring capabilities while maintaining the existing architecture and leveraging the Loki/Grafana stack for scalable, efficient security operations.
