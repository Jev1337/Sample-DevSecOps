# 🚀 Flask K8s DevSecOps - Complete CI/CD Security Pipeline

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Docker](https://img.shields.io/badge/Docker-20.10%2B-blue)](https://www.docker.com/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.30%2B-326ce5)](https://kubernetes.io/)
[![Python](https://img.shields.io/badge/Python-3.9%2B-green)](https://www.python.org/)
[![Ansible](https://img.shields.io/badge/Ansible-2.15%2B-red)](https://www.ansible.com/)
[![Terraform](https://img.shields.io/badge/Terraform-1.5%2B-purple)](https://www.terraform.io/)

Une solution complète de déploiement sécurisé d'applications Flask sur Kubernetes avec pipeline DevSecOps intégré, monitoring avancé, SIEM et automation complète.

## 📋 Table des Matières

- [🎯 Vue d'ensemble](#-vue-densemble)
- [🏗️ Architecture](#️-architecture)
- [⚡ Installation Rapide](#-installation-rapide)
- [🧩 Composants](#-composants)
- [🔒 Sécurité](#-sécurité)
- [�️ SIEM](#️-siem)
- [�📊 Monitoring](#-monitoring)
- [🤖 Automation avec Ansible](#-automation-avec-ansible)
- [☁️ Infrastructure Terraform (Azure)](#️-infrastructure-terraform-azure)
- [🛠️ Développement](#️-développement)
- [🔧 Troubleshooting](#-troubleshooting)
- [📚 Documentation](#-documentation)
- [📜 Licence](#-licence)

## 🎯 Vue d'ensemble

### ✨ Fonctionnalités principales

| Composant | Description | Technologie |
|-----------|-------------|-------------|
| **🐍 Application Flask** | API REST avec métriques et logs structurés | Python 3.9+, Prometheus |
| **🔄 Pipeline DevSecOps** | CI/CD automatisé avec scans sécurisés | Jenkins, SonarQube, Trivy |
| **📦 Orchestration K8s** | Déploiement, scaling et gestion automatique | MicroK8s, Helm Charts |
| **📊 Monitoring Complet** | Logs centralisés et dashboards temps réel | Loki, Grafana, Alloy |
| **🛡️ SIEM Intégré** | Surveillance sécurité et événements système | SIEM Dashboard, Audit logs, Webhook receiver |
| **🔐 Sécurité Intégrée** | Scans vulnérabilités et qualité code | Trivy, SonarQube, Audit logs |
| **☁️ Cloud Ready** | Support Azure avec accès externe | LoadBalancer, Ingress |

### 🎪 Nouveautés de cette version

- ✅ **Setup simplifié** avec menu interactif Ansible-driven
- ✅ **Installation Docker** automatisée
- ✅ **Support Azure** intégré avec accès externe
- ✅ **Mode développement** Docker Compose standalone
- ✅ **Cleanup intelligent** par composants avec tags Ansible
- ✅ **SIEM intégré** avec monitoring sécurité temps réel
- ✅ **Webhook receiver** pour événements Git/SCM
- ✅ **Audit logging K8s** avec policies sécurisées
- ✅ **Automation complète** via playbooks Ansible
- ✅ **Architecture modulaire** avec roles réutilisables

## 🏗️ Architecture

```mermaid
graph TB
    subgraph "DevSecOps Pipeline"
        A[Git Repo] --> B[Jenkins CI/CD]
        B --> C[SonarQube Analysis]
        B --> D[Trivy Security Scan]
        B --> E[Docker Build & Push]
        E --> F[K8s Deployment]
        A --> |Webhook| W[Webhook Receiver]
    end
    
    subgraph "Kubernetes Cluster"
        F --> G[Flask Application]
        G --> H[Service Mesh]
        H --> I[Ingress Controller]
        W --> |Code Changes| S[SIEM Stack]
    end
    
    subgraph "Monitoring & SIEM"
        G --> J[Alloy Collector]
        J --> K[Loki Storage]
        K --> L[Grafana Dashboards]
        OS[System Logs] --> J
        AU[Audit Logs] --> J
        S --> J
        B --> |CI/CD Events| J
    end
    
    subgraph "External Access"
        I --> M[Local DNS]
        I --> N[Azure LoadBalancer]
    end
    
    subgraph "Security Monitoring"
        L --> P[Security Dashboard]
        L --> Q[SIEM Dashboard] 
        L --> R[Application Dashboard]
    end
```

### � Stack Technologique

| Couche | Technologie | Version | Rôle |
|--------|-------------|---------|------|
| **App** | Flask + Gunicorn | 2.3.3 | API REST, métriques |
| **Container** | Docker + BuildKit | 24.0+ | Containerisation |
| **Orchestration** | MicroK8s | 1.30+ | Cluster Kubernetes |
| **Package Manager** | Helm | 3.8+ | Déploiement applications |
| **CI/CD** | Jenkins | 2.452+ | Pipeline automatisé |
| **Security** | SonarQube + Trivy | Latest | Analyse code + vulnérabilités |
| **Monitoring** | Loki + Grafana + Alloy | 3.0+ | Logs + visualisation |
| **SIEM** | Auditd + Webhook Receiver | Latest | Surveillance sécurité |
| **IaC** | Terraform + Ansible | Latest | Infrastructure + Automation |
| **Cloud** | Azure LoadBalancer | - | Accès externe |

## ⚡ Installation Rapide

### 🚀 Setup Automatisé (Recommandé)

```bash
# 1. Cloner le projet
git clone <repository-url>
cd Sample-DevSecOps

# 2. Rendre le script exécutable
chmod +x setup.sh

# 3. Lancer le menu interactif
./setup.sh
```

### 🎯 Fonctionnalités du Script Setup

Le script `setup.sh` offre une interface complète pour gérer votre environnement DevSecOps :

- **🔧 Gestion automatique des prérequis** - Vérification et installation d'Ansible
- **📊 Monitoring système intégré** - Statut en temps réel des composants
- **🎯 Déploiement modulaire** - Installation par composants ou complète
- **🧹 Nettoyage granulaire** - Suppression sélective par service
- **📋 Informations d'accès** - URLs et credentials centralisés
- **🔍 Diagnostics avancés** - Logs détaillés avec couleurs
- **☁️ Support cloud** - Configuration Azure automatisée
- **🛡️ Mode SIEM** - Déploiement surveillance sécurité

Le menu vous propose les options suivantes :

```
🚀 DevSecOps Setup Menu
======================
  1) Check Prerequisites              # Vérification prérequis système
  2) Install Ansible (if needed)     # Installation Ansible automatisée
  3) Deploy Individual Components    # Déploiement composants individuels
  4) Deploy Full Production Environment # Installation production complète
  5) Deploy SIEM Security Monitoring # Surveillance sécurité SIEM
  6) Development Mode (Docker Compose) # Mode développement local
  7) Show System Status              # Affichage statut système
  8) Show Access Information         # URLs et credentials d'accès
  9) Cleanup Options                 # Options de nettoyage par composants
 10) Exit                            # Quitter le script
```

**🧩 Menu composants individuels (Option 3) :**

```
🧩 Component Deployment Menu
============================
  1) Prerequisites & Docker          # Prérequis et installation Docker
  2) MicroK8s Setup                  # Configuration cluster Kubernetes
  3) Core Services (Jenkins, SonarQube) # Services CI/CD et qualité code
  4) Monitoring Stack (Loki, Grafana)   # Stack monitoring et logs
  5) Flask Application              # Déploiement application Flask
  6) SIEM Security Monitoring       # Monitoring sécurité et audit
  7) Azure External Access          # Configuration accès cloud Azure
  8) Return to main menu            # Retour au menu principal
```

### ⚡ Installation Express (Production)

```bash
./setup.sh
# Choisir option 4 pour l'installation production complète
```

### 🧪 Mode Développement Local

```bash
./setup.sh
# Choisir option 6 pour le mode développement Docker Compose
```

### 💡 Conseils d'Utilisation

**🚀 Première installation :**
```bash
./setup.sh
# 1. Option 1 : Check Prerequisites
# 2. Option 2 : Install Ansible (si nécessaire)
# 3. Option 4 : Deploy Full Production Environment
```

**🔧 Installation composant par composant :**
```bash
./setup.sh
# Option 3 : Deploy Individual Components
# Puis sélectionner chaque composant dans l'ordre :
# 1 → 2 → 3 → 4 → 5 → 6 → 7
```

**📊 Surveillance et maintenance :**
```bash
./setup.sh
# Option 7 : Show System Status (vérification santé)
# Option 8 : Show Access Information (URLs/credentials)
# Option 9 : Cleanup Options (nettoyage si besoin)
```

**🛡️ SIEM et sécurité :**
```bash
./setup.sh
# Option 5 : Deploy SIEM Security Monitoring
# Accès via Grafana → Dashboard "SIEM - Security Monitoring"
```

### 📋 Prérequis Système

| Composant | Version Minimum | Recommandé |
|-----------|----------------|------------|
| **OS** | Ubuntu 20.04+ | Ubuntu 22.04 LTS |
| **CPU** | 2 cores | 4+ cores |
| **RAM** | 4GB | 8GB+ |
| **Stockage** | 10GB libre | 20GB+ |
| **Docker** | 20.10+ | 24.0+ |
| **Git** | 2.25+ | Latest |

## 🧩 Composants

### 🐍 Application Flask

**Endpoints disponibles :**

```bash
GET  /                    # Page d'accueil avec statut
GET  /health              # Health check pour K8s
GET  /api/users           # Liste des utilisateurs (JSON)
POST /api/users           # Créer utilisateur
PUT  /api/users/{id}      # Modifier utilisateur
DELETE /api/users/{id}    # Supprimer utilisateur
GET  /metrics             # Métriques Prometheus
GET  /logs                # Interface logs temps réel
```

**Fonctionnalités :**

- ✅ Logs structurés JSON
- ✅ Métriques Prometheus intégrées
- ✅ Health checks Kubernetes
- ✅ Gestion d'erreurs centralisée
- ✅ Rate limiting
- ✅ CORS configuré

### 🔄 Pipeline DevSecOps

**Étapes du pipeline Jenkins :**

1. **📥 Checkout SCM** - Récupération code source
2. **📦 Install Dependencies** - Installation packages Python
3. **🧪 Run Tests** - Tests unitaires avec coverage
4. **📊 SonarQube Analysis** - Analyse qualité code
5. **🔍 Trivy FS Scan** - Scan filesystem vulnérabilités
6. **🐳 Build & Push Image** - Construction image Docker
7. **🛡️ Trivy Image Scan** - Scan image vulnérabilités
8. **🚀 Deploy to K8s** - Déploiement Kubernetes

**Configuration automatique :**

- Intégration SonarQube avec tokens
- Registry Docker local MicroK8s
- Déploiement Rolling Update
- Tests automatisés avec rapports

### 📊 Stack Monitoring

**Composants :**

| Service | Port | Rôle | Configuration |
|---------|------|------|---------------|
| **Loki** | 3100 | Stockage logs | SingleBinary mode |
| **Grafana** | 3000 | Visualisation | Dashboards pré-configurés |
| **Alloy** | - | Collecteur logs | Auto-discovery K8s |

**Dashboards inclus :**

- 📈 **Application Metrics** - Performance temps réel
- 🔒 **Security Dashboard** - Événements sécurité
- �️ **SIEM Dashboard** - Surveillance sécurité avancée
- �📋 **Infrastructure** - État cluster K8s
- 🚨 **Alerts** - Notifications automatiques

### 🛡️ SIEM (Security Information and Event Management)

**Capacités de surveillance :**

| Composant | Source | Type d'événement | Dashboard |
|-----------|--------|-------------------|-----------|
| **Auth Logs** | `/var/log/auth.log` | Connexions, échecs auth | SIEM Dashboard |
| **System Logs** | `/var/log/syslog` | Événements système | SIEM Dashboard |
| **Package Mgmt** | `/var/log/dpkg.log` | Installations logiciels | SIEM Dashboard |
| **Kernel Events** | `/var/log/kern.log` | Événements noyau | SIEM Dashboard |
| **Git Webhooks** | Webhook receiver | Changements code | SIEM Dashboard |
| **CI/CD Logs** | Jenkins | Builds, déploiements | SIEM Dashboard |
| **Audit Events** | `/var/log/audit/audit.log` | Accès fichiers critiques | SIEM Dashboard |

**Fonctionnalités SIEM :**

- 🔍 **Détection des intrusions** - Surveillez les tentatives de connexion suspectes
- 📊 **Analyse comportementale** - Identifiez les patterns anormaux
- 🌍 **Géolocalisation IP** - Analysez la provenance des connexions
- 📈 **Timeline des événements** - Corrélation temporelle des incidents
- 🚨 **Alertes en temps réel** - Notifications automatiques sur les threats
- 📋 **Rapports de conformité** - Audit trails pour la sécurité

**Configuration webhook Git :**
```bash
# URL pour votre dépôt GitHub
http://webhook.VOTRE_IP.nip.io/webhook

# Testez l'intégration
curl -X POST http://webhook.VOTRE_IP.nip.io/webhook \
  -H "Content-Type: application/json" \
  -d '{"test": "webhook"}'
```

## 🔒 Sécurité

### 🛡️ Scans Automatisés

**SonarQube Analysis :**

```bash
# Configuration dans security/sonarqube/sonar-project.properties
sonar.projectKey=flask-k8s-devsecops
sonar.sources=app/
sonar.language=py
sonar.python.coverage.reportPaths=coverage.xml
```

**Trivy Security Scans :**

```bash
# Scan filesystem
trivy fs ./app --format table --severity HIGH,CRITICAL

# Scan Docker image
trivy image localhost:32000/flask-k8s-app:latest
```

### 🔐 Sécurité Implémentée

| Aspect | Implémentation | Outil |
|--------|----------------|-------|
| **Container Security** | Images non-root, minimal base | Docker |
| **Code Quality** | Analyse statique continue | SonarQube |
| **Vulnerability Scan** | Scan images + filesystem | Trivy |
| **Secrets Management** | Kubernetes secrets chiffrés | K8s |
| **Network Policies** | Isolation réseau pods | K8s NetworkPolicy |
| **RBAC** | Contrôle accès granulaire | K8s RBAC |
| **TLS/SSL** | Chiffrement en transit | Ingress TLS |

### 📊 Dashboard Sécurité

Métriques surveillées :

- 🚫 Tentatives authentification échouées
- ⚠️ Erreurs HTTP suspectes (4xx/5xx)
- 🔍 Patterns d'attaque détectés
- 📈 Anomalies trafic réseau

## �️ SIEM

### 🎯 Security Information and Event Management

Le système SIEM intégré offre une surveillance complète des événements de sécurité :

**🔍 Événements Surveillés :**

| Type d'Événement | Source | Description |
|------------------|--------|-------------|
| **Authentification** | `/var/log/auth.log` | Connexions SSH, sudo, échecs |
| **Changements Système** | `/var/log/dpkg.log` | Installations/suppression packages |
| **Événements Kernel** | `/var/log/kern.log` | Événements système critiques |
| **Changements Code** | Git Webhooks | Push, commits, branches |
| **Pipeline CI/CD** | Jenkins logs | Builds, déploiements, tests |
| **Applications** | Container logs | Erreurs, warnings, métriques |

### 📊 Dashboard SIEM

**Importation du Dashboard :**

```bash
# Dashboard disponible dans monitoring/grafana/dashboards/siem-dashboard.json
# Importer via Grafana UI :
# 1. Accéder à Grafana (http://grafana.local)
# 2. Navigation → Dashboards → Import
# 3. Télécharger siem-dashboard.json
# 4. Configurer data source : Loki
```

**Métriques SIEM :**

- 🔐 **Authentification** : Succès/échecs, utilisateurs, IPs sources
- 🔄 **Changements Code** : Commits, auteurs, repositories
- 🏗️ **CI/CD** : Builds, déploiements, statuts
- 📦 **Système** : Installations, mises à jour, configurations
- ⚠️ **Alertes** : Événements suspicieux, anomalies

### 🔗 Configuration Webhook Git

**Setup Automatique :**

```bash
# Utiliser le script de configuration
./configure-webhook.sh

# Ou configurer manuellement :
# URL: http://webhook.YOUR_IP.nip.io/webhook
# Content-Type: application/json
# Events: Push events (ou tous pour surveillance complète)
```

**Test du Webhook :**

```bash
# Test manuel
curl -X POST http://webhook.YOUR_IP.nip.io/webhook \
  -H "Content-Type: application/json" \
  -d '{
    "repository": {"full_name": "test/repo"},
    "pusher": {"name": "testuser"},
    "head_commit": {
      "id": "abc123",
      "message": "Test commit"
    }
  }'
```

### 🚨 Alertes et Notifications

**Seuils d'Alerte :**

- **Échecs connexion** : > 5 tentatives/minute
- **Erreurs application** : > 10 erreurs/minute  
- **Changements système** : Installations non autorisées
- **Activité anormale** : Patterns d'accès suspects

## �📊 Monitoring

### 🎯 Métriques Application

**Prometheus Metrics :**

```python
# Compteurs requêtes
flask_requests_total{method="GET", endpoint="/api/users", status="200"}

# Latence requêtes
flask_request_duration_seconds{method="POST", endpoint="/api/users"}

# Métriques business
flask_users_created_total
flask_errors_total{error_type="validation"}
```

### 📋 Dashboards Grafana

**1. Application Dashboard :**

- 📊 Taux de requêtes par endpoint
- ⏱️ Latence P95/P99
- 📈 Codes de statut HTTP
- 💾 Utilisation ressources

**2. Security Dashboard :**

- 🔒 Échecs authentification
- 🚨 Alertes sécurité
- 📊 Top user agents suspects
- 🌐 Géolocalisation connexions

**3. Infrastructure Dashboard :**

- 🖥️ Métriques nodes K8s
- 📦 État des pods
- 💾 Utilisation stockage
- 🌐 Trafic réseau

### 🚨 Alertes Configurées

```yaml
# Exemple d'alerte Grafana
- alert: HighErrorRate
  expr: rate(flask_requests_total{status=~"5.."}[5m]) > 0.1
  for: 2m
  annotations:
    summary: "Taux d'erreur élevé détecté"
```

## � Automation avec Ansible

### 📋 Playbooks Disponibles

Le projet inclut des playbooks Ansible pour l'automatisation complète :

| Playbook | Description | Usage |
|----------|-------------|-------|
| `main.yml` | Setup complet DevSecOps | `ansible-playbook playbooks/main.yml` |
| `development.yml` | Environnement Docker Compose | `ansible-playbook playbooks/development.yml` |
| `core_services.yml` | Jenkins + SonarQube uniquement | `ansible-playbook playbooks/core_services.yml` |
| `monitoring.yml` | Stack monitoring uniquement | `ansible-playbook playbooks/monitoring.yml` |
| `siem.yml` | Stack SIEM uniquement | `ansible-playbook playbooks/siem.yml` |
| `flask_app.yml` | Application Flask uniquement | `ansible-playbook playbooks/flask_app.yml` |
| `cleanup.yml` | Nettoyage complet | `ansible-playbook playbooks/cleanup.yml` |

### 🎭 Rôles Ansible

| Rôle | Fonction |
|------|----------|
| `prerequisites` | Installation paquets requis |
| `docker` | Installation et configuration Docker |
| `microk8s` | Setup cluster Kubernetes |
| `jenkins_image` | Build image Jenkins personnalisée |
| `core_services` | Déploiement Jenkins/SonarQube |
| `monitoring_stack` | Déploiement Loki/Grafana/Alloy |
| `siem_stack` | **Configuration SIEM et audit** |
| `flask_app` | Déploiement application Flask |
| `azure_access` | Configuration accès externe |
| `access_info` | Affichage informations d'accès |

### 🚀 Exécution Ansible

```bash
# Setup complet automatisé
cd ansible/
ansible-playbook playbooks/main.yml --ask-become-pass

# Configuration SIEM uniquement
ansible-playbook playbooks/siem.yml --ask-become-pass

# Mode développement
ansible-playbook playbooks/development.yml --ask-become-pass

# Nettoyage
ansible-playbook playbooks/cleanup.yml --ask-become-pass
```

## ☁️ Infrastructure Terraform (Azure)

### 🏗️ Architecture Cloud

Le répertoire `terraform/` contient l'infrastructure as code pour Azure :

**Composants déployés :**

| Ressource | Type | Description |
|-----------|------|-------------|
| `azurerm_linux_virtual_machine` | Spot VM | Machine virtuelle optimisée coût |
| `azurerm_network_security_group` | Sécurité | Règles firewall DevSecOps |
| `azurerm_log_analytics_workspace` | Monitoring | Collecte logs Azure |
| `azurerm_application_insights` | APM | Monitoring applicatif |
| `azurerm_storage_account` | Stockage | Backups et artifacts |
| `azurerm_recovery_services_vault` | Sauvegarde | Backup automatisé VM |

### 💰 Optimisation des Coûts

```hcl
# Configuration Spot Instance (jusqu'à 90% d'économies)
priority     = "Spot"
max_bid_price = 0.10  # $0.10/heure maximum

# Auto-shutdown programmé
auto_shutdown_enabled = true
auto_shutdown_time = "2300"  # 23h00 UTC
```

### 🚀 Déploiement Terraform

```bash
cd terraform/

# 1. Configuration
cp terraform.tfvars.example terraform.tfvars
# Éditez terraform.tfvars avec vos valeurs

# 2. Authentification Azure
az login
az account set --subscription "your-subscription-id"

# 3. Déploiement
terraform init
terraform plan
terraform apply

# 4. Connexion à la VM
ssh -i devsecops-key.pem azureuser@PUBLIC_IP

# 5. Nettoyage
terraform destroy
```

### 🔗 URLs d'accès Cloud

Après déploiement Terraform, accédez aux services via :

```bash
# URLs nip.io (recommandé)
Jenkins:   http://jenkins.VOTRE_IP.nip.io
SonarQube: http://sonarqube.VOTRE_IP.nip.io
Grafana:   http://grafana.VOTRE_IP.nip.io
Flask App: http://app.VOTRE_IP.nip.io
SIEM Webhook: http://webhook.VOTRE_IP.nip.io/webhook

# Ou directement par IP
http://VOTRE_IP:8080  # Jenkins
http://VOTRE_IP:9000  # SonarQube
http://VOTRE_IP:3000  # Grafana
http://VOTRE_IP:5000  # Flask App
```

## �🛠️ Développement

### 🧪 Mode Développement Local

```bash
# Démarrer avec Docker Compose
./setup.sh  # Option 6

# Ou manuellement
docker compose up -d

# Vérifier les services
docker compose ps
```

**Services développement :**

| Service | URL | Identifiants |
|---------|-----|--------------|
| Flask App | http://localhost:5000 | - |
| SonarQube | http://localhost:9000 | admin/admin |
| Grafana | http://localhost:3000 | admin/admin123 |
| Loki | http://localhost:3100 | - |

### 🧪 Tests et Qualité

```bash
cd app/

# Tests unitaires
python -m pytest tests/ -v

# Tests avec couverture
python -m pytest tests/ --cov=. --cov-report=html

# Linting
flake8 app.py
black app.py --check

# Tests de charge
pip install locust
locust -f tests/load_test.py --host=http://localhost:5000
```

### 🔧 Développement avec Hot Reload

```bash
# Mode développement Flask
cd app/
FLASK_ENV=development python app.py

# Avec volume Docker
docker run -v $(pwd)/app:/app -p 5000:5000 flask-k8s-app:latest
```

### 📦 Build et Push Images

```bash
# Build local
docker build -t flask-k8s-app:latest ./app

# Tag pour registry
docker tag flask-k8s-app:latest localhost:32000/flask-k8s-app:latest

# Push vers MicroK8s registry
docker push localhost:32000/flask-k8s-app:latest
```

## ☁️ Déploiement Cloud

### 🌩️ Configuration Azure

```bash
# Configurer accès externe Azure
./setup.sh  # Option 3 puis Option 7

# Vérifier IP externe
curl -s ifconfig.me
```

**Services LoadBalancer créés :**

| Service | Port Externe | Port Interne |
|---------|--------------|--------------|
| Jenkins | 8080 | 8080 |
| SonarQube | 9000 | 9000 |
| Grafana | 3000 | 3000 |
| Flask App | 80 | 5000 |

### 🔗 URLs Accès Externe

Après configuration Azure :

```bash
# Remplacer <EXTERNAL_IP> par votre IP publique
http://<EXTERNAL_IP>:8080  # Jenkins
http://<EXTERNAL_IP>:9000  # SonarQube  
http://<EXTERNAL_IP>:3000  # Grafana
http://<EXTERNAL_IP>       # Flask App
```

### 🛡️ Sécurité Cloud

**Configuration firewall Azure :**

```bash
# Ouvrir ports nécessaires
az network nsg rule create \
  --resource-group myResourceGroup \
  --nsg-name myNSG \
  --name DevSecOps-Ports \
  --protocol tcp \
  --priority 1000 \
  --destination-port-ranges 80 3000 8080 9000 \
  --access allow
```

### � Monitoring Cloud

- 📈 **Azure Monitor** - Métriques VM
- 🔍 **Application Insights** - APM
- 📋 **Log Analytics** - Centralisation logs
- 🚨 **Azure Alerts** - Notifications

## �🔧 Troubleshooting

### ❗ Problèmes Courants

**1. Pods en état Pending :**

```bash
# Vérifier ressources
kubectl describe pod <pod-name> -n <namespace>
kubectl top nodes
microk8s inspect

# Solution : Augmenter ressources ou nettoyer
./setup.sh  # Option 9 pour cleanup
```

**2. Images Docker non trouvées :**

```bash
# Vérifier registry local
docker images | grep localhost:32000

# Rebuilder si nécessaire
./setup.sh  # Option 3 puis Options 3 et 5
```

**3. Services inaccessibles :**

```bash
# Vérifier ingress
kubectl get ingress -A
kubectl describe ingress -n flask-app

# Vérifier /etc/hosts
grep "\.local" /etc/hosts
```

**4. Jenkins build failures :**

```bash
# Vérifier logs Jenkins
kubectl logs -f deployment/jenkins -n jenkins

# Vérifier Docker dans Jenkins
kubectl exec -it deployment/jenkins -n jenkins -- docker ps
```

### 🔍 Commandes Diagnostic

```bash
# État général cluster
kubectl get all -A
microk8s status

# Logs par service
kubectl logs -f deployment/flask-app -n flask-app
kubectl logs -f statefulset/loki -n monitoring

# Ressources utilisées
kubectl top pods -A
kubectl top nodes

# Événements récents
kubectl get events --sort-by='.lastTimestamp' -A

# Storage et PVCs
kubectl get pv,pvc -A

# Network et services
kubectl get svc,endpoints -A
```

### 🧹 Nettoyage et Reset

```bash
# Cleanup par composants
./setup.sh  # Option 9

# Reset complet
./setup.sh  # Option 9 -> puis choisir cleanup complet

# Reset MicroK8s complet
microk8s reset
sudo snap remove microk8s
```

### 📞 Support et Aide

| Problème | Solution | Documentation |
|----------|----------|---------------|
| **Setup Issues** | Relancer `./setup.sh` option 1 puis 2 | [Prerequisites](#-installation-rapide) |
| **Network Problems** | Vérifier firewall et DNS | [Troubleshooting](#-troubleshooting) |
| **Performance** | Augmenter ressources VM | [Architecture](#️-architecture) |
| **Security Scans** | Vérifier config SonarQube/Trivy | [Sécurité](#-sécurité) |

## 📚 Documentation Complémentaire

- 📖 [**Documentation Technique Détaillée**](PROJECT_DOCUMENTATION.md)
- 🚀 [**Guide Architecture**](comparaison.md)
- ☁️ [**Azure External Access**](AZURE_EXTERNAL_ACCESS.md)
- 🛠️ [**Helm Charts Documentation**](helm/)

## 🤝 Contribution

1. **Fork** le projet
2. **Créer** une branche feature (`git checkout -b feature/amazing-feature`)
3. **Commit** les changements (`git commit -m 'Add amazing feature'`)
4. **Push** la branche (`git push origin feature/amazing-feature`)
5. **Ouvrir** une Pull Request

### 📋 Guidelines

- ✅ Tests unitaires pour nouvelles fonctionnalités
- ✅ Documentation mise à jour
- ✅ Respect des conventions de nommage
- ✅ Scans sécurité passants

## 📚 Documentation

- 📖 [**Documentation Projet**](PROJECT_DOCUMENTATION.md) - Guide technique détaillé
- 🛡️ [**Documentation SIEM**](SIEM_DOCUMENTATION.md) - Guide complet de surveillance sécurité
- 🔧 [**Documentation Ansible**](ansible/README.md) - Automatisation et déploiement
- ☁️ [**Documentation Terraform**](terraform/README.md) - Infrastructure Azure
- ☁️ [**Azure External Access**](AZURE_EXTERNAL_ACCESS.md) - Configuration accès cloud
- 🚀 [**Setup Script**](setup.sh) - Script d'installation interactif
- 📊 [**Architecture Comparison**](comparaison.md) - Analyse comparative des technologies

## 📜 Licence

Ce projet est sous licence MIT. Voir le fichier [LICENSE](LICENSE) pour plus de détails.

---

<div align="center">

**🚀 Plateforme DevSecOps complète - Janvier 2025**

[![Stars](https://img.shields.io/github/stars/Jev1337/Sample-DevSecOps?style=social)](https://github.com/Jev1337/Sample-DevSecOps)
[![Forks](https://img.shields.io/github/forks/Jev1337/Sample-DevSecOps?style=social)](https://github.com/Jev1337/Sample-DevSecOps)
[![Issues](https://img.shields.io/github/issues/Jev1337/Sample-DevSecOps)](https://github.com/Jev1337/Sample-DevSecOps/issues)

[🐛 Reporter un Bug](https://github.com/Jev1337/Sample-DevSecOps/issues) • [💡 Demander une Fonctionnalité](https://github.com/Jev1337/Sample-DevSecOps/issues) • [📖 Documentation](PROJECT_DOCUMENTATION.md) • [🛡️ SIEM Guide](SIEM_DOCUMENTATION.md)

</div>
