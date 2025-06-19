# Déploiement sécurisé sur Kubernetes : Intégration DevSecOps et centralisation des logs

## Vue d'ensemble du projet

Ce projet vise à mettre en place une solution complète de déploiement sécurisé sur Kubernetes avec intégration DevSecOps et centralisation des logs.

### Objectifs principaux
1. **Déploiement Kubernetes** : Créer et déployer une application simple sur Kubernetes
2. **Pipeline de sécurité DevSecOps** : Intégrer des outils de sécurité dans le pipeline CI/CD
3. **Centralisation des logs** : Mettre en place un système de collecte et visualisation des logs

## Analyse comparative des solutions et technologies

### 1. Environnements de déploiement Kubernetes

| Solution | Avantages | Inconvénients | Cas d'usage | Coût |
|----------|-----------|---------------|-------------|------|
| **Minikube** | - Installation locale simple<br>- Idéal pour développement<br>- Pas de coût<br>- Support addons intégrés | - Ressources limitées<br>- Un seul nœud<br>- Performance limitée | Développement local<br>Tests de base<br>Apprentissage | Gratuit |
| **Kind** | - Très léger<br>- Démarrage rapide<br>- Supporte multi-nœuds<br>- Intégration CI/CD excellente | - Moins de fonctionnalités<br>- Pas d'interface graphique<br>- Stockage volatile | Tests CI/CD<br>Développement rapide<br>Environnements temporaires | Gratuit |
| **MicroK8s** | - Léger<br>- Fonctionnalités Kubernetes complètes<br>- Installation facile | - Communauté plus petite<br>- Peut être gourmand en ressources | Développement<br>CI/CD<br>IoT/Edge | Gratuit |
| **Managed K8s** | - Prêt pour la production<br>- Scalable<br>- Géré par le fournisseur cloud | - Coût<br>- Complexité<br>- Dépendance au fournisseur | Environnements de production<br>Applications haute disponibilité | Payant |

### 2. Gestionnaires de packages Kubernetes

| Solution | Avantages | Inconvénients | Complexité | Écosystème |
|----------|-----------|---------------|------------|-------------|
| **Helm** | - Standard de facto<br>- Large écosystème de charts<br>- Gestion des versions<br>- Templating puissant | - Courbe d'apprentissage<br>- Complexité pour cas simples<br>- Dépendances multiples | Moyenne | Très large |
| **Kustomize** | - Natif Kubernetes<br>- Approche déclarative<br>- Pas de templating<br>- Simplicité | - Moins de fonctionnalités<br>- Pas de gestion versions<br>- Écosystème limité | Faible | Moyen |
| **YAML** | - Simplicité maximale<br>- Contrôle total<br>- Pas de dépendances<br>- Débogage facile | - Duplication de code<br>- Maintenance difficile<br>- Pas de réutilisabilité | Très faible | N/A |

### 3. Outils de sécurité DevSecOps

#### Scanners de vulnérabilités

| Outil | Type de scan | Avantages | Inconvénients | Coût | Intégration CI/CD |
|-------|--------------|-----------|---------------|------|-------------------|
| **Trivy** | Images, FS, Git | - Très rapide<br>- Base de données complète<br>- Facile à intégrer<br>- Supporte multiples formats | - Uniquement vulnérabilités<br>- Pas d'analyse comportementale | Gratuit | Excellente |
| **Clair** | Images de conteneurs | - Analyse approfondie<br>- API REST<br>- Scalable<br>- Notifications | - Configuration complexe<br>- Ressources importantes<br>- Courbe d'apprentissage | Gratuit | Bonne |
| **Anchore** | Images, conformité | - Analyse de conformité<br>- Politiques personnalisées<br>- Rapports détaillés<br>- Support entreprise | - Version gratuite limitée<br>- Complexité de configuration | Gratuit/Payant | Bonne |

#### Analyse de code statique

| Outil | Langages supportés | Avantages | Inconvénients | Coût | Qualité des rapports |
|-------|-------------------|-----------|---------------|------|---------------------|
| **SonarQube** | 25+ langages | - Analyse complète<br>- Interface web riche<br>- Historique des métriques<br>- Règles personnalisables | - Ressources importantes<br>- Configuration complexe<br>- Licence payante (fonctionnalités avancées) | Community/Payant | Excellente |
| **CodeQL** | 10+ langages | - Analyse sémantique<br>- Requêtes personnalisées<br>- Intégration GitHub<br>- Précision élevée | - Limité aux langages supportés<br>- Courbe d'apprentissage<br>- Ressources importantes | Gratuit (GitHub) | Très bonne |
| **Semgrep** | 20+ langages | - Règles simples<br>- Rapide<br>- Communauté active<br>- CLI intuitive | - Moins de fonctionnalités<br>- Pas d'interface web (version gratuite) | Gratuit/Payant | Bonne |


### 4. Plateformes CI/CD

