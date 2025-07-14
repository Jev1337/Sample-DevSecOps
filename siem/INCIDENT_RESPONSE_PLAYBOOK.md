# SIEM Incident Response Playbook

## Overview
This playbook provides step-by-step guidance for responding to security incidents detected by the SIEM system.

## Alert Categories and Response Procedures

### 🔐 Authentication Security Incidents

#### High Failed SSH Attempts
**Alert:** `HighFailedSSHAttempts`
**Severity:** Critical

**Immediate Actions:**
1. Check source IP addresses in Grafana dashboard
2. Verify if legitimate user is experiencing issues
3. Check for geographic anomalies

**Investigation Steps:**
```bash
# Check recent SSH attempts
sudo grep "Failed password" /var/log/auth.log | tail -20

# Check source IP details
whois <suspicious_ip>

# Review successful logins after failures
sudo grep "Accepted password" /var/log/auth.log | grep <suspicious_ip>
```

**Containment:**
```bash
# Block suspicious IP with fail2ban
sudo fail2ban-client set sshd banip <suspicious_ip>

# Check current banned IPs
sudo fail2ban-client status sshd
```

**Recovery:**
- Review and strengthen SSH configuration
- Consider implementing key-based authentication
- Update fail2ban thresholds if needed

#### Root Login Attempt
**Alert:** `RootLoginAttempt`
**Severity:** High

**Immediate Actions:**
1. Identify source IP and user attempt details
2. Verify if this was an authorized administrative action
3. Check for privilege escalation attempts

**Investigation Steps:**
```bash
# Check root login attempts
sudo grep "root" /var/log/auth.log | tail -10

# Review sudo usage
sudo grep "sudo" /var/log/auth.log | tail -10
```

**Containment:**
- Disable direct root login if not already done
- Implement sudo-only access for administrative tasks

### 🛡️ Runtime Security Incidents

#### Suspicious Process Execution
**Alert:** `SuspiciousProcessExecution`
**Severity:** High

**Immediate Actions:**
1. Check Falco logs for specific process details
2. Identify affected containers/nodes
3. Assess potential impact

**Investigation Steps:**
```bash
# Check Falco logs
microk8s kubectl logs -n security daemonset/falco --tail=50

# Check running processes in suspicious containers
microk8s kubectl exec -n <namespace> <pod> -- ps aux

# Review container security context
microk8s kubectl describe pod <suspicious_pod> -n <namespace>
```

**Containment:**
```bash
# Isolate suspicious pod
microk8s kubectl delete pod <suspicious_pod> -n <namespace>

# Scale down deployment if needed
microk8s kubectl scale deployment <deployment> --replicas=0 -n <namespace>
```

#### Privilege Escalation
**Alert:** `PrivilegeEscalation`
**Severity:** Critical

**Immediate Actions:**
1. Immediately isolate affected container/node
2. Preserve evidence for forensic analysis
3. Check for lateral movement

**Investigation Steps:**
```bash
# Check audit logs for privilege changes
sudo grep "type=USER_AUTH\|type=CRED_ACQ" /var/log/audit/audit.log

# Review container capabilities
microk8s kubectl get pod <pod> -o yaml | grep -A 10 securityContext

# Check for suspicious network connections
netstat -tulpn | grep ESTABLISHED
```

**Containment:**
- Immediately terminate affected workloads
- Review and harden security policies
- Conduct full security audit

### 🌐 Network Security Incidents

#### Unauthorized Network Connection
**Alert:** `UnauthorizedNetworkConnection`
**Severity:** Medium

**Investigation Steps:**
```bash
# Check network connections
sudo netstat -tulpn | grep <suspicious_port>

# Review iptables rules
sudo iptables -L -n

# Check Kubernetes network policies
microk8s kubectl get networkpolicies --all-namespaces
```

**Containment:**
```bash
# Block suspicious network traffic
sudo iptables -A INPUT -s <suspicious_ip> -j DROP

# Update network policies
microk8s kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-suspicious-traffic
  namespace: <affected_namespace>
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
  ingress: []
  egress: []
EOF
```

### 📁 File System Security Incidents

#### Sensitive File Access
**Alert:** `SensitiveFileAccess`
**Severity:** High

**Investigation Steps:**
```bash
# Check audit logs for file access
sudo ausearch -f /etc/passwd -f /etc/shadow -ts recent

# Review recent file modifications
find /etc /root /home -type f -mtime -1 -ls

# Check for unauthorized SUID files
find / -type f -perm -4000 -ls 2>/dev/null
```

**Containment:**
- Review and restrict file permissions
- Implement additional monitoring on sensitive files
- Consider file integrity monitoring

### 📦 Package Management Security

#### Unauthorized Package Installation
**Alert:** `UnauthorizedPackageInstallation`
**Severity:** Medium

**Investigation Steps:**
```bash
# Check recent package installations
grep "install" /var/log/apt/history.log | tail -10

# Review package sources
cat /etc/apt/sources.list
ls -la /etc/apt/sources.list.d/

# Check for suspicious packages
dpkg -l | grep -E "(exploit|hack|backdoor)"
```

