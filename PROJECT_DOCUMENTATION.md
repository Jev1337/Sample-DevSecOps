# Project Documentation: Flask K8s DevSecOps

## 1. Project Overview

This project implements a secure deployment pipeline for a Flask application on Kubernetes, integrating DevSecOps practices and centralized logging. The solution leverages containerization, CI/CD, security scanning, and monitoring to ensure robust, production-ready deployments.

## 2. Architecture and Components

- **Application Layer:** Python Flask REST API with Prometheus metrics.
- **Containerization:** Docker for building and running the application.
- **Orchestration:** Kubernetes manifests and Helm charts for deployment, scaling, and service management.
- **CI/CD:** Jenkins pipeline automates build, test, security scan, and deployment.
- **Security:** Trivy and SonarQube for vulnerability and code quality scanning.
- **Monitoring & Logging:** Loki, Grafana, and Alloy for log aggregation and visualization.

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
persistence:
  storageClass: "microk8s-hostpath" # Uses MicroK8s local storage
  size: "8Gi"                       # Sufficient storage for build artifacts
```
**Purpose:** Enables web access via local DNS, configures persistent storage for Jenkins data and builds, and ensures security with non-root execution.

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

## 5. Security and Monitoring

- **Secrets Management:** Kubernetes secrets are base64-encoded and mounted as environment variables.
- **Vulnerability Scanning:** Trivy scans both filesystem and Docker images for vulnerabilities.
- **Code Quality:** SonarQube analyzes code for bugs, vulnerabilities, and code smells.
- **Centralized Logging:** Loki collects logs, Grafana visualizes them with prebuilt dashboards.
- **Dashboards:**
  - Application logs: `monitoring/grafana/dashboards/app-logs.json`
  - Security events: `monitoring/grafana/dashboards/security.json`
  - HTML security report: `security/reports/security-dashboard.html`

### Grafana Dashboard Setup

The project includes pre-built Grafana dashboards for monitoring application logs and security events. However, these dashboards need to be manually imported into Grafana:

**For Docker Compose Setup:**
1. Access Grafana at `http://localhost:3000`
2. Login with credentials: `admin` / `admin123` (as configured in docker-compose.yml)
3. Navigate to "+" → "Import"
4. Upload the JSON files from `monitoring/grafana/dashboards/`:
   - `app-logs.json`: Application logs and metrics dashboard
   - `security.json`: Security events and monitoring dashboard

**Dashboard Features:**
- **Application Logs Dashboard:** Log levels distribution, log rate by pod, HTTP error status codes, and real-time application logs
- **Security Dashboard:** Authentication failures, HTTP errors, application errors, and security threat monitoring

**Note:** The dashboards are mounted as files in the container but require manual import. For production deployments, consider setting up Grafana provisioning to automatically load these dashboards.

## 6. CI/CD Pipeline

- **Stages:**
  1. Checkout SCM
  2. Install dependencies
  3. Run tests (with coverage)
  4. SonarQube analysis
  5. Trivy filesystem and image scans
  6. Docker build and push
  7. Kubernetes deployment
- **Artifacts:** Test results, coverage, and scan reports are archived for review.

## 7. Usage and Troubleshooting

- **Local Development:** Use `docker-compose up` to start all services locally.
- **Kubernetes Deployment:** Use Helm and manifests in `k8s/` and `helm/` directories.
- **Logs and Monitoring:** Access Grafana dashboards for real-time logs and security insights.
- **Security:** Review Trivy and SonarQube reports regularly.

### Grafana Access and Dashboard Import

1. **Access Grafana:**
   - Docker Compose: `http://localhost:3000`
   - Kubernetes: `http://grafana.local` (via ingress)
   - Default credentials: `admin` / `admin123`

2. **Import Dashboards:**
   - Go to "+" → "Import" in Grafana UI
   - Upload JSON files from `monitoring/grafana/dashboards/`
   - Configure data source as "Loki" when prompted

3. **Data Source Configuration:**
   - Add Loki as data source: `http://loki:3100` (Docker) or appropriate Kubernetes service URL
   - Test connection to ensure logs are being collected

**Troubleshooting:**
- Check pod logs: `kubectl logs <pod> -n <namespace>`
- Validate service and ingress: `kubectl get svc,ingress -n <namespace>`
- Ensure all required secrets and configmaps are present.
- Verify Loki is receiving logs: Check Loki logs and Grafana data source connectivity

---

This documentation provides a comprehensive overview and technical guide for deploying, securing, and monitoring the Flask K8s DevSecOps project. For further details, refer to the individual files and dashboards included in the repository.
