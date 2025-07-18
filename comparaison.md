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
| **Kubernetes** | MicroK8s | **Léger et complet :** MicroK8s offre un environnement Kubernetes complet avec une faible empreinte mémoire, ce qui le rend idéal pour le développement local et les pipelines CI/CD. Il est facile à installer et inclut des addons pour les fonctionnalités essentielles. |
| **Package Manager** | Helm | **Standard de l'industrie et puissance :** Helm est le gestionnaire de paquets de facto pour Kubernetes. Il simplifie la gestion des déploiements complexes grâce à son système de templating et à un vaste écosystème de charts réutilisables. |
| **Scanner vulnérabilités** | Trivy | **Rapidité et intégration facile :** Trivy est reconnu pour sa vitesse d'analyse et sa simplicité d'intégration dans les pipelines CI/CD. Il offre une détection de vulnérabilités complète pour les images de conteneurs, ce qui est essentiel pour une approche DevSecOps. |
| **Analyse code** | SonarQube Community | **Analyse approfondie et suivi qualité :** SonarQube offre une analyse statique complète du code, détectant les bugs, les vulnérabilités et les "code smells". Son interface web permet de suivre l'évolution de la qualité du code de manière centralisée. |
| **CI/CD** | Jenkins | **Flexibilité et extensibilité :** Jenkins est un standard de l'industrie pour l'automatisation CI/CD. Sa nature open-source et son immense écosystème de plugins permettent de construire des pipelines sur mesure, hautement flexibles et capables de s'intégrer avec pratiquement n'importe quel outil. |
| **Logs** | Loki + Alloy | **Architecture moderne et efficacité :** Cette stack est conçue pour être économique en ressources et nativement intégrée à Kubernetes. Loki indexe uniquement les métadonnées, réduisant les coûts de stockage, tandis que Grafana Alloy est le collecteur de télémétrie unifié de nouvelle génération, assurant une solution d'avenir. |


### 7. Infrastructure as Code et Automation

| Solution | Type | Avantages | Inconvénients | Cas d'usage | Complexité |
|----------|------|-----------|---------------|-------------|------------|
| **Ansible** | Configuration Management | - Agentless<br>- Syntax YAML simple<br>- Idempotent<br>- Large écosystème modules | - Performance sur gros inventaires<br>- Debugging parfois difficile<br>- Pas de state management | Configuration serveurs<br>Déploiement applications<br>Orchestration | Faible |
| **Terraform** | Infrastructure Provisioning | - Multi-cloud<br>- State management<br>- Plan/Apply workflow<br>- Écosystème providers riche | - Courbe d'apprentissage<br>- State file management<br>- Pas pour configuration OS | Provisioning cloud<br>Infrastructure immutable<br>Multi-environnements | Moyenne |
| **Kubernetes Manifests** | Container Orchestration | - Déclaratif natif<br>- Contrôle granulaire<br>- Pas de dépendances<br>- Standard Kubernetes | - Verbose<br>- Duplication configuration<br>- Maintenance complexe | Déploiement K8s simple<br>Contrôle total<br>Debugging | Faible |
| **Helm Charts** | Package Management K8s | - Templating puissant<br>- Gestion versions<br>- Écosystème charts<br>- Release management | - Complexité templates<br>- Debugging difficile<br>- Courbe apprentissage | Applications complexes<br>Réutilisabilité<br>Paramétrage multi-env | Moyenne |

### 8. SIEM et Monitoring de Sécurité

| Solution | Type | Avantages | Inconvénients | Coût | Intégration |
|----------|------|-----------|---------------|------|-------------|
| **ELK Stack** | SIEM Complet | - Recherche puissante<br>- Scalabilité<br>- Écosystème riche<br>- Visualisations avancées | - Ressources importantes<br>- Complexité configuration<br>- Coût infrastructure | Gratuit/Payant | Complexe |
| **Splunk** | SIEM Entreprise | - Fonctionnalités complètes<br>- Performance<br>- Support professionnel<br>- Intégrations nombreuses | - Coût très élevé<br>- Courbe apprentissage<br>- Vendor lock-in | Payant (cher) | Moyenne |
| **Grafana Loki + Alloy** | Log Aggregation + SIEM | - Économique ressources<br>- Intégration native K8s<br>- Configuration simple<br>- Stack unifié | - Fonctionnalités SIEM limitées<br>- Recherche full-text réduite<br>- Moins mature | Gratuit | Simple |
| **Security Onion** | SIEM Open Source | - Suite complète gratuite<br>- Network monitoring<br>- IDS/IPS intégré<br>- Prêt à l'emploi | - Ressources importantes<br>- Configuration complexe<br>- Interface dépassée | Gratuit | Complexe |

