# 🚀 Flask K8s DevSecOps - Déploiement Sécurisé avec Centralisation des Logs

Ce projet implémente une solution complète de déploiement sécurisé d'une application Flask sur Kubernetes avec intégration DevSecOps et centralisation des logs.

## 📋 Table des Matières

- [Vue d'ensemble](#vue-densemble)
- [Architecture](#architecture)
- [Prérequis](#prérequis)
- [Installation Rapide](#installation-rapide)
- [Utilisation](#utilisation)
- [Composants](#composants)
- [Sécurité](#sécurité)
- [Monitoring](#monitoring)
- [Développement](#développement)
- [Troubleshooting](#troubleshooting)

## 🎯 Vue d'ensemble

### Fonctionnalités principales

- **Application Flask** : API REST avec métriques Prometheus
- **Déploiement Kubernetes** : Manifestes complets avec HPA et Ingress
- **Pipeline DevSecOps** : Scans automatiques avec Trivy et SonarQube
- **Centralisation des logs** : Stack Loki + Grafana + Alloy
- **Monitoring** : Dashboards Grafana pour logs et sécurité
- **Helm Charts** : Déploiement simplifié avec templates

### Technologies utilisées

| Composant | Technologie | Version |
|-----------|-------------|---------|
| **Application** | Python Flask | 2.3.3 |
| **Containerisation** | Docker | 20.10+ |
| **Orchestration** | MicroK8s | 1.30+ |
| **Package Manager** | Helm | 3.8+ |
| **Logs** | Loki + Grafana + Alloy | 3.0+ |
| **Sécurité** | Trivy + SonarQube | Latest |
| **CI/CD** | Jenkins | 2.452.2+ |

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Flask App     │───▶│   Kubernetes    │───▶│   Monitoring    │
│   (Python)      │    │   (MicroK8s)    │    │   (Grafana)     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   CI/CD         │    │   Security      │    │   Logs          │
│   (Jenkins)     │    │   (Trivy/Sonar) │    │   (Loki)        │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 📋 Prérequis

### Outils requis

```bash
# Vérifier les versions
docker --version         # 24.0+
microk8s version       # 1.30+
helm version             # 3.8+
```

### Ressources système

- **CPU** : 4 cores minimum
- **RAM** : 8GB minimum
- **Stockage** : 20GB libre
- **Réseau** : Accès internet

## ⚡ Installation Rapide

### 1. Clonage du projet

```bash
git clone <repository-url>
cd flask-k8s-devsecops
```

### 2. Installation automatique

```bash
chmod +x setup.sh
./setup.sh
```

### 3. Vérification

```bash
# Vérifier les pods
kubectl get pods -A

# Tester l'application
curl http://localhost/health
```

## 🎮 Utilisation

### Accès aux services

| Service | URL | Identifiants |
|---------|-----|--------------|
| **Flask App** | http://flask-app.local | - |
| **Grafana** | http://grafana.local | admin/admin123 |
| **SonarQube** | http://sonarqube.local | admin/admin |
| **Jenkins** | http://jenkins.local | (mot de passe initial dans la console) |

### Commandes utiles

```bash
# Logs en temps réel
microk8s kubectl logs -f deployment/flask-app -n flask-app

# Port forwarding Grafana
microk8s kubectl port-forward service/grafana 3000:3000 -n monitoring

# Redémarrer un déploiement
microk8s kubectl rollout restart deployment/flask-app -n flask-app

# Scaler l'application
microk8s kubectl scale deployment/flask-app --replicas=5 -n flask-app
```

## 🧩 Composants

### Application Flask

```python
# Endpoints disponibles
GET  /                    # Page d'accueil
GET  /health              # Health check
GET  /api/users           # Liste des utilisateurs
POST /api/users           # Créer un utilisateur
GET  /metrics             # Métriques Prometheus
```

### Ressources Kubernetes

```bash
# Namespaces
kubectl get namespaces
flask-app    # Application
monitoring   # Monitoring stack

# Déploiements
kubectl get deployments -A
flask-app    # Application Flask
loki         # Stockage logs
grafana      # Visualisation
alloy        # Collecte logs
```

### Monitoring Stack

- **Loki** : Stockage des logs avec indexation par labels
- **Grafana Alloy** : Collecte moderne des logs (remplace Promtail)
- **Grafana** : Visualisation avec dashboards pré-configurés

## 🔒 Sécurité

### Scans automatiques

```bash
# Scan des vulnérabilités avec Trivy
trivy fs ./app --format table

# Analyse SonarQube
sonar-scanner -Dproject.settings=security/sonarqube/sonar-project.properties
```

### Bonnes pratiques implémentées

- ✅ Images Docker non-root
- ✅ Limites de ressources
- ✅ Network Policies
- ✅ Secrets chiffrés
- ✅ Scans de vulnérabilités
- ✅ Analyse de code statique

### Dashboards sécurité

- **Tentatives d'authentification** : Monitoring des échecs 401/403
- **Erreurs HTTP** : Suivi des codes d'erreur 4xx/5xx
- **Activité suspecte** : Détection de patterns anormaux

## 📊 Monitoring

### Dashboards Grafana

1. **Application Logs**
   - Distribution des niveaux de log
   - Taux de logs par pod
   - Codes d'erreur HTTP
   - Logs en temps réel

2. **Security Dashboard**
   - Échecs d'authentification
   - Erreurs HTTP
   - Menaces de sécurité
   - User agents suspects

### Métriques Prometheus

```bash
# Métriques disponibles
flask_requests_total              # Nombre total de requêtes
flask_request_duration_seconds    # Latence des requêtes
```

### Alertes configurées

- **Erreurs critiques** : > 10 erreurs/minute
- **Latence élevée** : > 2 secondes
- **Échecs authentification** : > 5 échecs/minute

## 🛠️ Développement

### Environnement local

```bash
# Démarrer l'environnement de développement
docker-compose up -d

# Vérifier les services
docker-compose ps

# Logs des services
docker-compose logs -f flask-app
```

### Tests

```bash
# Tests unitaires
cd app
python -m pytest tests/ -v

# Tests avec couverture
python -m pytest tests/ -v --cov=. --cov-report=html

# Tests de charge
artillery quick --count 100 --num 10 http://flask-app.local
```

### Déploiement avec Helm

```bash
# Installer avec Helm
helm install flask-app ./helm/flask-app

# Mettre à jour
helm upgrade flask-app ./helm/flask-app

# Désinstaller
helm uninstall flask-app
```

## 🔧 Troubleshooting

### Problèmes courants

#### Pods en état Pending

```bash
# Vérifier les ressources
kubectl describe pod <pod-name> -n <namespace>
kubectl top nodes
```

#### Logs non collectés

```bash
# Vérifier Alloy
kubectl logs -f daemonset/alloy -n monitoring

# Vérifier Loki
kubectl logs -f deployment/loki -n monitoring
```

#### Dashboards vides

```bash
# Vérifier la connexion Grafana-Loki
kubectl port-forward service/grafana 3000:3000 -n monitoring
# Aller dans Grafana > Data Sources > Loki
```

### Commandes de diagnostic

```bash
# État général du cluster
kubectl get all -A

# Événements par namespace
kubectl get events -n flask-app --sort-by='.lastTimestamp'

# Ressources utilisées
kubectl top pods -A
kubectl top nodes

# Logs système
minikube logs
```

### Réinitialisation complète

```bash
# Supprimer les ressources
kubectl delete namespace flask-app monitoring

# Redémarrer minikube
minikube delete
minikube start --memory=6144 --cpus=4

# Relancer le setup
./setup.sh
```

## 📚 Documentation

- [Documentation technique complète](technical.md)
- [Guide d'architecture](documentation.md)
- [Helm Charts](helm/flask-app/README.md)

## 🤝 Contribution

1. Fork le projet
2. Créer une branche feature (`git checkout -b feature/amazing-feature`)
3. Commit les changements (`git commit -m 'Add amazing feature'`)
4. Push la branche (`git push origin feature/amazing-feature`)
5. Ouvrir une Pull Request

## 📜 Licence

Ce projet est sous licence MIT. Voir le fichier [LICENSE](LICENSE) pour plus de détails.

## 🆘 Support

Pour toute question ou problème :

1. Consulter les [Issues GitHub](https://github.com/example/flask-k8s-devsecops/issues)
2. Vérifier la [documentation technique](technical.md)
3. Utiliser les commandes de diagnostic ci-dessus

---

**Créé avec ❤️ pour l'apprentissage DevSecOps**
