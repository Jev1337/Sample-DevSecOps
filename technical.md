# Guide Technique : Déploiement Sécurisé Flask sur Kubernetes avec DevSecOps et Centralisation des Logs

## Vue d'ensemble de l'architecture

Ce projet implémente une solution complète de déploiement sécurisé d'une application Flask sur Kubernetes avec :
- Pipeline DevSecOps intégré (Trivy, SonarQube)
- Centralisation des logs avec Loki + Grafana + Alloy
- Monitoring et dashboards de sécurité
- Tests automatisés et déploiement continu

### Architecture technique

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Flask App     │───▶│   Kubernetes    │───▶│   Monitoring    │
│   (Python)      │    │   (minikube)    │    │   (Grafana)     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   CI/CD         │    │   Security      │    │   Logs          │
│   (GitHub)      │    │   (Trivy/Sonar) │    │   (Loki)        │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Structure du projet

```
flask-k8s-devsecops/
├── app/
│   ├── app.py                    # Application Flask principale
│   ├── requirements.txt          # Dépendances Python
│   ├── tests/
│   │   └── test_app.py          # Tests unitaires
│   └── Dockerfile               # Image Docker
├── k8s/
│   ├── namespace.yaml           # Namespace Kubernetes
│   ├── deployment.yaml          # Déploiement de l'application
│   ├── service.yaml             # Service Kubernetes
│   ├── configmap.yaml           # Configuration de l'application
│   ├── secret.yaml              # Secrets (variables sensibles)
│   ├── ingress.yaml             # Ingress pour l'accès externe
│   └── hpa.yaml                 # Horizontal Pod Autoscaler
├── helm/
│   └── flask-app/               # Chart Helm (bonus)
│       ├── Chart.yaml
│       ├── values.yaml
│       └── templates/
├── monitoring/
│   ├── loki/
│   │   └── loki-config.yaml     # Configuration Loki
│   ├── grafana/
│   │   ├── grafana-config.yaml  # Configuration Grafana
│   │   └── dashboards/
│   │       ├── app-logs.json    # Dashboard logs application
│   │       └── security.json    # Dashboard sécurité
│   └── alloy/
│       └── alloy-config.yaml    # Configuration Grafana Alloy
├── security/
│   ├── sonarqube/
│   │   └── sonar-project.properties
│   ├── trivy/
│   │   └── trivy-config.yaml
│   └── reports/
│       └── security-dashboard.html
├── .github/
│   └── workflows/
│       ├── ci-cd.yml            # Pipeline principal
│       ├── security-scan.yml    # Pipeline sécurité
│       └── deploy.yml           # Pipeline déploiement
├── docker-compose.yml           # Stack de développement local
├── README.md                    # Documentation utilisateur
└── setup.sh                    # Script d'installation automatique
```

## Phase 1 : Création de l'application Flask

### 1.1 Application Flask de base

L'application Flask implémente une API REST simple avec :
- Endpoint de santé (`/health`)
- API utilisateurs (`/api/users`)
- Métriques Prometheus (`/metrics`)
- Logs structurés JSON
- Gestion d'erreurs complète

### 1.2 Tests unitaires

Tests automatisés couvrant :
- Endpoints de l'API
- Gestion des erreurs
- Métriques de performance
- Validation des données

### 1.3 Containerisation Docker

Image Docker optimisée avec :
- Image de base Alpine Linux (sécurisée et légère)
- Utilisateur non-root
- Multi-stage build
- Healthcheck intégré
- Variables d'environnement configurables

## Phase 2 : Déploiement Kubernetes

### 2.1 Manifestes Kubernetes de base

**Namespace** : Isolation des ressources
- Séparation claire des environnements
- Politiques de sécurité dédiées
- Gestion des quotas de ressources

**Deployment** : Gestion des pods
- 3 répliques pour la haute disponibilité
- Rolling updates pour le déploiement continu
- Probes de santé (liveness/readiness)
- Limites de ressources (CPU/Memory)

**Service** : Exposition interne
- Load balancing automatique
- Service discovery
- Port mapping configurable

**ConfigMap** : Configuration de l'application
- Variables d'environnement non-sensibles
- Configuration de logging
- Paramètres de l'application

**Secret** : Données sensibles
- Clés d'API chiffrées
- Mots de passe de base de données
- Certificats TLS

### 2.2 Fonctionnalités avancées

