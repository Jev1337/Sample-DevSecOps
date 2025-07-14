# SIEM Integration for DevSecOps Project

## Overview

This SIEM (Security Information and Event Management) implementation provides comprehensive security monitoring for the DevSecOps environment. It integrates with the existing Kubernetes cluster and monitoring stack to provide real-time security event detection, analysis, and alerting.

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   System Logs   │    │ Application Logs│    │  K8s Events     │
│   - SSH Auth    │    │   - Flask App   │    │   - Pod Events  │
│   - Auditd      │    │   - Jenkins     │    │   - Deployments │
│   - Fail2ban    │    │   - SonarQube   │    │   - Services    │
│   - Package Mgmt│    │   - Grafana     │    │   - Ingress     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │  Alloy Agent    │
                    │ (Log Collection │
                    │ & Processing)   │
                    └─────────────────┘
                                 │
                    ┌─────────────────┐    ┌─────────────────┐
                    │      Loki       │    │     Falco      │
                    │  (Log Storage)  │    │ (Runtime Sec.)  │
                    └─────────────────┘    └─────────────────┘
                                 │                       │
                    ┌─────────────────┐    ┌─────────────────┐
                    │    Grafana      │    │   Webhook       │
                    │ (Visualization) │    │   Receiver      │
                    │   Dashboards    │    │ (Git Events)    │
                    └─────────────────┘    └─────────────────┘
```

## Components

### 1. System Hardening
- **Auditd**: System call auditing and file access monitoring
- **Fail2ban**: Intrusion prevention system for SSH and web services
- **APT Monitoring**: Package installation/removal tracking

### 2. Runtime Security
- **Falco**: Kubernetes runtime security monitoring
- **Custom Rules**: DevSecOps-specific security rules
- **eBPF Driver**: High-performance kernel-level monitoring

### 3. Log Collection and Processing
- **Enhanced Alloy**: Advanced log collection with security parsing
- **Multi-source Collection**: System logs, application logs, K8s events
- **Real-time Processing**: Security event enrichment and classification

### 4. Security Analytics
- **SIEM Dashboards**: Comprehensive security visualization
- **Alert Correlation**: Multi-source event correlation
- **Threat Detection**: Pattern-based security threat identification

### 5. Git Security Monitoring
- **Webhook Receiver**: Secure Git event processing
- **Code Change Analysis**: Security risk assessment for commits
- **Behavioral Analysis**: User activity anomaly detection

## Security Events Monitored

### Authentication & Access
- SSH login attempts (successful/failed)
- Application authentication failures
- Privilege escalation attempts
- User behavior anomalies

### System Security
- File system access to sensitive files
- System call monitoring (via auditd)
- Package management activities
- Network connection monitoring

### Application Security
- HTTP error codes (4xx, 5xx)
- Security threats in logs (XSS, injection, etc.)
- Container runtime security events
- Kubernetes security events

### DevOps Security
- Git commit analysis for security risks
- CI/CD pipeline security events
- Container image security scanning
- Infrastructure changes

## Installation and Setup

### Automatic Installation
Run the full SIEM setup using the enhanced setup script:

```bash
./setup.sh
# Choose option 13: Full SIEM Setup
```

### Manual Installation Steps

1. **Deploy Base Infrastructure**
   ```bash
   ./setup.sh
   # Options 3-7: Setup MicroK8s through Flask App
   ```

2. **Deploy SIEM Stack**
   ```bash
   ./setup.sh
   # Option 8: Deploy SIEM Security Stack
   ```

3. **Configure External Access**
   ```bash
   ./setup.sh
   # Option 10: Configure SIEM External Access
   ```

4. **Install Dashboards**
   ```bash
   ./setup.sh
   # Option 11: Install SIEM Dashboards
   ```

## Configuration

### Alloy SIEM Configuration
Location: `helm/alloy/values.yaml`

Key features:
- Multi-source log collection (system, application, K8s)
- Security event parsing and enrichment
- Real-time threat detection
- Structured logging with security labels

### Falco Runtime Security
Location: `helm/falco/values.yaml`

Custom rules for:
- Container drift detection
- Privilege escalation monitoring
- Network security events
- Package management tracking
- Container escape attempts

### System Hardening
Configurations in `siem/configs/`:
- `auditd.rules`: System audit rules
- `fail2ban-jail.conf`: Intrusion prevention
- `apt-security-hook.sh`: Package monitoring

## Dashboards

### SIEM Security Dashboard
- **File**: `siem/dashboards/siem-security-dashboard.json`
- **Features**:
  - Critical security events overview
  - Authentication failure tracking
  - Security events timeline
  - Top security event types
  - Real-time critical event logs

### System Audit Dashboard
- **File**: `siem/dashboards/system-audit-dashboard.json`
- **Features**:
  - System audit events
  - Package management activities
  - SSH authentication monitoring
  - Source IP analysis
  - Recent audit and package events

## Access URLs

After deployment with external access configured:

### Core Services
- **Jenkins**: `http://jenkins.<EXTERNAL_IP>.nip.io`
- **SonarQube**: `http://sonarqube.<EXTERNAL_IP>.nip.io`
- **Grafana**: `http://grafana.<EXTERNAL_IP>.nip.io`
- **Flask App**: `http://app.<EXTERNAL_IP>.nip.io`

