# SIEM Quick Reference

## 🚀 Quick Setup Commands

```bash
# Deploy SIEM stack using setup.sh
./setup.sh
# Choose option 8: Deploy SIEM Stack
# Or option 11: Full Production + SIEM Setup

# Manual deployment
kubectl apply -f k8s/security-monitoring.yaml

# Check SIEM status
kubectl get pods -n security
sudo systemctl status auditd fail2ban rsyslog
```

## 🔗 Access URLs

- **Grafana SIEM Dashboards**: `http://grafana.{EXTERNAL_IP}.nip.io`
- **Webhook Endpoint**: `http://webhook.{EXTERNAL_IP}.nip.io/webhook`
- **Credentials**: admin/admin123

## 📊 Key Dashboards

1. **SIEM Security Overview** - Real-time security metrics
2. **Audit Log Monitoring** - System call and file access tracking  
3. **Network Security Monitoring** - SSH attempts and blocked IPs

## 🔍 Essential LogQL Queries

```logql
# Failed SSH logins
{job="auth-logs"} |~ "Failed password"

# Sudo commands executed
{job="auth-logs"} |~ "sudo.*COMMAND"

# Package installations
{job="package-logs"} |~ "install|upgrade"

# Fail2ban IP bans
{job="fail2ban-logs"} |~ "Ban"

# Authentication failures
{job="auth-logs"} |~ "authentication failure"

# File integrity violations
{job="audit-logs"} |~ "/etc/|/bin/|/sbin/"

# Git webhook activity
{job="webhook-security"} |~ "git_webhook"
```

## 🛡️ Security Monitoring Areas

### System Level
- ✅ SSH login attempts (success/failure)
- ✅ Authentication events
- ✅ File integrity monitoring
- ✅ Package management tracking
- ✅ System call monitoring (auditd)

### Network Level  
- ✅ Intrusion prevention (fail2ban)
- ✅ Suspicious port listeners
- ✅ Connection attempt analysis
- ✅ Geographic threat analysis

### Application Level
- ✅ Git webhook security
- ✅ Jenkins CI/CD pipeline activity
- ✅ SonarQube security analysis
- ✅ Container security events

## 🚨 Common Security Events

| Event Type | Log Source | Severity | Action |
|------------|------------|----------|---------|
| Failed SSH Login | auth-logs | Medium | Monitor threshold |
| Multiple Auth Failures | auth-logs | High | Auto-ban (fail2ban) |
| Sudo Command Execution | auth-logs | Low | Log and audit |
| Critical File Change | audit-logs | High | Immediate investigation |
| Package Installation | package-logs | Medium | Review and approve |
| Webhook Signature Failure | webhook-security | High | Block and investigate |

## 📋 Troubleshooting Commands

```bash
# Check security services
sudo systemctl status auditd fail2ban rsyslog

# View real-time security logs
sudo tail -f /var/log/security/*.log

# Check fail2ban banned IPs
sudo fail2ban-client status sshd

# View audit rules
sudo auditctl -l

# Test webhook endpoint
curl -X POST http://webhook.{EXTERNAL_IP}.nip.io/webhook \
  -H "Content-Type: application/json" \
  -d '{"test": "data"}'

# Check Kubernetes SIEM components
kubectl get all -n security
kubectl logs -n security -l app=security-monitor
kubectl logs -n security -l app=webhook-receiver
```

## 🔧 Configuration Files

| Component | Configuration File | Purpose |
|-----------|-------------------|---------|
| auditd | `/etc/audit/rules.d/siem.rules` | System monitoring rules |
| fail2ban | `/etc/fail2ban/jail.local` | Intrusion prevention |
| rsyslog | `/etc/rsyslog.d/90-siem.conf` | Log routing |
| Alloy | `helm/alloy/values-siem.yaml` | Log collection |
| Grafana | SIEM dashboard ConfigMaps | Visualization |

## 📈 Performance Metrics

| Component | CPU | Memory | Storage |
|-----------|-----|--------|---------|
| auditd | ~50m | ~100Mi | ~100MB/day |
| fail2ban | ~10m | ~50Mi | ~10MB/day |
| Security Monitor | 200m | 256Mi | - |
| Webhook Receiver | 100m | 128Mi | - |
| Security Logs | - | - | ~500MB/day |

## 🛠️ Maintenance Tasks

### Daily
- [ ] Review SIEM dashboards
- [ ] Check failed authentication attempts
- [ ] Verify fail2ban ban list

### Weekly  
- [ ] Analyze security trends
- [ ] Review audit log violations
- [ ] Update threat indicators

### Monthly
- [ ] Security log retention cleanup
- [ ] Review and tune alert thresholds
- [ ] Update security signatures
- [ ] Perform security assessment

## 🚨 Incident Response

### High Severity Events
1. **Multiple Failed Logins**: Check source IP, verify legitimacy
2. **Critical File Changes**: Investigate unauthorized modifications
3. **Suspicious Processes**: Analyze running processes and network connections
4. **Webhook Attacks**: Review Git activity and block malicious IPs

### Response Workflow
1. **Detection**: SIEM dashboard alert
2. **Investigation**: Grafana log analysis
3. **Containment**: Fail2ban blocking, manual IP blacklist
4. **Recovery**: System restoration, configuration fixes
5. **Documentation**: Incident logging, lessons learned

## 📞 Emergency Contacts

- **Security Team**: [Your security team contact]
- **System Admin**: [System administrator contact]  
- **DevOps Team**: [DevOps team contact]

## 🔗 Useful Resources

- [SIEM Documentation](./SIEM_DOCUMENTATION.md)
- [Grafana Documentation](https://grafana.com/docs/)
- [Loki LogQL Documentation](https://grafana.com/docs/loki/latest/logql/)
- [Fail2ban Documentation](https://www.fail2ban.org/wiki/index.php/Main_Page)
- [Linux Audit Documentation](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/security_guide/chap-system_auditing)
