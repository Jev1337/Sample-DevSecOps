# Project Documentation: Flask K8s DevSecOps Platform

[![Documentation Status](https://img.shields.io/badge/docs-latest-brightgreen.svg)](PROJECT_DOCUMENTATION.md)
[![Architecture](https://img.shields.io/badge/architecture-microservices-blue.svg)](#architecture-overview)
[![Security](https://img.shields.io/badge/security-devsecops-red.svg)](#security-implementation)

## 📖 Table of Contents

1. [Project Overview](#1-project-overview)
2. [Architecture & Design](#2-architecture--design)
3. [Technical Implementation](#3-technical-implementation)
4. [DevSecOps Pipeline](#4-devsecops-pipeline)
5. [Security Framework](#5-security-framework)
6. [Monitoring & Observability](#6-monitoring--observability)
7. [Deployment Strategies](#7-deployment-strategies)
8. [Configuration Management](#8-configuration-management)
9. [Performance & Scaling](#9-performance--scaling)
10. [Troubleshooting Guide](#10-troubleshooting-guide)

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
| **📊 Observability Stack** | Logging, Monitoring, Alerting, Tracing | Loki, Grafana, Alloy |
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

## 3. Technical Implementation

### 3.1 Flask Application Architecture

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

### 3.2 Kubernetes Resource Definitions

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

### 3.3 Container Security Implementation

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

## 4. DevSecOps Pipeline

### 4.1 Jenkins Pipeline Architecture

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

### 4.2 Quality Gates & Policies

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

## 5. Security Framework

### 5.1 Security Scanning Integration

**Multi-layered Security Approach:**

| Layer | Tool | Scope | Frequency |
|-------|------|-------|-----------|
| **Code Analysis** | SonarQube | SAST, Code Quality | Every commit |
| **Dependency Scan** | Trivy | Vulnerable libraries | Every build |
| **Container Scan** | Trivy | Image vulnerabilities | Every image push |
| **Infrastructure** | Kubernetes CIS | K8s security benchmarks | Weekly |
| **Runtime Security** | Falco | Behavioral anomalies | Continuous |

### 5.2 Security Policies Implementation

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

### 5.3 Secrets Management

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

### 5.4 Security Monitoring & Alerting

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

## 6. Monitoring & Observability

### 6.1 Logging Architecture

**Structured Logging Implementation:**

```python
# Enhanced logging configuration
import structlog
import logging.config

LOGGING_CONFIG = {
    'version': 1,
    'disable_existing_loggers': False,
    'formatters': {
        'json': {
            'format': '%(message)s'
        }
    },
    'handlers': {
        'console': {
            'class': 'logging.StreamHandler',
            'formatter': 'json',
            'stream': 'ext://sys.stdout'
        }
    },
    'loggers': {
        '': {
            'handlers': ['console'],
            'level': 'INFO',
            'propagate': False
        }
    }
}

# Configure structured logging
structlog.configure(
    processors=[
        structlog.stdlib.filter_by_level,
        structlog.stdlib.add_logger_name,
        structlog.stdlib.add_log_level,
        structlog.stdlib.PositionalArgumentsFormatter(),
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.processors.StackInfoRenderer(),
        structlog.processors.format_exc_info,
        structlog.processors.UnicodeDecoder(),
        structlog.processors.JSONRenderer()
    ],
    context_class=dict,
    logger_factory=structlog.stdlib.LoggerFactory(),
    wrapper_class=structlog.stdlib.BoundLogger,
    cache_logger_on_first_use=True,
)
```

### 6.2 Grafana Dashboard Configuration

**Application Performance Dashboard:**

```json
{
  "dashboard": {
    "title": "Flask Application Performance",
    "panels": [
      {
        "title": "Request Rate",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(flask_requests_total[5m])",
            "legendFormat": "{{method}} {{endpoint}}"
          }
        ]
      },
      {
        "title": "Response Time P95",
        "type": "graph",
        "targets": [
          {
            "expr": "histogram_quantile(0.95, flask_request_duration_seconds_bucket)",
            "legendFormat": "95th percentile"
          }
        ]
      },
      {
        "title": "Error Rate",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(flask_requests_total{status=~\"5..\"}[5m])",
            "legendFormat": "5xx errors"
          }
        ]
      }
    ]
  }
}
```

**Log Analysis Dashboard:**

```json
{
  "dashboard": {
    "title": "Application Logs Analysis",
    "panels": [
      {
        "title": "Log Volume by Level",
        "type": "bargauge",
        "targets": [
          {
            "expr": "sum by (level) (count_over_time({namespace=\"flask-app\"} [1h]))",
            "legendFormat": "{{level}}"
          }
        ]
      },
      {
        "title": "Recent Error Logs",
        "type": "logs",
        "targets": [
          {
            "expr": "{namespace=\"flask-app\", level=\"ERROR\"}"
          }
        ]
      }
    ]
  }
}
```

### 6.3 Alerting Strategy

**Alert Rule Configuration:**

```yaml
# monitoring/alert-rules.yaml
groups:
- name: application.rules
  rules:
  - alert: HighErrorRate
    expr: rate(flask_requests_total{status=~"5.."}[5m]) > 0.05
    for: 2m
    labels:
      severity: critical
    annotations:
      summary: "High error rate in Flask application"
      description: "Error rate is {{ $value | humanizePercentage }}"

  - alert: HighLatency
    expr: histogram_quantile(0.95, flask_request_duration_seconds_bucket) > 2
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "High request latency"
      description: "95th percentile latency is {{ $value }}s"

  - alert: PodCrashLooping
    expr: rate(kube_pod_container_status_restarts_total[15m]) > 0
    for: 5m
    labels:
      severity: critical
    annotations:
      summary: "Pod is crash looping"
      description: "Pod {{ $labels.pod }} is restarting frequently"
```

---

## 7. Deployment Strategies

### 7.1 Environment Management

**Multi-Environment Configuration:**

```bash
# Environment-specific deployments
environments/
├── development/
│   ├── kustomization.yaml
│   ├── deployment-patch.yaml
│   └── configmap.yaml
├── staging/
│   ├── kustomization.yaml
│   ├── deployment-patch.yaml
│   └── configmap.yaml
└── production/
    ├── kustomization.yaml
    ├── deployment-patch.yaml
    └── configmap.yaml
```

**Kustomization for Environment-Specific Config:**

```yaml
# environments/production/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
- ../../k8s/

patchesStrategicMerge:
- deployment-patch.yaml

configMapGenerator:
- name: flask-app-config
  files:
  - app.properties

images:
- name: flask-k8s-app
  newTag: v1.0.0-prod
```

### 7.2 Blue-Green Deployment

**Blue-Green Strategy Implementation:**

```yaml
# Blue-Green deployment script
#!/bin/bash
NAMESPACE="flask-app"
NEW_VERSION=$1
CURRENT_VERSION=$(kubectl get deployment flask-app -n $NAMESPACE -o jsonpath='{.spec.template.spec.containers[0].image}' | cut -d':' -f2)

# Deploy green version
kubectl set image deployment/flask-app-green flask-app=localhost:32000/flask-k8s-app:$NEW_VERSION -n $NAMESPACE

# Wait for rollout
kubectl rollout status deployment/flask-app-green -n $NAMESPACE --timeout=300s

# Health check
HEALTH_CHECK=$(curl -s http://flask-app-green.flask-app.svc.cluster.local/health | jq -r '.status')

if [ "$HEALTH_CHECK" = "healthy" ]; then
    # Switch traffic to green
    kubectl patch service flask-app -n $NAMESPACE -p '{"spec":{"selector":{"version":"green"}}}'
    echo "✅ Traffic switched to green version $NEW_VERSION"
    
    # Cleanup blue version
    kubectl delete deployment flask-app-blue -n $NAMESPACE
else
    echo "❌ Health check failed, keeping blue version"
    exit 1
fi
```

### 7.3 Canary Deployment

**Istio Canary Configuration:**

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: flask-app-canary
  namespace: flask-app
spec:
  http:
  - match:
    - headers:
        canary:
          exact: "true"
    route:
    - destination:
        host: flask-app
        subset: v2
  - route:
    - destination:
        host: flask-app
        subset: v1
      weight: 90
    - destination:
        host: flask-app
        subset: v2
      weight: 10
```

---

## 8. Configuration Management

### 8.1 Helm Chart Architecture

**Chart Structure:**

```
helm/flask-app/
├── Chart.yaml
├── values.yaml
├── values-dev.yaml
├── values-staging.yaml
├── values-prod.yaml
├── templates/
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── ingress.yaml
│   ├── configmap.yaml
│   ├── secret.yaml
│   ├── hpa.yaml
│   └── NOTES.txt
└── charts/
    └── postgresql/
```

**Values Configuration:**

```yaml
# helm/flask-app/values.yaml
replicaCount: 3

image:
  repository: localhost:32000/flask-k8s-app
  tag: latest
  pullPolicy: Always

service:
  type: ClusterIP
  port: 80
  targetPort: 5000

ingress:
  enabled: true
  className: "nginx"
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
  hosts:
    - host: flask-app.local
      paths:
        - path: /
          pathType: Prefix
  tls: []

resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 250m
    memory: 256Mi

autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70
  targetMemoryUtilizationPercentage: 80

nodeSelector: {}
tolerations: []
affinity: {}

monitoring:
  enabled: true
  serviceMonitor:
    enabled: true
    interval: 30s
    path: /metrics

security:
  podSecurityContext:
    runAsNonRoot: true
    runAsUser: 1000
    fsGroup: 1000
  securityContext:
    allowPrivilegeEscalation: false
    capabilities:
      drop:
      - ALL
    readOnlyRootFilesystem: true
```

### 8.2 Configuration Templating

**Dynamic Configuration Templates:**

```yaml
# templates/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "flask-app.fullname" . }}
  labels:
    {{- include "flask-app.labels" . | nindent 4 }}
spec:
  {{- if not .Values.autoscaling.enabled }}
  replicas: {{ .Values.replicaCount }}
  {{- end }}
  selector:
    matchLabels:
      {{- include "flask-app.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      {{- with .Values.podAnnotations }}
      annotations:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      labels:
        {{- include "flask-app.selectorLabels" . | nindent 8 }}
    spec:
      {{- with .Values.imagePullSecrets }}
      imagePullSecrets:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      securityContext:
        {{- toYaml .Values.security.podSecurityContext | nindent 8 }}
      containers:
        - name: {{ .Chart.Name }}
          securityContext:
            {{- toYaml .Values.security.securityContext | nindent 12 }}
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          ports:
            - name: http
              containerPort: {{ .Values.service.targetPort }}
              protocol: TCP
          livenessProbe:
            httpGet:
              path: /health
              port: http
            initialDelaySeconds: 30
            periodSeconds: 10
          readinessProbe:
            httpGet:
              path: /health
              port: http
            initialDelaySeconds: 5
            periodSeconds: 5
          resources:
            {{- toYaml .Values.resources | nindent 12 }}
```

---

## 9. Performance & Scaling

### 9.1 Performance Optimization

**Application-Level Optimizations:**

```python
# Performance optimization techniques
from flask_caching import Cache
from werkzeug.middleware.profiler import ProfilerMiddleware

# Caching configuration
cache = Cache(app, config={
    'CACHE_TYPE': 'redis',
    'CACHE_REDIS_URL': 'redis://redis:6379/0',
    'CACHE_DEFAULT_TIMEOUT': 300
})

# Database connection pooling
from sqlalchemy import create_engine
from sqlalchemy.pool import QueuePool

engine = create_engine(
    DATABASE_URL,
    poolclass=QueuePool,
    pool_size=10,
    max_overflow=20,
    pool_pre_ping=True
)

# Request compression
from flask_compress import Compress
Compress(app)

# Profiling in development
if app.config.get('PROFILING', False):
    app.wsgi_app = ProfilerMiddleware(
        app.wsgi_app,
        profile_dir='./profiles'
    )
```

**Gunicorn Production Configuration:**

```python
# gunicorn.conf.py
bind = "0.0.0.0:5000"
workers = 4
worker_class = "gevent"
worker_connections = 1000
max_requests = 1000
max_requests_jitter = 100
timeout = 30
keepalive = 2
preload_app = True

# Logging
accesslog = "-"
errorlog = "-"
loglevel = "info"
access_log_format = '%(h)s %(l)s %(u)s %(t)s "%(r)s" %(s)s %(b)s "%(f)s" "%(a)s" %(D)s'

# Process management
daemon = False
pidfile = "/tmp/gunicorn.pid"
user = "appuser"
group = "appuser"
tmp_upload_dir = None

# SSL (if needed)
# keyfile = "/path/to/keyfile"
# certfile = "/path/to/certfile"
```

### 9.2 Kubernetes Scaling Strategies

**Vertical Pod Autoscaler:**

```yaml
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: flask-app-vpa
  namespace: flask-app
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: flask-app
  updatePolicy:
    updateMode: "Auto"
  resourcePolicy:
    containerPolicies:
    - containerName: flask-app
      minAllowed:
        cpu: 100m
        memory: 128Mi
      maxAllowed:
        cpu: 1000m
        memory: 1Gi
      controlledResources: ["cpu", "memory"]
```

**Cluster Autoscaler Configuration:**

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: cluster-autoscaler-status
  namespace: kube-system
data:
  nodes.max: "10"
  nodes.min: "2"
  scale-down-delay-after-add: "10m"
  scale-down-unneeded-time: "10m"
  skip-nodes-with-local-storage: "false"
  skip-nodes-with-system-pods: "false"
```

### 9.3 Performance Monitoring

**Custom Metrics for Scaling:**

```python
# Custom business metrics for HPA
from prometheus_client import Gauge, Counter

# Business metrics
active_users = Gauge('flask_active_users', 'Number of active users')
queue_length = Gauge('flask_queue_length', 'Length of processing queue')
response_size = Gauge('flask_response_size_bytes', 'Response size in bytes')

# Performance metrics
database_connections = Gauge('flask_db_connections', 'Active database connections')
cache_hit_rate = Gauge('flask_cache_hit_rate', 'Cache hit rate percentage')
```

**Performance Testing Integration:**

```python
# tests/performance_test.py
import time
import requests
import concurrent.futures
from locust import HttpUser, task, between

class FlaskLoadTest(HttpUser):
    wait_time = between(1, 3)
    
    @task(3)
    def get_users(self):
        self.client.get("/api/users")
    
    @task(1)
    def create_user(self):
        payload = {
            "name": "Test User",
            "email": "test@example.com"
        }
        self.client.post("/api/users", json=payload)
    
    @task(1)
    def health_check(self):
        self.client.get("/health")

# Performance baseline test
def test_response_time_baseline():
    """Ensure response time is under 200ms for 95% of requests"""
    response_times = []
    
    for _ in range(100):
        start_time = time.time()
        response = requests.get("http://flask-app.local/health")
        end_time = time.time()
        
        assert response.status_code == 200
        response_times.append(end_time - start_time)
    
    # 95th percentile should be under 200ms
    response_times.sort()
    p95_time = response_times[94]  # 95th percentile
    assert p95_time < 0.2, f"95th percentile response time {p95_time:.3f}s exceeds 200ms"
```

---

## 10. Troubleshooting Guide

### 10.1 Common Issues & Solutions

**Issue: Pods Stuck in Pending State**

```bash
# Diagnosis
kubectl describe pod <pod-name> -n <namespace>
kubectl get events -n <namespace> --sort-by='.lastTimestamp'

# Common causes & solutions
# 1. Resource constraints
kubectl top nodes
kubectl describe nodes

# 2. Image pull issues
kubectl describe pod <pod-name> -n <namespace> | grep -A 10 "Events:"

# 3. Scheduling issues
kubectl get pod <pod-name> -n <namespace> -o yaml | grep -A 5 nodeSelector
```

**Issue: High Memory Usage**

```bash
# Memory analysis
kubectl top pods -n flask-app --sort-by=memory
kubectl describe pod <pod-name> -n flask-app

# Memory profiling
kubectl exec -it <pod-name> -n flask-app -- python -m memory_profiler app.py

# Solution: Tune memory limits
kubectl patch deployment flask-app -n flask-app -p \
'{"spec":{"template":{"spec":{"containers":[{"name":"flask-app","resources":{"limits":{"memory":"1Gi"}}}]}}}}'
```

**Issue: Application Not Responding**

```bash
# Check application health
kubectl get pods -n flask-app
kubectl logs -f deployment/flask-app -n flask-app

# Port forwarding for direct access
kubectl port-forward service/flask-app 8080:80 -n flask-app

# Test application directly
curl http://localhost:8080/health

# Check ingress
kubectl get ingress -n flask-app
kubectl describe ingress flask-app-ingress -n flask-app
```

### 10.2 Debugging Techniques

**Application Debugging:**

```python
# Enhanced debugging configuration
import logging
import sys

# Debug logging setup
if app.config.get('DEBUG', False):
    logging.basicConfig(
        level=logging.DEBUG,
        format='%(asctime)s %(name)s %(levelname)s: %(message)s',
        handlers=[
            logging.StreamHandler(sys.stdout),
            logging.FileHandler('/tmp/flask-debug.log')
        ]
    )
    
    # Enable Werkzeug debugger
    app.config['DEBUG'] = True
    app.config['TESTING'] = True

# Request debugging middleware
@app.before_request
def debug_request():
    if app.debug:
        logger.debug(f"Request: {request.method} {request.url}")
        logger.debug(f"Headers: {dict(request.headers)}")
        if request.is_json:
            logger.debug(f"JSON: {request.get_json()}")

@app.after_request
def debug_response(response):
    if app.debug:
        logger.debug(f"Response: {response.status_code}")
        logger.debug(f"Headers: {dict(response.headers)}")
    return response
```

**Kubernetes Debugging Commands:**

```bash
# Complete cluster status
kubectl cluster-info
kubectl get all -A
kubectl get events -A --sort-by='.lastTimestamp'

# Resource usage analysis
kubectl top nodes
kubectl top pods -A --sort-by=cpu
kubectl top pods -A --sort-by=memory

# Network debugging
kubectl get svc,endpoints -A
kubectl describe ingress -A

# Storage debugging
kubectl get pv,pvc -A
kubectl describe pv <pv-name>

# Node debugging
kubectl describe nodes
kubectl get nodes -o yaml

# Debugging specific deployment
kubectl rollout history deployment/flask-app -n flask-app
kubectl rollout status deployment/flask-app -n flask-app
kubectl describe deployment flask-app -n flask-app
```

### 10.3 Recovery Procedures

**Database Recovery:**

```bash
# PostgreSQL recovery for SonarQube
kubectl get pods -n sonarqube
kubectl exec -it postgresql-0 -n sonarqube -- pg_dump -U postgres sonarqube > backup.sql

# Restore from backup
kubectl exec -i postgresql-0 -n sonarqube -- psql -U postgres sonarqube < backup.sql
```

**Application Recovery:**

```bash
# Rolling restart
kubectl rollout restart deployment/flask-app -n flask-app

# Rollback to previous version
kubectl rollout undo deployment/flask-app -n flask-app

# Scale down and up
kubectl scale deployment flask-app --replicas=0 -n flask-app
kubectl scale deployment flask-app --replicas=3 -n flask-app

# Force pod recreation
kubectl delete pod -l app=flask-app -n flask-app
```

**Monitoring Recovery:**

```bash
# Restart monitoring stack
kubectl rollout restart deployment/grafana -n monitoring
kubectl rollout restart statefulset/loki -n monitoring
kubectl rollout restart daemonset/alloy -n monitoring

# Clear monitoring data
kubectl delete pvc -l app=loki -n monitoring
kubectl delete pvc -l app=grafana -n monitoring
```

### 10.4 Performance Troubleshooting

**Slow Response Times:**

```bash
# Application profiling
kubectl exec -it <pod-name> -n flask-app -- python -m cProfile -o profile.stats app.py

# Database query analysis
kubectl exec -it postgresql-0 -n sonarqube -- psql -U postgres -c "
  SELECT query, mean_time, calls 
  FROM pg_stat_statements 
  ORDER BY mean_time DESC 
  LIMIT 10;"

# Resource bottleneck identification
kubectl top pods -n flask-app
kubectl describe pod <pod-name> -n flask-app | grep -A 5 "Limits\|Requests"
```

**Memory Leaks:**

```python
# Memory monitoring in application
import psutil
import gc

@app.route('/debug/memory')
def memory_usage():
    if not app.debug:
        abort(403)
    
    process = psutil.Process()
    memory_info = process.memory_info()
    
    return jsonify({
        'rss': memory_info.rss,
        'vms': memory_info.vms,
        'percent': process.memory_percent(),
        'objects': len(gc.get_objects())
    })
```

---

## 📚 Additional Resources

### Documentation Links
- [Kubernetes Official Documentation](https://kubernetes.io/docs/)
- [Jenkins Pipeline Documentation](https://www.jenkins.io/doc/book/pipeline/)
- [SonarQube Documentation](https://docs.sonarqube.org/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Trivy Documentation](https://aquasecurity.github.io/trivy/)

### Best Practices
- [12-Factor App Methodology](https://12factor.net/)
- [Kubernetes Security Best Practices](https://kubernetes.io/docs/concepts/security/)
- [Container Security Best Practices](https://cloud.google.com/solutions/best-practices-for-building-containers)
- [DevSecOps Guidelines](https://owasp.org/www-project-devsecops-guideline/)

### Community Resources
- [CNCF Landscape](https://landscape.cncf.io/)
- [Kubernetes Community](https://kubernetes.io/community/)
- [DevOps Toolkit](https://www.devopstoolkitseries.com/)

---

<div align="center">

**📖 This documentation is continuously updated to reflect the latest best practices and improvements.**

[🐛 Report Documentation Issue](https://github.com/username/repo/issues) • [💡 Suggest Improvement](https://github.com/username/repo/issues) • [📧 Contact Team](mailto:team@example.com)

</div>

## 3. File-by-File Explanation

### Root Directory
- `README.md`: Project summary, features, and quick start.
- `comparaison.md`/`comparaison.pdf`: Comparative analysis of Kubernetes solutions and package managers.
- `docker-compose.yml`: Local development stack for Flask, SonarQube, Loki, Grafana, and Alloy.
- `setup.sh`: Automated setup script for MicroK8s, namespaces, and core services.

### Application (`app/`)
- `app.py`: Main Flask application. Implements REST endpoints, Prometheus metrics, structured logging, and error handling.
- `requirements.txt`: Python dependencies for the Flask app.
- `Dockerfile`: Builds a secure, non-root container image for the Flask app using Gunicorn.
- `tests/test_app.py`: Pytest-based unit and integration tests for all API endpoints.

### Kubernetes Manifests (`k8s/`)
- `namespace.yaml`: Defines the `flask-app` namespace.
- `configmap.yaml`: Application configuration (environment variables).
- `secret.yaml`: Encoded secrets for the Flask app (e.g., secret key, DB password, API token).
- `deployment.yaml`: Standard deployment manifest for the Flask app.
- `service.yaml`: ClusterIP service exposing the Flask app on port 80.
- `hpa.yaml`: Horizontal Pod Autoscaler for dynamic scaling based on CPU/memory.
- `ingress.yaml`: Ingress resource for external access to the Flask app.

### Helm Configurations (`helm/`)
- This directory contains the externalized Helm `values.yaml` files for the services deployed by the `setup.sh` script. This approach separates configuration from the setup logic, making the configurations easier to manage and customize.
- `helm/jenkins/values.yaml`: Custom values for the Jenkins Helm chart.
- `helm/sonarqube/values.yaml`: Custom values for the SonarQube Helm chart.
- `helm/loki/values.yaml`: Custom values for the Loki Helm chart.
- `helm/grafana/values.yaml`: Custom values for the Grafana Helm chart.
- `helm/alloy/values.yaml`: Custom values for the Alloy Helm chart.

### Jenkins Pipeline (`jenkins/`)
- `Jenkinsfile`: Declarative pipeline for SCM checkout, dependency install, testing, SonarQube and Trivy scans, Docker build/push, and Kubernetes deployment.

### Security (`security/`)
- `sonarqube/sonar-project.properties`: SonarQube project configuration for Python code analysis.
- `trivy/trivy-config.yaml`: Trivy configuration for vulnerability scanning.
- `reports/security-dashboard.html`: HTML dashboard summarizing security scan results.

### Monitoring (`monitoring/`)
- `grafana/ingress.yaml`: Ingress for Grafana dashboard access.
- `grafana/dashboards/app-logs.json`: Grafana dashboard for application logs.
- `grafana/dashboards/security.json`: Grafana dashboard for security events.

## 4. Technical Setup Guide

### Prerequisites
- Docker 24.0+
- MicroK8s 1.30+
- Helm 3.8+
- Git, Snap (for Linux)

### Step-by-Step Setup

1. **Check Prerequisites**
   - Ensure `snap`, `git`, and `docker` are installed.

2. **Install and Configure MicroK8s**
   - Install MicroK8s if not present.
   - Wait for MicroK8s to be ready: `microk8s status --wait-ready`
   - Enable required addons:
     - `microk8s enable dns`
     - `microk8s enable helm3`
     - `microk8s enable ingress`
     - `microk8s enable metrics-server`
     - `microk8s enable storage`
     - `microk8s enable registry --size 20Gi`

3. **Deploy Core Services**
   - Create namespaces:
     - `microk8s kubectl apply -f k8s/namespace.yaml`
     - `microk8s kubectl create ns jenkins` (if not exists)
     - `microk8s kubectl create ns sonarqube` (if not exists)
   - Deploy Jenkins and SonarQube using Helm with custom values files.
   - Wait for Jenkins and SonarQube to be ready using `kubectl rollout status`.

4. **Deploy Application and Monitoring Stack**
   - Deploy Flask app using direct Kubernetes manifests:
     - `microk8s kubectl apply -f k8s/`
   - Deploy monitoring stack (Loki, Grafana, Alloy) using Helm with custom values.
   - Expose services via ingress for dashboard access.

5. **CI/CD Pipeline**
   - Jenkins pipeline automates build, test, scan, and deployment steps.
   - SonarQube and Trivy scans are integrated for code and image security.

6. **Accessing Services**
   - Flask app: `http://flask-app.local` (via Ingress)
   - Grafana: `http://grafana.local` (default admin password: see `docker-compose.yml` or Helm values)
   - SonarQube: `http://sonarqube.local`
   - Jenkins: as configured in your environment

### Custom Helm Values Explained

The `setup.sh` script uses custom values files located in the `helm/` directory for each Helm deployment to optimize them for the MicroK8s environment. Here's why each configuration is used:

#### Jenkins Custom Values (`helm/jenkins/values.yaml`)
```yaml
controller:
  ingress:
    enabled: true
    hostName: jenkins.local          # Local DNS for easy access
    ingressClassName: public         # Uses MicroK8s ingress controller
  servicePort: 8080
  jenkinsUrl: http://jenkins.local/
  podSecurityContext:
    fsGroup: 1000                   # Ensures proper file permissions
    runAsUser: 1000                 # Non-root user for security
  dnsConfig:
    nameservers:
      - "8.8.8.8"                   # External DNS for plugin downloads
  sidecars:
    configAutoReload:
      enabled: false                # Disabled for stability
persistence:
  storageClass: "microk8s-hostpath" # Uses MicroK8s local storage
  size: "8Gi"                       # Sufficient storage for build artifacts
```
**Purpose:** Enables web access via local DNS, configures persistent storage for Jenkins data and builds, ensures security with non-root execution, and pre-installs essential Kubernetes plugins to prevent the plugin dependency issues that can occur with newer Jenkins versions.

#### SonarQube Custom Values (`helm/sonarqube/values.yaml`)
```yaml
ingress:
  enabled: true
  hosts:
    - name: sonarqube.local          # Local DNS for code analysis access
  ingressClassName: public
persistence:
  storageClass: "microk8s-hostpath" # Local storage for analysis data
  size: "8Gi"                       # Storage for code analysis results
monitoringPasscode: "admin"         # Simple admin password for demo
edition: ""
community:
  enabled: true                     # Uses free community edition
```
**Purpose:** Provides web access for code quality reports, persistent storage for analysis history, and uses the free community edition suitable for development/demo environments.

#### Loki Custom Values (`helm/loki/values.yaml`)
```yaml
deploymentMode: SingleBinary        # Simplified deployment for demo
loki:
  auth_enabled: false               # No authentication for demo setup
  storage:
    type: 'filesystem'              # File-based storage (not cloud)
singleBinary:
  replicas: 1                       # Single instance for resource efficiency
  persistence:
    storageClass: "microk8s-hostpath"
    size: "10Gi"                    # Larger storage for log retention
read/write/backend:
  replicas: 0                       # Disables microservices mode
```
**Purpose:** Optimized for single-node deployment with filesystem storage, suitable for development and demo environments where simplicity is preferred over high availability.

#### Grafana Custom Values (`helm/grafana/values.yaml`)
```yaml
persistence:
  storageClassName: "microk8s-hostpath"
  size: "2Gi"                       # Storage for dashboards and settings
adminPassword: "admin123"           # Default password for easy access
ingress:
  enabled: true
  hosts:
    - grafana.local                 # Local DNS for dashboard access
datasources:
  - name: Loki                      # Pre-configured Loki connection
    url: http://loki.monitoring.svc.cluster.local:3100
    isDefault: true                 # Sets Loki as primary data source
```
**Purpose:** Provides immediate dashboard access with pre-configured Loki data source, eliminating manual setup steps for log visualization.

#### Alloy Custom Values (`helm/alloy/values.yaml`)
```yaml
alloy:
  configMap:
    content: |
      discovery.kubernetes "pods" {
        role = "pod"
      }
      loki.write "default" {
        endpoint {
          url = "http://loki.monitoring.svc.cluster.local:3100/loki/api/v1/push"
        }
      }
```
**Purpose:** Automatically discovers Kubernetes pods and forwards their logs to Loki, enabling centralized log collection without manual configuration.

**Why These Custom Values:**
1. **MicroK8s Optimization:** All use `microk8s-hostpath` storage class for local development
2. **Simplified Access:** Local DNS names (*.local) for easy browser access
3. **Resource Efficiency:** Single-instance deployments to minimize resource usage
4. **Demo-Ready:** Pre-configured connections and passwords for immediate use
5. **Security Balance:** Reasonable security for demo while maintaining simplicity
6. **Plugin Management:** Jenkins values include essential Kubernetes plugins to prevent startup failures
7. **Dependency Resolution:** Jackson2-api updated to required version for Kubernetes plugin compatibility

## 5. Security and Monitoring

- **Secrets Management:** Kubernetes secrets are base64-encoded and mounted as environment variables.
- **Vulnerability Scanning:** Trivy scans both filesystem and Docker images for vulnerabilities.
- **Code Quality:** SonarQube analyzes code for bugs, vulnerabilities, and code smells.
- **Centralized Logging:** Loki collects logs, Grafana visualizes them with prebuilt dashboards.
- **Dashboards:**
  - Application logs: `monitoring/grafana/dashboards/app-logs.json`
  - Security events: `monitoring/grafana/dashboards/security.json`
  - HTML security report: `security/reports/security-dashboard.html`

### 7.4 Monitoring and Observability

#### Real-time Application Monitoring
- **Application Logs:** View in Grafana dashboards for log analysis and troubleshooting
- **Security Events:** Monitor authentication failures and security threats
- **Performance Metrics:** Track application response times and resource usage
- **Infrastructure Health:** Monitor Kubernetes cluster and pod status

#### Log Analysis with Loki and Grafana
1. **Access Grafana:** http://grafana.local (admin/admin123)
2. **Import Dashboards:** Upload JSON files from `monitoring/grafana/dashboards/`
3. **Explore Logs:** Use Loki data source for log queries and analysis
4. **Set Alerts:** Configure alert rules for critical events and thresholds

### 7.5 Grafana Dashboard Setup and Configuration

The project includes pre-built Grafana dashboards for comprehensive monitoring of application logs and security events. These dashboards provide real-time insights into application performance and security posture.

**Dashboard Import Process:**

**For Docker Compose Setup:**
1. Access Grafana at `http://localhost:3000`
2. Login with credentials: `admin` / `admin123` (as configured in docker-compose.yml)
3. Navigate to "+" → "Import"
4. Upload the JSON files from `monitoring/grafana/dashboards/`:
   - `app-logs.json`: Application logs and metrics dashboard
   - `security.json`: Security events and monitoring dashboard

**For Kubernetes Setup:**
1. Access Grafana at `http://grafana.local`
2. Login with credentials: `admin` / `admin123` (as configured in helm values)
3. Follow the same import process as above

**Dashboard Features:**
- **Application Logs Dashboard:** 
  - Log levels distribution and trends
  - Log rate analysis by pod and namespace
  - HTTP status code monitoring
  - Real-time application logs with filtering capabilities
  - Error rate tracking and alerting thresholds

- **Security Dashboard:** 
  - Authentication failure monitoring
  - HTTP error analysis (4xx, 5xx responses)
  - Application error tracking and root cause analysis
  - Security threat detection and incident timeline
  - Vulnerability scan results integration

**Data Source Configuration:**
The Grafana Helm chart is pre-configured with Loki as the primary data source:
```yaml
datasources:
  - name: Loki
    url: http://loki.monitoring.svc.cluster.local:3100
    isDefault: true
```

**Advanced Configuration:**
- **Custom Queries:** Create custom LogQL queries for specific log analysis
- **Alert Rules:** Set up Grafana alerts for critical security events
- **Dashboard Variables:** Use template variables for dynamic filtering
- **Annotations:** Mark important events and deployments on dashboards

**Note:** While dashboards are included as JSON files, they require manual import for flexibility in customization. For production deployments, consider implementing Grafana provisioning to automatically load these dashboards via ConfigMaps.

## 6. CI/CD Pipeline Setup and Configuration

### 6.1 Pipeline Overview

The Jenkins pipeline automates the complete DevSecOps workflow with the following stages:
1. **Checkout SCM** - Retrieves source code from Git repository
2. **Install Dependencies** - Sets up Python environment and installs requirements
3. **Run Tests** - Executes pytest with coverage reporting
4. **SonarQube Analysis** - Performs static code analysis for quality and security
5. **Trivy FS Scan** - Scans filesystem for vulnerabilities
6. **Build & Push Docker Image** - Builds container image and pushes to registry
7. **Trivy Image Scan** - Scans Docker image for vulnerabilities
8. **Deploy to Kubernetes** - Deploys application to the cluster

### 6.2 Jenkins Initial Setup

#### Accessing Jenkins
1. After running the setup script, access Jenkins at `http://jenkins.local`
2. Use the initial admin password provided by the setup script output
3. Complete the initial setup wizard:
   - Install suggested plugins
   - Create the first admin user
   - Confirm Jenkins URL as `http://jenkins.local/`

#### Required Plugin Installation
The pipeline requires additional plugins beyond the Kubernetes plugins already configured in `helm/jenkins/values.yaml`:

**Navigate to:** `Manage Jenkins > Manage Plugins > Available`

**Install these plugins:**
- SonarQube Scanner
- Docker Pipeline
- Pipeline: Stage View
- Blue Ocean (optional, for better UI)
- Credentials Binding
- Workspace Cleanup

**Restart Jenkins after installation.**

### 6.3 SonarQube Configuration

#### Accessing SonarQube
1. Access SonarQube at `http://sonarqube.local`
2. Default credentials: `admin` / `admin`
3. Change the default password when prompted

#### Creating SonarQube Token
1. **Login to SonarQube** with admin credentials
2. **Navigate to:** User Menu (top-right) > My Account > Security
3. **Generate Token:**
   - Name: `jenkins-pipeline`
   - Type: `User Token`
   - Expires: `No expiration` (for demo) or set appropriate expiry
4. **Copy the generated token** - you'll need this for Jenkins configuration

#### Creating SonarQube Project
1. **Navigate to:** Projects > Create Project > Manually
2. **Project Settings:**
   - Project display name: `Flask K8s DevSecOps`
   - Project key: `flask-k8s-devsecops`
   - Main branch name: `main` (or your default branch)
3. **Click:** Create project
4. **Setup:** Choose "With Jenkins" > "Other CI" for configuration

### 6.4 Jenkins-SonarQube Integration

#### Configure SonarQube Server in Jenkins
1. **Navigate to:** `Manage Jenkins > Configure System`
2. **Scroll to:** SonarQube servers section
3. **Add SonarQube server:**
   - Name: `SonarQube`
   - Server URL: `http://sonarqube.local`
   - Server authentication token: *Create credential (see below)*

#### Adding SonarQube Token to Jenkins
1. **Navigate to:** `Manage Jenkins > Manage Credentials`
2. **Select:** `(global)` domain
3. **Click:** Add Credentials
4. **Configure:**
   - Kind: `Secret text`
   - Secret: *Paste the SonarQube token from step 6.3*
   - ID: `sonar-token`
   - Description: `SonarQube Authentication Token`
5. **Save the credential**

#### Configure SonarQube Scanner
1. **Navigate to:** `Manage Jenkins > Global Tool Configuration`
2. **Scroll to:** SonarQube Scanner section
3. **Add SonarQube Scanner:**
   - Name: `SonarQube Scanner`
   - ✅ Install automatically
   - Version: Latest available

### 6.5 Docker Registry Configuration

#### For Local Development (MicroK8s Registry)
The setup script enables a local Docker registry at `localhost:32000`. Update the Jenkinsfile:

```groovy
environment {
    REGISTRY = 'localhost:32000' // Local MicroK8s registry
    IMAGE_NAME = 'flask-k8s-app'
    TAG = "build-${env.BUILD_NUMBER}"
    // ... other variables
}
```

#### For External Registry (Docker Hub, ECR, etc.)
1. **Create registry credentials** in Jenkins:
   - Navigate to: `Manage Jenkins > Manage Credentials`
   - Add Username/Password credential with ID: `docker-registry`
2. **Update Jenkinsfile** to use credentials:
   ```groovy
   stage('Build & Push Docker Image') {
       steps {
           script {
               docker.withRegistry('https://your-registry.com', 'docker-registry') {
                   def image = docker.build("${env.IMAGE_NAME}:${env.TAG}", "./app")
                   image.push()
               }
           }
       }
   }
   ```

### 6.6 Creating the Pipeline Job

#### Step-by-Step Pipeline Creation
1. **Navigate to:** Jenkins Dashboard
2. **Click:** New Item
3. **Configure Job:**
   - Enter name: `flask-devsecops-pipeline`
   - Select: `Pipeline`
   - Click: OK

4. **Pipeline Configuration:**
   - **Description:** `DevSecOps pipeline for Flask application`
   - **Pipeline Definition:** Pipeline script from SCM
   - **SCM:** Git
   - **Repository URL:** Your Git repository URL
   - **Credentials:** Add if repository is private
   - **Branch:** `*/main` (or your default branch)
   - **Script Path:** `jenkins/Jenkinsfile`

5. **Advanced Settings:**
   - **Poll SCM:** `H/5 * * * *` (polls every 5 minutes)
   - **GitHub hook trigger:** ✅ (if using GitHub webhooks)

6. **Save the configuration**

### 6.7 Environment Variables and Secrets

#### Required Environment Variables
Update the Jenkinsfile environment section:

```groovy
environment {
    REGISTRY = 'localhost:32000'
    IMAGE_NAME = 'flask-k8s-app'
    TAG = "build-${env.BUILD_NUMBER}"
    SONAR_HOST_URL = "http://sonarqube.local"
    SONAR_PROJECT_KEY = "flask-k8s-devsecops"
    SONAR_TOKEN = credentials('sonar-token')
}
```

#### Additional Credentials Needed
1. **SonarQube Token** (ID: `sonar-token`) - Already configured above
2. **Docker Registry** (ID: `docker-registry`) - If using external registry
3. **Kubernetes Config** - Ensure Jenkins agent has access to `microk8s kubectl`

### 6.8 Pipeline Execution and Monitoring

#### Running Your First Pipeline
1. **Navigate to:** Your pipeline job
2. **Click:** Build Now
3. **Monitor progress** in the build console output
4. **Review artifacts:**
   - Test results and coverage reports
   - SonarQube analysis results
   - Trivy security scan reports

#### Pipeline Artifacts and Reports
- **Test Coverage:** Available in build artifacts (`htmlcov/`)
- **SonarQube Report:** View in SonarQube dashboard
- **Security Scans:** Trivy reports archived as build artifacts
- **Deployment Status:** Kubernetes rollout status in console output

#### Troubleshooting Common Issues
1. **SonarQube Connection:** Verify token and server URL
2. **Docker Push Fails:** Check registry credentials and network access
3. **Kubernetes Deploy Fails:** Ensure Jenkins agent has proper kubectl access
4. **Plugin Dependency Issues:** Refer to the Jenkins values.yaml plugin list

**Artifacts:** Test results, coverage reports, SonarQube analysis, and security scan reports are automatically archived for review and compliance.

## 7. Usage and Troubleshooting

### 7.1 Quick Start Guide

#### Running the Complete Setup
1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd Sample-DevSecOps
   ```

2. **Run the automated setup:**
   ```bash
   chmod +x setup.sh
   ./setup.sh
   ```

3. **Add DNS entries to /etc/hosts:**
   ```
   127.0.0.1 jenkins.local
   127.0.0.1 sonarqube.local
   127.0.0.1 grafana.local
   127.0.0.1 flask-app.local
   ```

4. **Access services using the URLs provided in setup output**

#### Local Development Alternative
For development and testing without Kubernetes:
```bash
docker-compose up -d
```
This starts all services locally for development purposes.

### 7.2 Service Access and Initial Configuration

#### Jenkins (http://jenkins.local)
- **Initial Setup:** Use admin password from setup script output
- **Required Actions:**
  1. Complete setup wizard and install suggested plugins
  2. Install additional plugins: SonarQube Scanner, Docker Pipeline
  3. Configure SonarQube server integration
  4. Create pipeline job pointing to `jenkins/Jenkinsfile`

#### SonarQube (http://sonarqube.local)
- **Default Login:** admin/admin (change on first login)
- **Required Actions:**
  1. Create new project with key: `flask-k8s-devsecops`
  2. Generate authentication token for Jenkins integration
  3. Configure quality gates and rules as needed

#### Grafana (http://grafana.local)
- **Default Login:** admin/admin123
- **Required Actions:**
  1. Import dashboards from `monitoring/grafana/dashboards/`
  2. Verify Loki data source connectivity
  3. Explore pre-configured application and security dashboards

### 7.3 CI/CD Pipeline Execution

#### First Pipeline Run
1. **Setup Complete:** Ensure all services are running and configured
2. **Create Pipeline Job:** Follow section 6.6 for detailed steps
3. **Trigger Build:** Run pipeline manually or via SCM webhook
4. **Monitor Progress:** Watch build console and review artifacts

#### Pipeline Troubleshooting
- **Build Failures:** Check Jenkins console logs for detailed error messages
- **SonarQube Issues:** Verify token authentication and project configuration
- **Docker Issues:** Ensure registry access and image build context
- **Kubernetes Deployment:** Check pod logs and service status

### 7.4 Monitoring and Observability

### 7.6 Security Scanning and Compliance

#### Continuous Security Monitoring
- **Trivy Scans:** Automated vulnerability scanning in CI/CD pipeline
- **SonarQube Analysis:** Code quality and security vulnerability detection
- **Security Reports:** Generated HTML dashboard at `security/reports/security-dashboard.html`
- **Compliance Tracking:** Monitor security posture over time

#### Security Best Practices
1. **Regular Scans:** Run security scans on every commit and deployment
2. **Vulnerability Management:** Review and remediate findings from Trivy reports
3. **Code Quality:** Address SonarQube findings for maintainable, secure code
4. **Access Control:** Use Kubernetes RBAC and network policies
5. **Secret Management:** Leverage Kubernetes secrets for sensitive data

### 7.7 Common Troubleshooting Scenarios

#### Service Access Issues
- **DNS Resolution:** Verify /etc/hosts entries for *.local domains
- **Ingress Problems:** Check ingress controller status and configuration
- **Service Discovery:** Ensure services are running and endpoints are available

#### Jenkins Pipeline Failures
- **Plugin Issues:** Verify required plugins are installed and up-to-date
- **Credential Problems:** Check SonarQube token and Docker registry access
- **Resource Constraints:** Monitor Jenkins agent resources and scaling

#### Monitoring Stack Issues
- **Loki Connectivity:** Verify Alloy is collecting and forwarding logs
- **Grafana Data Sources:** Test Loki connection and query performance
- **Dashboard Issues:** Re-import dashboards if visualizations fail

#### Application Deployment Problems
- **Image Pull Errors:** Check Docker registry accessibility and credentials
- **Pod Startup Issues:** Review pod logs and resource requests/limits
- **Service Connectivity:** Verify service discovery and network policies

**For detailed troubleshooting:**
- Check pod logs: `microk8s kubectl logs <pod> -n <namespace>`
- Validate services: `microk8s kubectl get svc,ingress -n <namespace>`
- Monitor events: `microk8s kubectl get events -n <namespace> --sort-by='.lastTimestamp'`

---

This documentation provides a comprehensive overview and technical guide for deploying, securing, and monitoring the Flask K8s DevSecOps project. For further details, refer to the individual files and dashboards included in the repository.