### SIEM Services
- **Webhook Receiver**: `http://webhook.<EXTERNAL_IP>.nip.io/webhook`
- **Security Dashboards**: Available in Grafana
- **Falco Logs**: `kubectl logs -f daemonset/falco -n security`

## Security Features

### 1. SSH Security
- **Monitoring**: All SSH login attempts logged and analyzed
- **Protection**: Fail2ban automatic IP blocking
- **Alerts**: Real-time dashboard notifications

### 2. Package Security
- **Tracking**: All apt/dpkg operations logged
- **Analysis**: Security-sensitive package detection
- **Audit Trail**: Complete package management history

### 3. Application Security
- **Log Analysis**: Real-time parsing of application logs
- **Threat Detection**: Pattern-based security threat identification
- **HTTP Monitoring**: Status code analysis and error tracking

### 4. Git Security
- **Webhook Analysis**: Secure Git event processing
- **Risk Assessment**: Commit and file change analysis
- **Behavioral Monitoring**: User activity anomaly detection

### 5. Runtime Security
- **Container Monitoring**: Falco runtime security rules
- **System Call Auditing**: Auditd comprehensive monitoring
- **Network Security**: Connection monitoring and analysis

## Alerting and Response

### Automated Responses
- **Fail2ban**: Automatic IP blocking for failed authentication
- **Audit Logging**: Persistent security event storage
- **Real-time Dashboards**: Immediate visualization of threats

### Manual Response
- **Log Analysis**: Comprehensive log search via Grafana
- **Event Correlation**: Multi-source event timeline
- **Incident Investigation**: Detailed security event tracking

## Maintenance

### Log Retention
- **Loki**: Configured for efficient log storage
- **Rotation**: Automatic log file rotation
- **Cleanup**: Scheduled cleanup of old events

### Updates
- **Falco Rules**: Regular security rule updates
- **System Hardening**: Periodic configuration reviews
- **Dashboard Updates**: Enhanced visualization features

### Monitoring
- **Service Health**: Kubernetes readiness probes
- **Performance**: Resource usage monitoring
- **Availability**: Service uptime tracking

## Troubleshooting

### Common Issues

1. **Alloy Not Collecting System Logs**
   - Check volume mounts in DaemonSet
   - Verify file permissions on /var/log
   - Ensure privileged security context

2. **Falco Not Starting**
   - Check eBPF driver compatibility
   - Verify kernel version requirements
   - Review security contexts and RBAC

3. **Webhook Not Receiving Events**
   - Verify external access configuration
   - Check LoadBalancer and Ingress status
   - Test webhook endpoint connectivity

4. **Dashboards Not Loading**
   - Verify Loki data source configuration
   - Check dashboard import process
   - Review Grafana logs for errors

### Log Locations
- **System Logs**: `/var/log/auth.log`, `/var/log/syslog`
- **Audit Logs**: `/var/log/audit/audit.log`
- **Application Logs**: Kubernetes pod logs
- **SIEM Logs**: Loki via Grafana

## Security Best Practices

1. **Regular Updates**: Keep all components updated
2. **Access Control**: Restrict dashboard access appropriately
3. **Secret Management**: Secure webhook secrets and credentials
4. **Network Security**: Use TLS for external access
5. **Backup**: Regular backup of configuration and logs
6. **Monitoring**: Continuous monitoring of SIEM components

## Advanced Configuration

### Custom Falco Rules
Add custom security rules in `helm/falco/values.yaml`:

```yaml
customRules:
  custom-rules.yaml: |-
    - rule: Custom Security Rule
      desc: Description of the rule
      condition: condition expression
      output: output format
      priority: HIGH
```

### Alloy Log Processing
Enhance log processing in `helm/alloy/values.yaml`:

```yaml
loki.process "custom_processing" {
  stage.regex {
    expression = "custom regex pattern"
  }
  stage.labels {
    values = {
      custom_label = "value"
    }
  }
}
```

### Custom Dashboards
Create additional dashboards by:
1. Designing in Grafana UI
2. Exporting JSON configuration
3. Adding to `siem/dashboards/`
4. Updating installation scripts

## Support and Contributing

For issues, enhancements, or questions:
1. Review troubleshooting section
2. Check Kubernetes and service logs
3. Verify configuration against documentation
4. Test with minimal configuration first

This SIEM implementation provides a solid foundation for security monitoring in DevSecOps environments and can be extended based on specific security requirements.