**Containment:**
- Review change management processes
- Implement package installation controls
- Audit installed packages for security

### 🚨 Application Security Incidents

#### Security Vulnerability in Commit
**Alert:** `SecurityVulnerabilityInCommit`
**Severity:** High

**Investigation Steps:**
```bash
# Check webhook logs
microk8s kubectl logs -n flask-app deployment/webhook-receiver

# Review recent commits
git log --oneline -10

# Scan for secrets in code
grep -r -E "(password|secret|key|token)" . --include="*.py" --include="*.js" --include="*.yaml"
```

**Containment:**
- Immediately review and remove sensitive data
- Rotate any exposed credentials
- Update security scanning in CI/CD pipeline

## General Incident Response Procedures

### 1. Initial Assessment (0-15 minutes)
- [ ] Acknowledge the alert
- [ ] Determine severity and scope
- [ ] Activate incident response team if needed
- [ ] Begin evidence preservation

### 2. Containment (15-60 minutes)
- [ ] Isolate affected systems
- [ ] Prevent lateral movement
- [ ] Preserve system state for analysis
- [ ] Document all actions taken

### 3. Investigation (1-4 hours)
- [ ] Analyze logs and evidence
- [ ] Determine attack vectors
- [ ] Assess impact and scope
- [ ] Identify indicators of compromise (IoCs)

### 4. Eradication (2-8 hours)
- [ ] Remove malicious artifacts
- [ ] Patch vulnerabilities
- [ ] Update security controls
- [ ] Verify threat elimination

### 5. Recovery (4-24 hours)
- [ ] Restore systems from clean backups
- [ ] Implement additional monitoring
- [ ] Gradually restore services
- [ ] Monitor for recurring issues

### 6. Lessons Learned (1-2 weeks)
- [ ] Conduct post-incident review
- [ ] Update procedures and controls
- [ ] Improve detection capabilities
- [ ] Provide additional training

## Emergency Contacts

### Internal Team
- **Security Team Lead:** security-lead@company.com
- **DevOps Team:** devops@company.com
- **IT Support:** support@company.com
- **Management:** management@company.com

### External Resources
- **Cloud Provider Support:** [Provider Support Contact]
- **Security Vendor:** [Security Vendor Contact]
- **Legal/Compliance:** legal@company.com

## Key Commands Reference

### System Information
```bash
# Check system status
systemctl status
df -h
free -m
uptime

# Check running processes
ps aux | grep -E "(suspicious|malware|exploit)"

# Check network connections
netstat -tulpn
ss -tulpn
```

### Kubernetes Commands
```bash
# Check cluster status
microk8s kubectl get nodes
microk8s kubectl get pods --all-namespaces

# Check security events
microk8s kubectl get events --all-namespaces --sort-by='.lastTimestamp'

# Check resource usage
microk8s kubectl top pods --all-namespaces
microk8s kubectl top nodes
```

### Log Analysis
```bash
# Check system logs
journalctl -xe
tail -f /var/log/syslog

# Check authentication logs
tail -f /var/log/auth.log

# Check audit logs
tail -f /var/log/audit/audit.log
```

### Security Tools
```bash
# Fail2ban status
sudo fail2ban-client status

# Check Falco events
microk8s kubectl logs -n security daemonset/falco --follow

# Loki query examples
curl -G -s "http://loki.local/loki/api/v1/query" \
  --data-urlencode 'query={job="alloy/logs", level="error"}' \
  --data-urlencode 'time=now'
```

## Reporting Templates

### Initial Incident Report
```
Incident ID: INC-YYYY-MMDD-XXX
Detection Time: [UTC Timestamp]
Reporter: [Name/System]
Severity: [Critical/High/Medium/Low]
Category: [Authentication/Runtime/Network/File/Package/Application]
Description: [Brief description of the incident]
Affected Systems: [List of affected systems/services]
Initial Actions Taken: [Summary of immediate response]
Status: [Open/Investigating/Contained/Resolved]
```

### Final Incident Report
```
Incident Summary:
- Detection Time: [UTC Timestamp]
- Resolution Time: [UTC Timestamp]
- Duration: [Total incident duration]
- Root Cause: [Primary cause of the incident]
- Impact: [Description of business/technical impact]
- Timeline: [Key events and response actions]
- Lessons Learned: [What was learned from this incident]
- Improvements: [Recommended improvements to prevent recurrence]
```

## Compliance Considerations

### Data Handling
- Ensure all incident data is handled according to privacy regulations
- Maintain audit trails of all investigation activities
- Preserve evidence according to legal requirements

### Notification Requirements
- Notify relevant stakeholders within required timeframes
- Consider regulatory notification requirements
- Document all notifications sent

### Documentation
- Maintain detailed logs of all incident response activities
- Ensure documentation meets compliance requirements
- Regularly review and update procedures

---

**Note:** This playbook should be regularly reviewed and updated based on new threats, lessons learned, and changes to the infrastructure. Conduct regular tabletop exercises to ensure team familiarity with procedures.
