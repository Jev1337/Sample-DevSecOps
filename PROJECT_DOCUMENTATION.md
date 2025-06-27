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