### 9. Recommandations Mises à Jour (2025)

| Composant | Recommandation | Justification Mise à Jour |
|-----------|----------------|---------------------------|
| **Automation** | Ansible | **Simplicité et adoption :** Ansible reste le choix optimal pour l'automation grâce à sa syntaxe YAML accessible, son approche agentless et sa capacité à gérer aussi bien l'infrastructure que les applications. Idéal pour les équipes DevOps de toutes tailles. |
| **SIEM** | Loki + Alloy + Custom Dashboard | **Approche pragmatique :** Pour la plupart des projets, une solution basée sur Loki avec Grafana Alloy offre un excellent rapport coût/bénéfice. Le dashboard SIEM personnalisé apporte les fonctionnalités essentielles sans la complexité des solutions entreprise. |
| **IaC Cloud** | Terraform + Ansible | **Complémentarité :** Terraform pour le provisioning d'infrastructure cloud (immutable) et Ansible pour la configuration des services (mutable). Cette approche hybride maximise les avantages de chaque outil. |
| **Package Management** | Helm (confirmé) | **Maturité croissante :** Helm 3.x a résolu les problèmes de sécurité de Tiller et reste l'standard pour Kubernetes. L'écosystème de charts continue de croître. |
| **Observabilité** | Loki + Grafana + Alloy | **Stack moderne :** Grafana Alloy (successeur de Promtail) offre une collecte unifiée logs/métriques/traces. Cette stack est désormais mature et recommandée pour les nouveaux projets. |

## Architecture générale mise à jour (2025)

```mermaid
graph TB
    subgraph "Development"
        DEV[Developer] --> GIT[Git Repository]
        GIT --> WEBHOOK[Webhook Events]
    end
    
    subgraph "Infrastructure (Terraform + Ansible)"
        TERRA[Terraform<br/>Infrastructure Provisioning]
        ANSIBLE[Ansible<br/>Configuration Management]
        TERRA --> ANSIBLE
    end
    
    subgraph "Kubernetes Cluster (MicroK8s)"
        APP[Flask Application<br/>+ Helm Chart]
        JENKINS[Jenkins CI/CD<br/>+ Pipeline]
        SONAR[SonarQube<br/>Code Analysis]
    end
    
    subgraph "Security Pipeline"
        TRIVY[Trivy<br/>Vulnerability Scan]
        AUDIT[Security Audit<br/>K8s Policies]
        JENKINS --> TRIVY
        JENKINS --> SONAR
        JENKINS --> AUDIT
    end
    
    subgraph "SIEM & Monitoring (Loki Stack)"
        ALLOY[Grafana Alloy<br/>Unified Collector]
        LOKI[Loki<br/>Log Storage]
        GRAFANA[Grafana<br/>Dashboards + SIEM]
        ALERTS[Alert Manager<br/>Notifications]
        
        ALLOY --> LOKI
        LOKI --> GRAFANA
        GRAFANA --> ALERTS
    end
    
    GIT --> JENKINS
    WEBHOOK --> ALLOY
    TERRAFORM --> APP
    ANSIBLE --> APP
    APP --> ALLOY
    JENKINS --> ALLOY
    SONAR --> ALLOY
    AUDIT --> ALLOY
```

### Stack technologique finale retenue

| Couche | Technologie | Version | Rôle |
|--------|-------------|---------|------|
| **Application** | Flask + Gunicorn | 2.3+ | API REST, métriques |
| **Containerisation** | Docker + BuildKit | 24.0+ | Images sécurisées |
| **Orchestration** | MicroK8s | 1.30+ | Cluster Kubernetes |
| **Package Management** | Helm | 3.8+ | Déploiement K8s |
| **CI/CD** | Jenkins | 2.452+ | Pipeline automatisé |
| **Code Quality** | SonarQube Community | Latest | Analyse statique |
| **Security Scan** | Trivy | Latest | Vulnérabilités |
| **Log Management** | Loki + Alloy | 3.0+ | Logs centralisés |
| **Monitoring** | Grafana | 10.0+ | Dashboards + SIEM |
| **Infrastructure** | Terraform | 1.5+ | Provisioning cloud |
| **Configuration** | Ansible | 2.15+ | Automation |
| **Cloud Platform** | Azure | - | Infrastructure cloud |