**Ingress** : Exposition externe
- Routage HTTP/HTTPS
- Terminaison SSL/TLS
- Path-based routing

**HPA (Horizontal Pod Autoscaler)** : Autoscaling
- Scaling basé sur l'utilisation CPU
- Scaling basé sur les métriques personnalisées
- Limites min/max configurables

### 2.3 Helm Chart

Chart Helm pour simplifier le déploiement :
- Templates paramétrables
- Values.yaml pour la configuration
- Hooks de déploiement
- Dépendances gérées

## Phase 3 : Pipeline DevSecOps

### 3.1 Configuration GitHub Actions

**Pipeline principal** (`ci-cd.yml`) :
1. Checkout du code
2. Configuration Python
3. Installation des dépendances
4. Exécution des tests
5. Build de l'image Docker
6. Push vers le registry
7. Déploiement sur Kubernetes

**Pipeline sécurité** (`security-scan.yml`) :
1. Scan de vulnérabilités avec Trivy
2. Analyse de code avec SonarQube
3. Tests de sécurité OWASP ZAP
4. Génération de rapports HTML
5. Publication des résultats

### 3.2 Intégration Trivy

Configuration pour le scan de vulnérabilités :
- Scan des images Docker
- Scan du filesystem
- Scan des dépendances
- Formats de sortie multiples (JSON, HTML, SARIF)
- Seuils de sévérité configurables

### 3.3 Intégration SonarQube

Analyse de qualité et sécurité du code :
- Détection de vulnérabilités
- Code smells et bugs
- Couverture de tests
- Métriques de qualité
- Quality Gates automatiques

### 3.4 Dashboard de sécurité

Dashboard HTML interactif présentant :
- Résultats des scans Trivy
- Métriques SonarQube
- Tendances de sécurité
- Recommandations d'amélioration
- Statut global de sécurité

## Phase 4 : Centralisation des logs avec Loki + Grafana + Alloy

### 4.1 Architecture de logging

**Grafana Alloy** (Collecteur moderne) :
- Collecte unified logs/metrics/traces
- Autodécouverte Kubernetes
- Parsing et transformation des logs
- Support OpenTelemetry
- Configuration déclarative

**Loki** (Stockage des logs) :
- Indexation par labels uniquement
- Stockage efficace et économique
- Query language PromQL-like (LogQL)
- Intégration native avec Grafana
- Rétention configurable

**Grafana** (Visualisation) :
- Dashboards interactifs
- Alerting avancé
- Exploration des logs
- Corrélation logs/métriques
- Partage et collaboration

### 4.2 Configuration des composants

**Loki** : Stockage et indexation
- Configuration pour environnement de développement
- Stockage local avec filesystem
- Rétention des logs sur 30 jours
- Limites de débit configurables

**Grafana Alloy** : Collecte des logs
- Découverte automatique des pods Kubernetes
- Parsing des logs JSON
- Ajout de labels de métadonnées
- Pipeline de transformation

**Grafana** : Visualisation et alertes
- Datasource Loki pré-configuré
- Dashboards pour logs applicatifs
- Dashboards pour logs système
- Alertes sur les erreurs critiques

### 4.3 Dashboards personnalisés

**Dashboard Application** :
- Volume de logs par service
- Répartition par niveau de log
- Top des erreurs
- Logs en temps réel
- Métriques de performance

**Dashboard Sécurité** :
- Tentatives d'accès
- Erreurs d'authentification
- Activité suspecte
- Alertes de sécurité
- Corrélation avec les scans

## Phase 5 : Déploiement et configuration

### 5.1 Prérequis techniques

**Environnement de développement** :
- Docker 20.10+
- kubectl 1.24+
- Helm 3.8+
- minikube 1.25+
- Git 2.30+

**Ressources système** :
- CPU : 4 cores minimum
- RAM : 8GB minimum
- Stockage : 20GB libre
- Réseau : accès internet

### 5.2 Installation automatisée

Script `setup.sh` pour l'installation complète :
1. Vérification des prérequis
2. Démarrage de minikube
3. Installation des opérateurs
4. Déploiement de l'application
5. Configuration du monitoring
6. Validation du déploiement

### 5.3 Configuration pas à pas

**Étape 1 : Préparation de l'environnement**
```bash
# Démarrage de minikube avec les ressources nécessaires
minikube start --memory=6144 --cpus=4 --disk-size=20g

# Activation des addons requis
minikube addons enable ingress
minikube addons enable metrics-server
```