| Plateforme | Avantages | Inconvénients | Coût | Écosystème |
|------------|-----------|---------------|------|-------------|
| **GitHub Actions** | - Intégration native GitHub<br>- Marketplace d'actions<br>- Gratuit (limites généreuses)<br>- Configuration simple | - Limité aux repositories GitHub<br>- Moins de fonctionnalités avancées<br>- Dépendant de GitHub | Gratuit/Payant | Très large |
| **GitLab CI/CD** | - Intégration complète GitLab<br>- Runners flexibles<br>- DevOps complet<br>- Auto DevOps | - Courbe d'apprentissage<br>- Ressources importantes<br>- Configuration complexe | Gratuit/Payant | Large |
| **Jenkins** | - Très flexible<br>- Plugins nombreux<br>- Contrôle total<br>- Open source | - Maintenance importante<br>- Sécurité à gérer<br>- Interface vieillissante | Gratuit | Très large |

### 5. Solutions de centralisation des logs

#### Détail des composants

**Stack ELK (Elasticsearch, Logstash, Kibana)**

| Composant | Rôle | Avantages | Inconvénients |
|-----------|------|-----------|---------------|
| **Elasticsearch** | Stockage et recherche | - Recherche full-text puissante<br>- Scalabilité horizontale<br>- Agrégations complexes | - Consommation mémoire élevée<br>- Configuration complexe<br>- Coût de stockage |
| **Logstash** | Collecte et transformation | - Nombreux plugins<br>- Transformations complexes<br>- Pipeline flexible | - Consommation ressources<br>- Configuration complexe<br>- Goulot d'étranglement |
| **Kibana** | Visualisation | - Interface riche<br>- Dashboards avancés<br>- Alertes intégrées | - Courbe d'apprentissage<br>- Performances variables<br>- Consommation ressources |

**Stack Loki + Grafana**

| Composant | Rôle | Avantages | Inconvénients |
|-----------|------|-----------|---------------|
| **Loki** | Stockage logs | - Très économe en ressources<br>- Indexation par labels<br>- Compatible Prometheus<br>- Version 3.5 récente | - Recherche full-text limitée<br>- Fonctionnalités réduites vs ELK<br>- Moins mature qu'Elasticsearch |
| **Grafana Alloy** | Collecte télémétrie | - Collecteur unifié (logs/métriques/traces)<br>- Remplace Promtail<br>- Configuration moderne<br>- Support OpenTelemetry natif | - Nouveau (courbe d'apprentissage)<br>- Documentation en évolution<br>- Complexité accrue |
| **Promtail** | Collecte logs (legacy) | - Léger et éprouvé<br>- Configuration simple<br>- Autodécouverte Kubernetes | - Uniquement logs<br>- Remplacé par Alloy<br>- Fonctionnalités limitées |
| **Grafana** | Visualisation | - Interface moderne<br>- Dashboards flexibles<br>- Alertes avancées | - Principalement pour métriques<br>- Logs en second plan<br>- Moins de fonctionnalités logs |

### 6. Recommandations


| Composant | Recommandation | Justification |
|-----------|----------------|---------------|
| **Kubernetes** | Minikube | **Simplicité et accessibilité :** Idéal pour le développement local, Minikube permet une prise en main rapide de Kubernetes sans les coûts et la complexité d'un cluster cloud. Sa documentation complète en fait un excellent outil d'apprentissage. |
| **Package Manager** | Helm | **Standard de l'industrie et puissance :** Helm est le gestionnaire de paquets de facto pour Kubernetes. Il simplifie la gestion des déploiements complexes grâce à son système de templating et à un vaste écosystème de charts réutilisables. |
| **Scanner vulnérabilités** | Trivy | **Rapidité et intégration facile :** Trivy est reconnu pour sa vitesse d'analyse et sa simplicité d'intégration dans les pipelines CI/CD. Il offre une détection de vulnérabilités complète pour les images de conteneurs, ce qui est essentiel pour une approche DevSecOps. |
| **Analyse code** | SonarQube Community | **Analyse approfondie et suivi qualité :** SonarQube offre une analyse statique complète du code, détectant les bugs, les vulnérabilités et les "code smells". Son interface web permet de suivre l'évolution de la qualité du code de manière centralisée. |
| **CI/CD** | GitHub Actions | **Intégration native et simplicité :** En tant que solution intégrée à GitHub, Actions permet de créer des workflows CI/CD de manière fluide et intuitive. La vaste marketplace d'actions et le généreux plan gratuit en font un choix pragmatique pour ce projet. |
| **Logs** | Loki + Alloy | **Architecture moderne et efficacité :** Cette stack est conçue pour être économique en ressources et nativement intégrée à Kubernetes. Loki indexe uniquement les métadonnées, réduisant les coûts de stockage, tandis que Grafana Alloy est le collecteur de télémétrie unifié de nouvelle génération, assurant une solution d'avenir. |


## Architecture générale

```
Application → Kubernetes → Pipeline DevSecOps → Monitoring & Logs
     ↓              ↓              ↓                    ↓
   Docker      Pod/Service    Security Scan      Loki + Grafana
              Deployment      + Dashboard        + Dashboards
```
