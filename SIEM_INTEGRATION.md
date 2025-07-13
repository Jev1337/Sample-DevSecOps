# SIEM Integration Summary

## 🛡️ What's Been Added

### 📁 Files Created:
1. **`setup-siem.sh`** - Standalone SIEM setup script
2. **`siem/alloy-siem-config.alloy`** - Enhanced Alloy configuration
3. **`monitoring/grafana/dashboards/siem-security.json`** - Security dashboard
4. **`ansible/playbooks/siem.yml`** - SIEM host configuration playbook
5. **`siem/webhook-service.yaml`** - Git webhook service definition

### 🔧 Files Modified:
1. **`setup.sh`** - Enhanced with SIEM webhook deployment
2. **`cleanup.sh`** - Added SIEM cleanup options
3. **`helm/alloy/values.yaml`** - Enhanced with SIEM log collection
4. **`README.md`** - Updated with comprehensive SIEM documentation

## 🚀 How to Use

### Step 1: Deploy Monitoring with SIEM
```bash
./setup.sh
# Choose option 6: Deploy Monitoring Stack with SIEM
```

### Step 2: Configure Host SIEM Monitoring
```bash
# Option A: Use the standalone script (Recommended)
chmod +x setup-siem.sh
./setup-siem.sh

# Option B: Manual Ansible
cd ansible
ansible-playbook -i inventory playbooks/siem.yml --ask-become-pass
```

### Step 3: Configure Git Webhooks
- Repository Settings → Webhooks → Add webhook
- URL: `http://webhook.{YOUR_IP}.nip.io/webhook`
- Content-Type: `application/json`
- Events: Push events

### Step 4: Access SIEM Dashboard
- Navigate to Grafana: `http://grafana.{YOUR_IP}.nip.io`
- Find "SIEM Security Dashboard"
- Monitor security events in real-time

## 🔍 What Gets Monitored

### 📊 Log Sources:
- **SSH Authentication** (`/var/log/auth.log`)
- **System Events** (`/var/log/syslog`)
- **Audit Logs** (`/var/log/audit/audit.log`)
- **Kernel Events** (`/var/log/kern.log`)
- **Git Webhooks** (Port 9999)
- **Container Logs** (Kubernetes pods)

### 🚨 Security Events:
- SSH login attempts (successful/failed)
- Invalid user attempts
- Source IP tracking
- Git commit monitoring
- System security events
- Container security events

### 📈 Dashboard Panels:
- SSH/Auth Events Distribution
- Authentication Timeline
- Top Failed Login Sources
- Security Events by Severity
- Git Activity Monitoring
- Critical Events Log Stream

## 🛠️ Architecture

```
Host System Logs → Alloy Collector → Loki Storage → Grafana Dashboard
Git Webhooks    → Webhook Receiver →     ↑              ↑
Container Logs  →       ↑          →     ↑              ↑
```

## 🔐 Security Features

- **fail2ban**: Automatic IP blocking after failed attempts
- **auditd**: System access auditing
- **logwatch**: Daily log analysis reports
- **chkrootkit**: Rootkit detection
- **Log rotation**: Automated cleanup and archiving
- **Real-time monitoring**: Live security event streaming

## 📝 Notes

- The setup.sh script deploys the webhook service automatically
- Host monitoring requires separate Ansible setup for security reasons
- All configuration is ready for production use
- SIEM data integrates with existing Loki/Grafana stack
- No additional infrastructure components required