**Étape 2 : Déploiement de l'application**
```bash
# Création du namespace
kubectl apply -f k8s/namespace.yaml

# Déploiement des ressources
kubectl apply -f k8s/

# Vérification du déploiement
kubectl get pods -n flask-app
```

**Étape 3 : Configuration du monitoring**
```bash
# Déploiement de Loki
kubectl apply -f monitoring/loki/

# Déploiement de Grafana
kubectl apply -f monitoring/grafana/

# Déploiement d'Alloy
kubectl apply -f monitoring/alloy/
```

**Étape 4 : Configuration de la sécurité**
```bash
# SonarQube local
docker-compose up -d sonarqube

# Configuration des scans Trivy
kubectl apply -f security/trivy/
```

### 5.4 Validation et tests

**Tests de fonctionnement** :
- Accessibilité de l'application
- Fonctionnement des API
- Génération des logs
- Collecte par Alloy
- Visualisation dans Grafana

**Tests de sécurité** :
- Scans automatiques Trivy
- Analyse SonarQube
- Génération des rapports
- Validation des seuils

**Tests de performance** :
- Load testing avec Artillery
- Monitoring des métriques
- Autoscaling HPA
- Limites de ressources

## Phase 6 : Utilisation et maintenance

### 6.1 Accès aux services

**Application Flask** :
- URL : `http://flask-app.local` (via Ingress)
- API Health : `http://flask-app.local/health`
- Métriques : `http://flask-app.local/metrics`

**Grafana** :
- URL : `http://grafana.local`
- Utilisateur : `admin`
- Mot de passe : généré automatiquement

**SonarQube** :
- URL : `http://localhost:9000`
- Utilisateur : `admin`
- Mot de passe : `admin`

### 6.2 Dashboards et monitoring

**Dashboard Logs Application** :
- Filtrage par service/pod
- Recherche full-text
- Alertes automatiques
- Export des logs

**Dashboard Sécurité** :
- Statut des scans
- Vulnérabilités détectées
- Tendances de sécurité
- Actions recommandées

### 6.3 Maintenance et évolution

**Mises à jour de sécurité** :
- Scan automatique quotidien
- Alertes sur nouvelles vulnérabilités
- Procédure de mise à jour
- Tests de régression

**Optimisation des performances** :
- Monitoring des ressources
- Ajustement des limites
- Optimisation des requêtes
- Tuning de la configuration

**Sauvegarde et récupération** :
- Sauvegarde des logs
- Export des dashboards
- Configuration as Code
- Procédures de disaster recovery

## Métriques et indicateurs de succès

### Métriques de déploiement
- Temps de déploiement : < 5 minutes
- Temps de récupération : < 2 minutes
- Disponibilité : > 99.9%
- Temps de réponse : < 200ms

### Métriques de sécurité
- Vulnérabilités critiques : 0
- Vulnérabilités hautes : < 5
- Couverture de tests : > 80%
- Délai de correction : < 24h

### Métriques de monitoring
- Collecte des logs : 100%
- Rétention : 30 jours
- Temps de recherche : < 3s
- Disponibilité monitoring : > 99%

## Troubleshooting courant

### Problèmes de déploiement
- Pods en état Pending : vérifier les ressources
- ImagePullBackOff : valider l'image Docker
- CrashLoopBackOff : examiner les logs

### Problèmes de monitoring
- Logs non collectés : vérifier Alloy
- Dashboards vides : valider Loki
- Alertes non fonctionnelles : tester la configuration

### Problèmes de sécurité
- Scans échoués : vérifier la connectivité
- Rapports incomplets : valider les permissions
- Quality Gates bloqués : examiner les métriques

## Améliorations futures

### Sécurité avancée
- Intégration Falco pour la détection d'intrusion
- Policies OPA/Gatekeeper
- Network Policies Kubernetes
- Service Mesh (Istio) pour mTLS

### Monitoring avancé
- Traces distribuées avec Jaeger
- Métriques applicatives avec Prometheus
- APM avec OpenTelemetry
- Corrélation logs-metrics-traces

### Déploiement avancé
- GitOps avec ArgoCD
- Environnements multiples (dev/staging/prod)
- Canary deployments
- Infrastructure as Code avec Terraform

Cette architecture fournit une base solide pour un déploiement sécurisé en production avec toutes les bonnes pratiques DevSecOps et une observabilité complète.