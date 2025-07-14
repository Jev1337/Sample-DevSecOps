# Project Documentation: Flask K8s DevSecOps Platform

[![Documentation Status](https://img.shields.io/badge/docs-latest-brightgreen.svg)](PROJECT_DOCUMENTATION.md)
[![Architecture](https://img.shields.io/badge/architecture-microservices-blue.svg)](#architecture-overview)
[![Security](https://img.shields.io/badge/security-devsecops-red.svg)](#security-implementation)

## 📖 Table of Contents

1. [Project Overview](#1-project-overview)
2. [Architecture & Design](#2-architecture--design)
3. [Automation Framework](#3-automation-framework)
4. [Technical Implementation](#4-technical-implementation)
5. [DevSecOps Pipeline](#5-devsecops-pipeline)
6. [Security Framework](#6-security-framework)
7. [SIEM Integration](#7-siem-integration)
8. [Monitoring & Observability](#8-monitoring--observability)
9. [Deployment Strategies](#9-deployment-strategies)
10. [Configuration Management](#10-configuration-management)
11. [Performance & Scaling](#11-performance--scaling)
12. [Troubleshooting Guide](#12-troubleshooting-guide)

---

## 1. Project Overview

### 1.1 Mission Statement

This project delivers a **production-ready DevSecOps platform** that integrates security, monitoring, and automation into every stage of the software development lifecycle. It demonstrates modern cloud-native practices with Kubernetes orchestration, comprehensive security scanning, and real-time observability.

### 1.2 Key Features & Capabilities

| Feature Category | Capabilities | Technology Stack |
|------------------|--------------|------------------|
| **🏗️ Application Platform** | REST API, Health Checks, Metrics | Flask, Gunicorn, Prometheus |
| **📦 Container Orchestration** | Auto-scaling, Rolling Updates, Self-healing | Kubernetes, Helm, MicroK8s |
| **🔄 CI/CD Pipeline** | Automated Testing, Security Scans, Deployment | Jenkins, GitOps |
| **🔒 Security Integration** | SAST, DAST, Container Scanning, Compliance | SonarQube, Trivy, OWASP |
| **�️ SIEM Platform** | Real-time Security Monitoring, Event Correlation | Custom SIEM, Webhook Receiver |
| **�📊 Observability Stack** | Logging, Monitoring, Alerting, Tracing | Loki, Grafana, Alloy |
| **🤖 Automation Framework** | Infrastructure as Code, Configuration Management | Ansible, Terraform |
| **☁️ Cloud Deployment** | Multi-environment, External Access, Load Balancing | Azure, LoadBalancer |
| **🧪 Development Tools** | Local Development, Testing, Debugging | Docker Compose, pytest |

### 1.3 Target Use Cases

- **Enterprise DevOps Teams** - Streamlined CI/CD with integrated security
- **Cloud Migration Projects** - Kubernetes-native application modernization
- **Security-First Organizations** - Continuous security scanning and compliance
- **Educational Environments** - Learning modern DevSecOps practices
- **Proof-of-Concept Deployments** - Rapid prototyping with production-grade tools

---

## 2. Architecture & Design

### 2.1 System Architecture Overview

```mermaid
graph TB
    subgraph "External Layer"
        EXT1[Internet Traffic]
        EXT2[Developer Workstation]
        EXT3[Azure LoadBalancer]
    end
    
    subgraph "Ingress Layer"
        ING1[Kubernetes Ingress]
        ING2[Local DNS Resolution]
        ING3[TLS Termination]
    end
    
    subgraph "Application Layer"
        APP1[Flask Application]
        APP2[Gunicorn WSGI Server]
        APP3[Prometheus Metrics]
    end
    
    subgraph "Platform Layer"
        PLAT1[Jenkins CI/CD]
        PLAT2[SonarQube Analysis]
        PLAT3[Trivy Security Scan]
    end
    
    subgraph "Data Layer"
        DATA1[Loki Log Storage]
        DATA2[Grafana Dashboards]
        DATA3[PostgreSQL Database]
    end
    
    subgraph "Infrastructure Layer"
        INFRA1[MicroK8s Cluster]
        INFRA2[Docker Registry]
        INFRA3[Persistent Storage]
    end
    
    EXT1 --> ING1
    EXT2 --> ING2
    EXT3 --> ING1
    ING1 --> APP1
    ING2 --> APP1
    APP1 --> APP2
    APP2 --> APP3
    PLAT1 --> APP1
    PLAT2 --> PLAT1
    PLAT3 --> PLAT1
    APP1 --> DATA1
    DATA1 --> DATA2
    PLAT2 --> DATA3
    APP1 --> INFRA1
    PLAT1 --> INFRA2
    DATA1 --> INFRA3
```

### 2.2 Component Interaction Diagram

```mermaid
sequenceDiagram
    participant DEV as Developer
    participant GIT as Git Repository
    participant JEN as Jenkins
    participant SON as SonarQube
    participant TRI as Trivy
    participant REG as Docker Registry
    participant K8S as Kubernetes
    participant MON as Monitoring
    
    DEV->>GIT: Code Push
    GIT->>JEN: Webhook Trigger
    JEN->>JEN: Checkout & Build
    JEN->>SON: Code Quality Analysis
    SON-->>JEN: Quality Report
    JEN->>TRI: Security Scan
    TRI-->>JEN: Vulnerability Report
    JEN->>REG: Build & Push Image
    JEN->>K8S: Deploy Application
    K8S->>MON: Send Logs & Metrics
    MON->>DEV: Alerts & Dashboards
```

### 2.3 Network Architecture

| Component | Network Mode | Port Exposure | Security |
|-----------|--------------|---------------|----------|
| **Flask Application** | ClusterIP | 5000 → 80 | Internal only |
| **Jenkins** | LoadBalancer/Ingress | 8080 | RBAC + Authentication |
| **SonarQube** | LoadBalancer/Ingress | 9000 | Token-based auth |
| **Grafana** | LoadBalancer/Ingress | 3000 | User management |
| **Loki** | ClusterIP | 3100 | Internal access only |
| **PostgreSQL** | ClusterIP | 5432 | Database credentials |

### 2.4 Data Flow Architecture

**Log Aggregation Flow:**

```
Pod Logs → Alloy Agent → Loki Storage → Grafana Visualization
    ↓
Structured JSON → Label Extraction → Time Series → Dashboard Queries
```

**Metrics Collection Flow:**

```
Application Metrics → Prometheus Format → Grafana Scraping → Dashboard Display
```

**Security Scan Flow:**

```
Code Commit → Jenkins Trigger → SonarQube + Trivy → Report Generation → Dashboard Update
```

---

## 3. Automation Framework

### 3.1 Ansible-Driven Deployment

The platform leverages **Ansible** for complete infrastructure automation, providing consistent, reproducible deployments across environments.

**Architecture Overview:**

```mermaid
graph TB
    subgraph "Control Node"
        CLI[./setup.sh CLI]
        ANSIBLE[Ansible Engine]
    end
    
    subgraph "Playbooks"
        MAIN[main.yml - Full Stack]
        CORE[core_services.yml - Jenkins/SonarQube]
        MON[monitoring.yml - Grafana/Loki]
        SIEM[siem.yml - Security Monitoring]
        DEV[development.yml - Docker Compose]
    end
    
    subgraph "Roles"
        PREREQ[prerequisites]
        DOCKER[docker]
        K8S[microk8s]
        JENKINS[jenkins_image]
        MONITORING[monitoring_stack]
        SIEM_ROLE[siem_monitoring]
        AZURE[azure_access]
    end
    
    CLI --> ANSIBLE
    ANSIBLE --> MAIN
    ANSIBLE --> CORE
    ANSIBLE --> MON
    ANSIBLE --> SIEM
    ANSIBLE --> DEV
    
    MAIN --> PREREQ
    MAIN --> DOCKER
    MAIN --> K8S
    MAIN --> JENKINS
    MAIN --> MONITORING
    MAIN --> SIEM_ROLE
    MAIN --> AZURE
```

### 3.2 Ansible Project Structure

```
ansible/
├── ansible.cfg              # Ansible configuration
├── inventory               # Target hosts
├── requirements.yml        # Ansible collections
├── main.yml               # Master playbook
├── siem.yml               # SIEM deployment
├── cleanup.yml            # Environment cleanup
├── playbooks/             # Individual playbooks
│   ├── core_services.yml  # Jenkins + SonarQube
│   ├── monitoring.yml     # Loki + Grafana + Alloy  
│   ├── flask_app.yml      # Application deployment
│   ├── development.yml    # Docker Compose mode
│   └── cleanup.yml        # Cleanup operations
├── roles/                 # Reusable components
│   ├── prerequisites/     # System requirements
│   ├── docker/           # Docker installation
│   ├── microk8s/         # Kubernetes setup
│   ├── jenkins_image/    # Custom Jenkins build
│   ├── monitoring_stack/ # Observability stack
│   ├── siem_monitoring/  # Security monitoring
│   ├── flask_app/        # Application deployment
│   └── azure_access/     # External access config
├── templates/            # Kubernetes manifests
│   ├── jenkins-ingress.yaml.j2
│   ├── grafana-ingress.yaml.j2
│   └── sonarqube-ingress.yaml.j2
└── vars/
    └── main.yml          # Global variables
```

### 3.3 Key Automation Features

| Feature | Implementation | Benefits |
|---------|----------------|----------|
| **Idempotent Operations** | Ansible modules with state checking | Safe re-runs, consistent results |
| **Tagged Execution** | Granular task control with tags | Selective component deployment |
| **Error Handling** | Comprehensive error recovery | Robust deployment process |
| **Configuration Templates** | Jinja2 templating for K8s manifests | Environment-specific configs |
| **Dependency Management** | Proper task ordering and dependencies | Reliable deployment sequence |

### 3.4 Interactive Setup Script

The `setup.sh` script provides a user-friendly interface to Ansible automation:

```bash
🚀 DevSecOps Setup Menu
====================
  1) Check Prerequisites              # Validate system requirements
  2) Install Ansible (if needed)     # Setup Ansible environment
  3) Deploy Individual Components    # Granular component deployment
  4) Deploy Full Production Environment # Complete stack deployment
  5) Deploy SIEM Security Monitoring # Security monitoring setup
  6) Development Mode (Docker Compose) # Local development environment
  7) Show System Status             # Environment health check
  8) Show Access Information        # Service URLs and credentials
  9) Cleanup Options               # Environment cleanup
 10) Exit
```

**Component-Level Deployment:**

```bash
🧩 Component Deployment Menu
============================
  1) Prerequisites & Docker        # System preparation
  2) MicroK8s Setup               # Kubernetes cluster
  3) Core Services                # Jenkins + SonarQube + PostgreSQL
  4) Monitoring Stack             # Loki + Grafana + Alloy
  5) Flask Application            # Main application
  6) SIEM Security Monitoring     # Security event monitoring
  7) Azure External Access        # Cloud connectivity
  8) Return to main menu
```

### 3.5 Deployment Modes

**Production Mode (`main.yml`):**
- Complete infrastructure setup
- Security hardening enabled
- Monitoring and alerting configured
- External access ready

**Development Mode (`development.yml`):**
- Docker Compose based
- Faster startup time
- Debug configurations
- Local development optimized

**Incremental Mode (Component playbooks):**
- Deploy specific services only
- Useful for updates and maintenance
- Minimal resource usage

### 3.6 Configuration Management

**Global Variables (`vars/main.yml`):**

```yaml
# Application configuration
app_name: "flask-k8s-devsecops"
app_version: "latest"
app_namespace: "flask-app"

# External access
domain_suffix: "local"
external_access_enabled: false

# Security settings
enable_network_policies: true
enable_pod_security_policies: true

# Resource limits
default_cpu_limit: "500m"
default_memory_limit: "512Mi"

# Monitoring
monitoring_namespace: "monitoring"
retention_days: 30
```

**Environment-Specific Overrides:**

```yaml
# Development environment
external_access_enabled: false
domain_suffix: "local"
resource_limits_enabled: false

# Production environment  
external_access_enabled: true
domain_suffix: "{{ ansible_default_ipv4.address }}.nip.io"
resource_limits_enabled: true
backup_enabled: true
```

---

## 4. Technical Implementation

### 4.1 Flask Application Architecture

**Application Structure:**

```python
app/
├── app.py                 # Main Flask application
├── requirements.txt       # Python dependencies
├── Dockerfile            # Container definition
├── tests/
│   ├── test_app.py       # Unit tests
│   └── load_test.py      # Performance tests
└── config/
    ├── gunicorn.conf.py  # WSGI server config
    └── logging.conf      # Logging configuration
```

**Core Features Implementation:**

```python
# Structured Logging
def log_structured(level, message, **kwargs):
    log_entry = {
        "timestamp": datetime.utcnow().isoformat(),
        "level": level,
        "message": message,
        "request_id": getattr(request, 'request_id', str(uuid.uuid4())),
        "service": "flask-app",
        "version": "1.0.0",
        **kwargs
    }
    logger.info(json.dumps(log_entry))

# Prometheus Metrics
REQUEST_COUNT = Counter('flask_requests_total', 
                       'Total Flask requests', 
                       ['method', 'endpoint', 'status'])
REQUEST_LATENCY = Histogram('flask_request_duration_seconds', 
                           'Flask request latency', 
                           ['method', 'endpoint'])

# Health Check Endpoint
@app.route('/health')
def health_check():
    return jsonify({
        "status": "healthy",
        "timestamp": datetime.utcnow().isoformat(),
        "version": "1.0.0"
    }), 200
```

### 4.2 Kubernetes Resource Definitions

**Deployment Configuration:**

```yaml
# k8s/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: flask-app
  namespace: flask-app
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 1
  selector:
    matchLabels:
      app: flask-app
  template:
    metadata:
      labels:
        app: flask-app
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        fsGroup: 1000
      containers:
      - name: flask-app
        image: localhost:32000/flask-k8s-app:latest
        ports:
        - containerPort: 5000
        env:
        - name: PORT
          value: "5000"
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: 5000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: 5000
          initialDelaySeconds: 5
          periodSeconds: 5
```

**Horizontal Pod Autoscaler:**

```yaml
# k8s/hpa.yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: flask-app-hpa
  namespace: flask-app
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: flask-app
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
```

### 4.3 Container Security Implementation

**Multi-stage Dockerfile:**

```dockerfile
# app/Dockerfile
FROM python:3.9-slim as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --user --no-cache-dir -r requirements.txt

FROM python:3.9-slim
RUN groupadd -r appuser && useradd -r -g appuser appuser
WORKDIR /app
COPY --from=builder /root/.local /home/appuser/.local
COPY . .
RUN chown -R appuser:appuser /app
USER appuser
ENV PATH=/home/appuser/.local/bin:$PATH
EXPOSE 5000
CMD ["gunicorn", "--config", "gunicorn.conf.py", "app:app"]
```

**Security Contexts:**

```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  runAsGroup: 1000
  fsGroup: 1000
  capabilities:
    drop:
    - ALL
  readOnlyRootFilesystem: true
  allowPrivilegeEscalation: false
```

---

## 5. DevSecOps Pipeline

### 5.1 Jenkins Pipeline Architecture

**Pipeline Stages Overview:**

```groovy
pipeline {
    agent any
    
    environment {
        REGISTRY = 'localhost:32000'
        IMAGE_NAME = 'flask-k8s-app'
        SONAR_TOKEN = credentials('sonar-token')
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
                script {
                    env.BUILD_VERSION = "${env.BUILD_NUMBER}-${env.GIT_COMMIT.take(7)}"
                }
            }
        }
        
        stage('Install Dependencies') {
            steps {
                sh '''
                    cd app
                    python -m venv venv
                    . venv/bin/activate
                    pip install -r requirements.txt
                    pip install pytest pytest-cov flake8
                '''
            }
        }
        
        stage('Run Tests') {
            steps {
                sh '''
                    cd app
                    . venv/bin/activate
                    python -m pytest tests/ -v --cov=. --cov-report=xml --cov-report=html
                    flake8 app.py --max-line-length=88
                '''
            }
            post {
                always {
                    archiveArtifacts artifacts: 'app/htmlcov/**', allowEmptyArchive: true
                    publishHTML([
                        allowMissing: false,
                        alwaysLinkToLastBuild: true,
                        keepAll: true,
                        reportDir: 'app/htmlcov',
                        reportFiles: 'index.html',
                        reportName: 'Coverage Report'
                    ])
                }
            }
        }
        
        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('SonarQube') {
                    sh '''
                        cd app
                        sonar-scanner \
                          -Dsonar.projectKey=flask-k8s-devsecops \
                          -Dsonar.sources=. \
                          -Dsonar.host.url=http://sonarqube.local \
                          -Dsonar.login=${SONAR_TOKEN} \
                          -Dsonar.python.coverage.reportPaths=coverage.xml
                    '''
                }
            }
        }
        
        stage('Security Scan - Filesystem') {
            steps {
                sh '''
                    trivy fs ./app \
                      --format table \
                      --severity HIGH,CRITICAL \
                      --output trivy-fs-report.txt
                '''
                archiveArtifacts artifacts: 'trivy-fs-report.txt'
            }
        }
        
        stage('Build & Push Docker Image') {
            steps {
                script {
                    def image = docker.build("${REGISTRY}/${IMAGE_NAME}:${BUILD_VERSION}", "./app")
                    image.push()
                    image.push("latest")
                }
            }
        }
        
        stage('Security Scan - Image') {
            steps {
                sh '''
                    trivy image ${REGISTRY}/${IMAGE_NAME}:${BUILD_VERSION} \
                      --format table \
                      --severity HIGH,CRITICAL \
                      --output trivy-image-report.txt
                '''
                archiveArtifacts artifacts: 'trivy-image-report.txt'
            }
        }
        
        stage('Deploy to Kubernetes') {
            steps {
                sh '''
                    sed -i "s|image: .*|image: ${REGISTRY}/${IMAGE_NAME}:${BUILD_VERSION}|g" k8s/deployment.yaml
                    microk8s kubectl apply -f k8s/
                    microk8s kubectl rollout status deployment/flask-app -n flask-app --timeout=300s
                '''
            }
        }
    }
    
    post {
        always {
            cleanWs()
        }
        success {
            slackSend(
                channel: '#deployments',
                color: 'good',
                message: "✅ Deployment successful: ${env.JOB_NAME} - ${env.BUILD_NUMBER}"
            )
        }
        failure {
            slackSend(
                channel: '#deployments',
                color: 'danger',
                message: "❌ Deployment failed: ${env.JOB_NAME} - ${env.BUILD_NUMBER}"
            )
        }
    }
}
```

### 5.2 Quality Gates & Policies

**SonarQube Quality Gate Configuration:**

```properties
# security/sonarqube/sonar-project.properties
sonar.projectKey=flask-k8s-devsecops
sonar.projectName=Flask K8s DevSecOps
sonar.projectVersion=1.0

# Source analysis
sonar.sources=app/
sonar.exclusions=**/tests/**,**/venv/**,**/__pycache__/**
sonar.language=py

# Test coverage
sonar.python.coverage.reportPaths=coverage.xml
sonar.python.xunit.reportPath=test-results.xml

# Quality gate thresholds
sonar.qualitygate.wait=true
sonar.qualitygate.timeout=300

# Security rules
sonar.python.bandit.reportPaths=bandit-report.json
```

**Trivy Security Configuration:**

```yaml
# security/trivy/trivy-config.yaml
format: json
severity:
  - HIGH
  - CRITICAL
vulnerability:
  type:
    - os
    - library
secret:
  config:
    - .trivyignore
policy:
  - security/trivy/policies/
```

---

## 6. Security Framework

### 6.1 Security Scanning Integration

**Multi-layered Security Approach:**

| Layer | Tool | Scope | Frequency |
|-------|------|-------|-----------|
| **Code Analysis** | SonarQube | SAST, Code Quality | Every commit |
| **Dependency Scan** | Trivy | Vulnerable libraries | Every build |
| **Container Scan** | Trivy | Image vulnerabilities | Every image push |
| **Infrastructure** | Kubernetes CIS | K8s security benchmarks | Weekly |
| **Runtime Security** | Falco | Behavioral anomalies | Continuous |

### 6.2 Security Policies Implementation

**Pod Security Standards:**

```yaml
# k8s/pod-security-policy.yaml
apiVersion: policy/v1beta1
kind: PodSecurityPolicy
metadata:
  name: flask-app-psp
spec:
  privileged: false
  allowPrivilegeEscalation: false
  requiredDropCapabilities:
    - ALL
  volumes:
    - 'configMap'
    - 'emptyDir'
    - 'projected'
    - 'secret'
    - 'downwardAPI'
    - 'persistentVolumeClaim'
  runAsUser:
    rule: 'MustRunAsNonRoot'
  seLinux:
    rule: 'RunAsAny'
  fsGroup:
    rule: 'RunAsAny'
```

**Network Security Policies:**

```yaml
# k8s/network-policy.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: flask-app-netpol
  namespace: flask-app
spec:
  podSelector:
    matchLabels:
      app: flask-app
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: ingress-nginx
    ports:
    - protocol: TCP
      port: 5000
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          name: monitoring
    ports:
    - protocol: TCP
      port: 3100  # Loki
```

### 6.3 Secrets Management

**Kubernetes Secrets Implementation:**

```yaml
# k8s/secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: flask-app-secrets
  namespace: flask-app
type: Opaque
stringData:
  SECRET_KEY: "your-super-secret-key-here"
  DATABASE_URL: "postgresql://user:password@postgres:5432/dbname"
  API_TOKEN: "your-api-token-here"
  SONAR_TOKEN: "sonarqube-authentication-token"
```

**Secret Rotation Strategy:**

```bash
# Automated secret rotation script
#!/bin/bash
NAMESPACE="flask-app"
SECRET_NAME="flask-app-secrets"

# Generate new secret key
NEW_SECRET_KEY=$(openssl rand -base64 32)

# Update secret
kubectl patch secret $SECRET_NAME -n $NAMESPACE \
  --type='json' \
  -p='[{"op": "replace", "path": "/data/SECRET_KEY", "value": "'$(echo -n $NEW_SECRET_KEY | base64)'"}]'

# Rolling restart to pick up new secret
kubectl rollout restart deployment/flask-app -n $NAMESPACE
```

### 6.4 Security Monitoring & Alerting

**Security Event Detection:**

```yaml
# monitoring/security-rules.yaml
groups:
- name: security.rules
  rules:
  - alert: HighFailedLoginRate
    expr: rate(flask_requests_total{status="401"}[5m]) > 0.1
    for: 2m
    labels:
      severity: warning
    annotations:
      summary: "High failed login rate detected"
      description: "{{ $value }} failed logins per second"

  - alert: SuspiciousUserAgent
    expr: increase(flask_requests_total{user_agent=~".*bot.*|.*scanner.*"}[5m]) > 10
    for: 1m
    labels:
      severity: critical
    annotations:
      summary: "Suspicious user agent detected"
      description: "Potential bot or scanning activity"
```

---

## 7. SIEM Integration

### 7.1 Security Information and Event Management

The integrated SIEM platform provides comprehensive security monitoring, event correlation, and threat detection across the entire DevSecOps pipeline.

**SIEM Architecture:**

```mermaid
graph TB
    subgraph "Data Sources"
        SYS[System Logs<br/>/var/log/*]
        K8S[Kubernetes Audit<br/>API Server logs]
        APP[Application Logs<br/>Container stdout]
        GIT[Git Events<br/>Webhook Receiver]
        CICD[CI/CD Events<br/>Jenkins logs]
    end
    
    subgraph "Collection Layer"
        ALLOY[Grafana Alloy<br/>Unified Collector]
        WEBHOOK[Webhook Receiver<br/>Git Event API]
    end
    
    subgraph "Storage & Processing"
        LOKI[Loki<br/>Log Aggregation]
        PROC[Event Processor<br/>Log parsing & enrichment]
    end
    
    subgraph "Analysis & Visualization"
        GRAFANA[Grafana SIEM Dashboard<br/>Real-time monitoring]
        ALERTS[Alert Manager<br/>Threat notifications]
    end
    
    SYS --> ALLOY
    K8S --> ALLOY
    APP --> ALLOY
    GIT --> WEBHOOK
    CICD --> ALLOY
    
    ALLOY --> LOKI
    WEBHOOK --> LOKI
    LOKI --> PROC
    PROC --> GRAFANA
    GRAFANA --> ALERTS
```

### 7.2 Monitored Security Events

**System-Level Events:**

| Event Type | Source | Description | Risk Level |
|------------|--------|-------------|------------|
| **Authentication** | `/var/log/auth.log` | SSH logins, sudo usage, failed auth | HIGH |
| **Package Management** | `/var/log/dpkg.log` | Software installations/removals | MEDIUM |
| **Kernel Events** | `/var/log/kern.log` | System-level security events | HIGH |
| **Audit Trail** | `auditd` | File access, system calls | MEDIUM |

**Application-Level Events:**

| Event Type | Source | Description | Risk Level |
|------------|--------|-------------|------------|
| **HTTP Errors** | Flask logs | 4xx/5xx error patterns | MEDIUM |
| **Authentication Failures** | Application logs | Login failures, invalid tokens | HIGH |
| **API Abuse** | Access logs | Rate limiting, suspicious patterns | MEDIUM |
| **Error Patterns** | Exception logs | Recurring errors, stack traces | LOW |

**DevOps Pipeline Events:**

| Event Type | Source | Description | Risk Level |
|------------|--------|-------------|------------|
| **Code Changes** | Git Webhooks | Commits, branches, sensitive files | MEDIUM |
| **Build Failures** | Jenkins | Failed builds, security scan failures | MEDIUM |
| **Deployment Events** | K8s Events | Pod crashes, image pulls | LOW |
| **Configuration Changes** | Config Management | Secret updates, policy changes | HIGH |

### 7.3 SIEM Dashboard Components

**Real-Time Security Monitoring Dashboard:**

Located at: `monitoring/grafana/dashboards/siem-real-security.json`

**Panel 1 - Authentication Activity:**
```logql
# SSH Login Success/Failure Rate
rate({job="system-auth"} |= "Accepted" [5m])
rate({job="system-auth"} |= "Failed" [5m])

# Top Failed Login Sources
topk(10, count by (ip) ({job="system-auth"} |= "Failed" | json | count by (ip)))
```

**Panel 2 - System Changes:**
```logql
# Package Installation Activity
{job="package-install"} | json | line_format "{{.timestamp}} - {{.action}}: {{.package}}"

# System Modifications
{job="system-audit"} |= "SYSCALL" | json | count by (user)
```

**Panel 3 - Development Activity:**
```logql
# Git Activity Timeline
{job="webhook-receiver"} | json | line_format "{{.timestamp}} - {{.author}}: {{.message}}"

# Build Success/Failure Rate
rate({job="jenkins"} |= "SUCCESS" [1h])
rate({job="jenkins"} |= "FAILURE" [1h])
```

**Panel 4 - Threat Detection:**
```logql
# Security Incidents
{job=~"system-.*"} |= "ERROR" or "CRITICAL" or "SECURITY"

# Anomaly Detection
rate({job=~".*"} [5m]) > on() group_left() 
(avg_over_time(rate({job=~".*"} [5m])[24h:1h]) * 2)
```

### 7.4 Webhook Receiver Integration

**Git Event Processing:**
