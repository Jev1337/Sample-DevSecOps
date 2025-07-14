# 🛡️ SIEM Documentation - Security Information and Event Management

[![Security](https://img.shields.io/badge/Security-SIEM-red)](https://en.wikipedia.org/wiki/Security_information_and_event_management)
[![Grafana](https://img.shields.io/badge/Grafana-Dashboard-orange)](https://grafana.com/)
[![Loki](https://img.shields.io/badge/Loki-Logs-blue)](https://grafana.com/oss/loki/)
[![Real-time](https://img.shields.io/badge/Monitoring-Real--time-green)](#real-time-monitoring)

## 📋 Table des Matières

- [🎯 Vue d'ensemble SIEM](#-vue-densemble-siem)
- [🔍 Sources de Données](#-sources-de-données)
- [📊 Dashboards et Visualisations](#-dashboards-et-visualisations)
- [🚨 Alertes et Détection](#-alertes-et-détection)
- [🔧 Configuration](#-configuration)
- [📈 Métriques Surveillées](#-métriques-surveillées)
- [🛠️ Troubleshooting](#️-troubleshooting)

---

## 🎯 Vue d'ensemble SIEM

Le système SIEM (Security Information and Event Management) intégré dans cette plateforme DevSecOps fournit une surveillance continue et en temps réel des événements de sécurité. Il collecte, analyse et corrèle les données de sécurité provenant de multiples sources pour détecter les menaces et les anomalies.

### 🎪 Fonctionnalités Principales

| Fonction | Description | Technologie |
|----------|-------------|-------------|
| **📊 Collecte Logs** | Centralisation des logs système, application et sécurité | Grafana Alloy |
| **🔍 Analyse Temps Réel** | Détection d'anomalies et patterns suspects | Loki Queries |
| **📈 Visualisation** | Dashboards interactifs pour monitoring sécurité | Grafana |
| **🚨 Alertes** | Notifications automatiques sur événements critiques | Grafana Alerts |
| **🔗 Intégration Git** | Surveillance des changements de code via webhooks | Flask Webhook Receiver |
| **📝 Audit Trail** | Traçabilité complète des événements système | System Logs + Audit |

### 🏗️ Architecture SIEM

```mermaid
graph TB
    subgraph "Sources de Données"
        AUTH[Auth Logs<br/>/var/log/auth.log]
        KERN[Kernel Logs<br/>/var/log/kern.log]
        PKG[Package Logs<br/>/var/log/dpkg.log]
        GIT[Git Events<br/>Webhook Receiver]
        APP[Application Logs<br/>Container Logs]
        AUDIT[K8s Audit Logs<br/>Security Events]
    end
    
    subgraph "Collecte et Traitement"
        ALLOY[Grafana Alloy<br/>Log Collector]
        WEBHOOK[Webhook Receiver<br/>Git Events API]
    end
    
    subgraph "Stockage et Index"
        LOKI[Loki<br/>Log Storage]
    end
    
    subgraph "Analyse et Visualisation"
        GRAFANA[Grafana<br/>SIEM Dashboard]
        ALERTS[Alert Manager<br/>Notifications]
    end
    
    AUTH --> ALLOY
    KERN --> ALLOY
    PKG --> ALLOY
    GIT --> WEBHOOK
    APP --> ALLOY
    AUDIT --> ALLOY
    
    ALLOY --> LOKI
    WEBHOOK --> LOKI
    
    LOKI --> GRAFANA
    GRAFANA --> ALERTS
```

---

## 🔍 Sources de Données

### 📊 Logs Système

| Source | Localisation | Type d'Événements | Fréquence |
|--------|-------------|-------------------|-----------|
| **Authentication** | `/var/log/auth.log` | SSH, sudo, authentification | Temps réel |
| **Kernel** | `/var/log/kern.log` | Événements noyau, matériel | Temps réel |
| **Package Management** | `/var/log/dpkg.log` | Installation/suppression packages | En temps réel |
| **System Journal** | `journalctl` | Services système, démarrage | Temps réel |

### 🐳 Logs Applications

| Source | Namespace | Description | Format |
|--------|-----------|-------------|--------|
| **Flask App** | `flask-app` | API requests, erreurs, métriques | JSON structuré |
| **Jenkins** | `jenkins` | Builds, déploiements, pipeline events | Text + JSON |
| **SonarQube** | `sonarqube` | Analyses sécurité, qualité code | Text |
| **Grafana** | `monitoring` | Dashboards, alertes, utilisateurs | JSON |

### 🔗 Événements Git/SCM

```python
# Webhook receiver capture
{
    "event_type": "push",
    "repository": "sample-devsecops",
    "author": "developer@company.com",
    "commit_id": "abc123...",
    "message": "Fix security vulnerability",
    "timestamp": "2025-01-14T10:30:00Z",
    "files_changed": ["app.py", "requirements.txt"]
}
```

### 🔐 Logs de Sécurité Kubernetes

```yaml
# K8s Audit Policy (siem/configs/audit-policy.yaml)
apiVersion: audit.k8s.io/v1
kind: Policy
rules:
- level: Metadata
  namespaces: ["default", "flask-app", "jenkins"]
  resources:
  - group: ""
    resources: ["secrets", "configmaps"]
- level: Request
  namespaces: ["kube-system"]
  verbs: ["create", "update", "delete"]
```

---

## 📊 Dashboards et Visualisations

### 🛡️ Dashboard SIEM Principal

**Localisation :** `monitoring/grafana/dashboards/siem-real-security.json`

**Panels Principaux :**

1. **🔐 Authentification & Accès**
   ```logql
   # Connexions SSH réussies
   {job="system-auth"} |= "Accepted" | json
   
   # Échecs d'authentification
   {job="system-auth"} |= "Failed" | json
   ```

2. **📦 Changements Système**
   ```logql
   # Installations de packages
   {job="package-install"} |= "install" | json
   
   # Modifications configuration
   {job="system-audit"} |= "SYSCALL" | json
   ```

3. **🔄 Activité Git/SCM**
   ```logql
   # Événements webhook
   {job="webhook-receiver"} | json
   
   # Pushs de code
   {job="webhook-receiver"} |= "push" | json
   ```

4. **🚨 Événements Critiques**
   ```logql
   # Événements de sécurité
   {job=~"system-.*"} |= "ERROR" or "CRITICAL" or "FAILED"
   ```

### 📈 Métriques Temps Réel

**Widget 1 - Taux d'Authentification :**
```promql
rate({job="system-auth"}[5m])
```

**Widget 2 - Activité Git :**
```promql
sum by (repository) (rate({job="webhook-receiver"}[1h]))
```

**Widget 3 - Événements Système :**
```promql
rate({job=~"system-.*"}[10m])
```

### 🎨 Visualisations Personnalisées

**Géolocalisation IP (si configured) :**
- Carte mondiale des connexions SSH
- Top pays de connexion
- Adresses IP suspectes

**Timeline des Événements :**
- Chronologie des événements de sécurité
- Corrélation entre événements
- Patterns d'attaque détectés

---

## 🚨 Alertes et Détection

### ⚠️ Règles d'Alerte Configurées

**1. Échecs d'Authentification Multiples**
```yaml
alert: MultipleAuthFailures
expr: rate({job="system-auth"} |= "Failed"[5m]) > 0.1
for: 2m
annotations:
  summary: "Détection de tentatives d'authentification suspectes"
  description: "Plus de 6 échecs d'authentification en 5 minutes"
```

**2. Installation de Packages Non Autorisée**
```yaml
alert: UnauthorizedPackageInstall
expr: rate({job="package-install"}[1h]) > 0
for: 0s
annotations:
  summary: "Installation de package système détectée"
  description: "Un package a été installé en dehors des heures autorisées"
```

**3. Activité Git Anormale**
```yaml
alert: AbnormalGitActivity
expr: rate({job="webhook-receiver"}[1h]) > 5
for: 10m
annotations:
  summary: "Activité Git intensive détectée"
  description: "Plus de 5 pushs par heure détectés"
```

### 📧 Notifications

**Channels Supportés :**
- 📧 Email (SMTP)
- 💬 Slack
- 🔔 Discord
- 📱 PagerDuty
- 🔗 Webhook custom

**Configuration Slack :**
```yaml
# grafana/alerting/notification-channels.yaml
apiVersion: 1
notifiers:
- name: slack-security
  type: slack
  settings:
    url: "YOUR_SLACK_WEBHOOK_URL"
    channel: "#security-alerts"
    title: "🚨 SIEM Alert - {{ .GroupLabels.alertname }}"
```

---

## 🔧 Configuration

### 🚀 Déploiement SIEM

**Déploiement Automatique :**
```bash
# Via setup script
./setup.sh
# Choisir option 5) Deploy SIEM Security Monitoring

# Ou via Ansible directement
cd ansible
ansible-playbook siem.yml
```

**Déploiement Manuel :**
```bash
# 1. Déployer webhook receiver
kubectl apply -f webhook/webhook-deployment.yaml

# 2. Configurer Alloy pour SIEM
helm upgrade alloy grafana/alloy -n monitoring -f helm/alloy/values.yaml

# 3. Importer dashboard SIEM
# Via Grafana UI ou API
```

### ⚙️ Configuration Avancée

**1. Modification Sources de Logs**

Éditer `helm/alloy/values.yaml` :
```yaml
alloy:
  configMap:
    content: |
      // Ajouter nouvelles sources
      loki.source.file "custom_logs" {
        targets = [
          {__path__ = "/var/log/custom-app.log", job = "custom-app"},
        ]
        forward_to = [loki.write.grafana_loki.receiver]
      }
```

**2. Personnalisation Dashboard**

```bash
# Exporter dashboard existant
curl -X GET http://admin:admin123@grafana.local/api/dashboards/uid/siem-dashboard

# Modifier et réimporter
curl -X POST http://admin:admin123@grafana.local/api/dashboards/db \
  -H "Content-Type: application/json" \
  -d @custom-siem-dashboard.json
```

### 🔐 Configuration Webhooks Git

**GitHub :**
```bash
# Repository → Settings → Webhooks → Add webhook
Payload URL: http://webhook.YOUR_IP.nip.io/webhook
Content type: application/json
Events: Push events, Pull requests
```

**GitLab :**
```bash
# Project → Settings → Integrations
URL: http://webhook.YOUR_IP.nip.io/webhook
Trigger: Push events, Merge request events
```

---

## 📈 Métriques Surveillées

### 🔐 Sécurité

| Métrique | Description | Seuil Critique |
|----------|-------------|----------------|
| **auth_failures_rate** | Taux d'échecs d'authentification | > 5/min |
| **sudo_usage_rate** | Utilisation commandes sudo | > 10/h |
| **ssh_connections** | Connexions SSH nouvelles | > 20/h |
| **package_installs** | Installations packages | > 0 (hors maintenance) |

### 🔄 Développement

| Métrique | Description | Seuil Alerte |
|----------|-------------|--------------|
| **git_push_rate** | Fréquence pushs Git | > 10/h |
| **build_failures** | Échecs builds CI/CD | > 0 |
| **code_quality_score** | Score SonarQube | < 80% |
| **vulnerability_count** | Vulnérabilités Trivy | > 0 (HIGH/CRITICAL) |

### 🖥️ Infrastructure

| Métrique | Description | Seuil Critique |
|----------|-------------|----------------|
| **container_restarts** | Redémarrages containers | > 3/h |
| **disk_usage** | Utilisation disque | > 90% |
| **memory_usage** | Utilisation mémoire | > 95% |
| **network_anomalies** | Trafic réseau anormal | > baseline + 200% |

---

## 🛠️ Troubleshooting

### ❗ Problèmes Courants

**1. Dashboard SIEM vide/pas de données**

```bash
# Vérifier status Alloy
kubectl get pods -n monitoring | grep alloy
kubectl logs -n monitoring deployment/alloy

# Vérifier Loki
kubectl get pods -n monitoring | grep loki
kubectl logs -n monitoring statefulset/loki

# Test manuel des logs
curl -X GET "http://loki.monitoring.svc.cluster.local:3100/loki/api/v1/query_range?query={job=\"system-auth\"}"
```

**2. Webhook receiver non accessible**

```bash
# Vérifier déploiement
kubectl get pods -n monitoring | grep webhook
kubectl get svc -n monitoring | grep webhook

# Test connectivité
curl -X POST http://webhook.YOUR_IP.nip.io/webhook \
  -H "Content-Type: application/json" \
  -d '{"test": "data"}'
```

**3. Alertes non reçues**

```bash
# Vérifier configuration Grafana alerts
curl -X GET http://admin:admin123@grafana.local/api/alert-notifications

# Test notification channel
curl -X POST http://admin:admin123@grafana.local/api/alert-notifications/test \
  -H "Content-Type: application/json" \
  -d '{"name": "slack-security"}'
```

### 🔍 Debugging Commands

```bash
# Logs détaillés Alloy
kubectl logs -n monitoring deployment/alloy -f

# Stats Loki
curl -X GET http://loki.monitoring.svc.cluster.local:3100/loki/api/v1/stats

# Métriques internes Grafana
curl -X GET http://grafana.monitoring.svc.cluster.local:3000/metrics

# Test webhook receiver
kubectl port-forward -n monitoring svc/webhook-receiver 8080:80
curl -X POST http://localhost:8080/webhook -d '{"test": true}'
```

### 🆘 Recovery Procedures

**Reset complet SIEM :**
```bash
# 1. Cleanup
./setup.sh  # Option 9 → Cleanup SIEM Stack

# 2. Redéploiement
./setup.sh  # Option 5 → Deploy SIEM Security Monitoring

# 3. Réimport dashboard
# Via Grafana UI: Import dashboard from monitoring/grafana/dashboards/
```

---

## 🚀 Exemples d'Usage

### 📊 Requêtes LogQL Utiles

**Authentification SSH par utilisateur :**
```logql
{job="system-auth"} |= "Accepted" 
| json 
| count by (user)
```

**Top IPs sources suspectes :**
```logql
{job="system-auth"} |= "Failed" 
| json 
| count by (ip) 
| sort desc
```

**Timeline changements code :**
```logql
{job="webhook-receiver"} 
| json 
| line_format "{{.timestamp}} - {{.author}}: {{.message}}"
```

**Événements système critiques :**
```logql
{job=~"system-.*"} |= "ERROR" or "CRITICAL" or "FAILED"
| json
| line_format "{{.timestamp}} [{{.severity}}] {{.message}}"
```

### 🔧 Scripts d'Automatisation

**Export logs SIEM :**
```bash
#!/bin/bash
# export-siem-logs.sh

DATE=$(date -d "1 hour ago" +%s000000000)
LOKI_URL="http://loki.monitoring.svc.cluster.local:3100"

curl -G "$LOKI_URL/loki/api/v1/query_range" \
  --data-urlencode 'query={job=~"system-.*|webhook-receiver"}' \
  --data-urlencode "start=$DATE" \
  --data-urlencode "end=$(date +%s000000000)" \
  | jq '.data.result[].values[][1]' > siem-export-$(date +%Y%m%d-%H%M).json
```

**Rapport sécurité quotidien :**
```bash
#!/bin/bash
# daily-security-report.sh

echo "📊 Rapport Sécurité - $(date)"
echo "================================"

# Authentifications échouées
echo "🔐 Échecs d'authentification :"
kubectl exec -n monitoring deployment/loki -- \
  logcli query '{job="system-auth"} |= "Failed"' --since=24h --quiet | wc -l

# Installations packages
echo "📦 Packages installés :"
kubectl exec -n monitoring deployment/loki -- \
  logcli query '{job="package-install"}' --since=24h --quiet | wc -l

# Activité Git
echo "🔄 Pushs Git :"
kubectl exec -n monitoring deployment/loki -- \
  logcli query '{job="webhook-receiver"}' --since=24h --quiet | wc -l
```

---

## 📚 Ressources Additionnelles

### 🔗 Documentation Techniques

- [Grafana Loki Documentation](https://grafana.com/docs/loki/)
- [Grafana Alloy Documentation](https://grafana.com/docs/alloy/)
- [SIEM Best Practices](https://www.sans.org/white-papers/36902/)
- [LogQL Query Language](https://grafana.com/docs/loki/latest/logql/)

### 🛡️ Ressources Sécurité

- [OWASP Logging Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Logging_Cheat_Sheet.html)
- [NIST Cybersecurity Framework](https://www.nist.gov/cyberframework)
- [CIS Controls](https://www.cisecurity.org/controls/)

---

<div align="center">

**🛡️ Documentation SIEM mise à jour le $(date +%Y-%m-%d)**

[🐛 Reporter un Problème](https://github.com/Jev1337/Sample-DevSecOps/issues) • [💡 Suggestions](https://github.com/Jev1337/Sample-DevSecOps/issues) • [📖 Documentation Principale](README.md)

</div>
