#!/bin/bash

set -e

echo "🚀 DevSecOps Environment Setup Script"
echo "======================================"
echo "| Comprehensive Kubernetes DevSecOps |"
echo "| Deployment with Monitoring & CI/CD |"
echo "======================================"

# Global variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/tmp/devsecops-setup.log"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${2:-$NC}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}" | tee -a "$LOG_FILE"
}

# Function to check if a command exists
check_command() {
    if ! command -v $1 &> /dev/null; then
        log "❌ Error: $1 is not installed." "$RED"
        return 1
    fi
    return 0
}

# Function to install Docker
install_docker() {
    log "🐳 Installing Docker..." "$BLUE"
    
    if check_command docker; then
        log "✅ Docker is already installed." "$GREEN"
        return 0
    fi
    
    # Update the apt package index
    log "Updating package list..." "$YELLOW"
    sudo apt-get update
    
    # Install prerequisite packages
    log "Installing prerequisite packages..." "$YELLOW"
    sudo apt-get install -y \
        apt-transport-https \
        ca-certificates \
        curl \
        software-properties-common
    
    # Add Docker's official GPG key
    sudo install -m 0755 -d /etc/apt/keyrings
    log "Adding Docker's official GPG key..." "$YELLOW"
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
    
    # Set up the Docker repository
    log "Setting up the Docker repository..." "$YELLOW"
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Install Docker Engine
    sudo apt-get update
    log "Installing Docker Engine..." "$YELLOW"
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    # Post-installation steps
    log "Configuring Docker..." "$YELLOW"
    sudo systemctl enable docker
    sudo systemctl start docker
    sudo usermod -aG docker ${USER}
    
    log "✅ Docker installation completed!" "$GREEN"
    log "⚠️  Please log out and log back in for group changes to take effect." "$YELLOW"
}

# Function to check prerequisites
check_prerequisites() {
    log "📝 Checking prerequisites..." "$BLUE"
    
    local missing_tools=()
    
    if ! check_command snap; then
        missing_tools+=("snap")
    fi
    
    if ! check_command git; then
        missing_tools+=("git")
    fi
    
    if ! check_command docker; then
        log "⚠️  Docker not found. Will offer installation." "$YELLOW"
    fi
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        log "❌ Missing required tools: ${missing_tools[*]}" "$RED"
        log "Please install missing tools and re-run the script." "$RED"
        exit 1
    fi
    
    log "✅ Prerequisites check completed." "$GREEN"
}

# Function to install and configure MicroK8s
setup_microk8s() {
    log "🔧 Setting up MicroK8s..." "$BLUE"
    
    if ! command -v microk8s &> /dev/null; then
        log "Installing MicroK8s..." "$YELLOW"
        sudo snap install microk8s --classic --channel=1.30/stable
        sudo usermod -a -G microk8s $USER
        sudo chown -f -R $USER ~/.kube
        log "✅ MicroK8s installed." "$GREEN"
        log "⚠️  Please run 'newgrp microk8s' or log out/in for group changes, then re-run this script." "$YELLOW"
        exit 0
    else
        log "✅ MicroK8s is already installed." "$GREEN"
    fi
    
    log "Waiting for MicroK8s to be ready..." "$YELLOW"
    microk8s status --wait-ready
    
    log "🔌 Enabling MicroK8s addons..." "$YELLOW"
    microk8s enable dns
    microk8s enable helm3
    microk8s enable ingress
    microk8s enable metrics-server
    microk8s enable storage
    microk8s enable registry --size 20Gi
    
    log "✅ MicroK8s setup completed." "$GREEN"
}

# Function to build custom Jenkins image
build_jenkins_image() {
    log "🔨 Building Custom Jenkins Image..." "$BLUE"
    
    cd "$SCRIPT_DIR/jenkins"
    DOCKER_GID=$(getent group docker | cut -d: -f3 || echo 999)
    
    log "Building Jenkins DevSecOps image..." "$YELLOW"
    docker build --build-arg DOCKER_GID=${DOCKER_GID} -t jenkins-devsecops:latest .
    docker tag jenkins-devsecops:latest localhost:32000/jenkins-devsecops:latest
    docker push localhost:32000/jenkins-devsecops:latest
    
    cd "$SCRIPT_DIR"
    log "✅ Custom Jenkins image built and pushed." "$GREEN"
}

# Function to deploy core services
deploy_core_services() {
    log "🚀 Deploying Core Services (Jenkins & SonarQube)..." "$BLUE"
    
    # Create Namespaces
    log "Creating namespaces..." "$YELLOW"
    microk8s kubectl apply -f k8s/namespace.yaml
    microk8s kubectl get ns jenkins >/dev/null 2>&1 || microk8s kubectl create ns jenkins
    microk8s kubectl get ns sonarqube >/dev/null 2>&1 || microk8s kubectl create ns sonarqube
    
    # Add Helm repositories
    log "Adding Helm repositories..." "$YELLOW"
    microk8s helm3 repo add jenkins https://charts.jenkins.io
    microk8s helm3 repo add bitnami https://charts.bitnami.com/bitnami
    microk8s helm3 repo add sonarqube https://SonarSource.github.io/helm-chart-sonarqube
    microk8s helm3 repo update
    
    # Deploy Jenkins
    if ! microk8s helm3 status jenkins -n jenkins &> /dev/null; then
        log "Deploying Jenkins via Helm..." "$YELLOW"
        microk8s helm3 install jenkins jenkins/jenkins -n jenkins -f helm/jenkins/values.yaml
    else
        log "✅ Jenkins is already deployed." "$GREEN"
    fi
    
    # Deploy PostgreSQL for SonarQube
    if ! microk8s helm3 status postgresql -n sonarqube &> /dev/null; then
        log "Deploying PostgreSQL via Helm..." "$YELLOW"
        microk8s helm3 install postgresql bitnami/postgresql -n sonarqube -f helm/postgresql/values.yaml
    else
        log "✅ PostgreSQL is already deployed." "$GREEN"
    fi
    
    # Deploy SonarQube
    if ! microk8s helm3 status sonarqube -n sonarqube &> /dev/null; then
        log "Deploying SonarQube via Helm..." "$YELLOW"
        microk8s helm3 install sonarqube sonarqube/sonarqube -n sonarqube -f helm/sonarqube/values.yaml
    else
        log "✅ SonarQube is already deployed." "$GREEN"
    fi
    
    log "⏳ Waiting for core services to be ready..." "$YELLOW"
    microk8s kubectl rollout status statefulset/jenkins -n jenkins --timeout=5m
    microk8s kubectl rollout status statefulset/postgresql -n sonarqube --timeout=5m
    microk8s kubectl rollout status statefulset/sonarqube-sonarqube -n sonarqube --timeout=5m
    
    log "✅ Core services deployed successfully." "$GREEN"
}

# Function to deploy monitoring stack with SIEM capabilities
deploy_monitoring_stack() {
    log "📊 Deploying Monitoring Stack with SIEM..." "$BLUE"
    
    microk8s kubectl get ns monitoring >/dev/null 2>&1 || microk8s kubectl create ns monitoring
    
    # Add Grafana Helm Repo if not already added
    if ! microk8s helm3 repo list | grep -q "grafana"; then
        log "Adding Grafana Helm repository..." "$YELLOW"
        microk8s helm3 repo add grafana https://grafana.github.io/helm-charts
        microk8s helm3 repo update
    else
        log "✅ Grafana Helm repository already exists." "$GREEN"
    fi
    
    # Enable Kubernetes audit logging for SIEM
    log "🔐 Configuring Kubernetes audit logging..." "$YELLOW"
    setup_kubernetes_audit_logging
    
    # Deploy Loki
    if ! microk8s helm3 status loki -n monitoring &> /dev/null; then
        log "Deploying Loki via Helm..." "$YELLOW"
        microk8s helm3 install loki grafana/loki -n monitoring -f helm/loki/values.yaml
    else
        log "✅ Loki is already deployed." "$GREEN"
    fi
    
    # Deploy Grafana
    if ! microk8s helm3 status grafana -n monitoring &> /dev/null; then
        log "Deploying Grafana via Helm..." "$YELLOW"
        microk8s helm3 install grafana grafana/grafana -n monitoring -f helm/grafana/values.yaml
    else
        log "✅ Grafana is already deployed." "$GREEN"
    fi
    
    # Deploy Alloy with SIEM configuration
    if ! microk8s helm3 status alloy -n monitoring &> /dev/null; then
        log "Deploying Alloy with SIEM configuration..." "$YELLOW"
        microk8s helm3 install alloy grafana/alloy -n monitoring -f helm/alloy/values.yaml
    else
        log "✅ Alloy is already deployed." "$GREEN"
    fi
    
    # Deploy SIEM webhook service
    log "🕸️ Deploying SIEM webhook service..." "$YELLOW"
    deploy_siem_webhook_service
    
    # Configure system log forwarding
    log "📝 Configuring system log forwarding..." "$YELLOW"
    configure_system_log_forwarding
    
    log "⏳ Waiting for monitoring components..." "$YELLOW"
    microk8s kubectl rollout status statefulset/loki -n monitoring --timeout=5m
    microk8s kubectl rollout status deployment/grafana -n monitoring --timeout=5m
    microk8s kubectl rollout status daemonset/alloy -n monitoring --timeout=5m
    
    # Install security monitoring tools
    log "🛡️ Installing security monitoring tools..." "$YELLOW"
    install_security_tools
    
    log "✅ Monitoring stack with SIEM deployed successfully." "$GREEN"
}

# Function to build and deploy application
deploy_application() {
    log "🐳 Building and Deploying Flask Application..." "$BLUE"
    
    log "Building local Docker image..." "$YELLOW"
    docker build -t flask-k8s-app:latest ./app
    docker tag flask-k8s-app:latest localhost:32000/flask-k8s-app:latest
    docker push localhost:32000/flask-k8s-app:latest
    
    # Create flask-app namespace if missing
    microk8s kubectl get ns flask-app >/dev/null 2>&1 || microk8s kubectl create ns flask-app
    
    log "Deploying Flask application manifests..." "$YELLOW"
    # Update deployment to use local registry image
    sed -i 's|image: flask-k8s-app:latest|image: localhost:32000/flask-k8s-app:latest|g' k8s/deployment.yaml
    microk8s kubectl apply -f k8s/
    
    log "⏳ Waiting for application deployment..." "$YELLOW"
    microk8s kubectl rollout status deployment/flask-app -n flask-app --timeout=2m
    
    log "✅ Flask application deployed successfully." "$GREEN"
}
# Function to configure Azure external access
configure_azure_access() {
    log "🌐 Configuring Azure External Access..." "$BLUE"
    
    # Get the external IP of the Azure VM
    log "🔍 Detecting Azure VM external IP..." "$YELLOW"
    EXTERNAL_IP=$(curl -s ifconfig.me || curl -s ipinfo.io/ip || curl -s icanhazip.com)
    log "✅ External IP detected: $EXTERNAL_IP" "$GREEN"
    
    # Create LoadBalancer services
    log "📋 Creating LoadBalancer Services..." "$YELLOW"
    
    # Jenkins LoadBalancer
    cat <<EOF | microk8s kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: jenkins-loadbalancer
  namespace: jenkins
spec:
  type: LoadBalancer
  ports:
  - port: 8080
    targetPort: 8080
    name: http
  selector:
    app.kubernetes.io/component: jenkins-controller
    app.kubernetes.io/instance: jenkins
EOF
    
    # SonarQube LoadBalancer
    cat <<EOF | microk8s kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: sonarqube-loadbalancer
  namespace: sonarqube
spec:
  type: LoadBalancer
  ports:
  - port: 9000
    targetPort: 9000
    name: http
  selector:
    app: sonarqube
EOF
    
    # Grafana LoadBalancer
    cat <<EOF | microk8s kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: grafana-loadbalancer
  namespace: monitoring
spec:
  type: LoadBalancer
  ports:
  - port: 3000
    targetPort: 3000
    name: http
  selector:
    app.kubernetes.io/name: grafana
EOF
    
    # Flask App LoadBalancer
    cat <<EOF | microk8s kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: flask-app-loadbalancer
  namespace: flask-app
spec:
  type: LoadBalancer
  ports:
  - port: 80
    targetPort: 5000
    name: http
  selector:
    app: flask-app
EOF
    
    log "✅ LoadBalancer services created" "$GREEN"
    
    # Create Ingress configurations
    log "📋 Creating Ingress configurations..." "$YELLOW"
    
    # Jenkins Ingress
    cat <<EOF | microk8s kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: jenkins-external
  namespace: jenkins
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: public
  rules:
  - host: jenkins.${EXTERNAL_IP}.nip.io
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: jenkins
            port:
              number: 8080
EOF
    
    # SonarQube Ingress
    cat <<EOF | microk8s kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: sonarqube-external
  namespace: sonarqube
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: public
  rules:
  - host: sonarqube.${EXTERNAL_IP}.nip.io
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: sonarqube-sonarqube
            port:
              number: 9000
EOF
    
    # Grafana Ingress
    cat <<EOF | microk8s kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: grafana-external
  namespace: monitoring
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: public
  rules:
  - host: grafana.${EXTERNAL_IP}.nip.io
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: grafana
            port:
              number: 80
EOF
    
    # Flask App Ingress
    cat <<EOF | microk8s kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: flask-app-external
  namespace: flask-app
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: public
  rules:
  - host: app.${EXTERNAL_IP}.nip.io
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: flask-app-service
            port:
              number: 80
EOF
    
    log "✅ External ingress configurations created" "$GREEN"
    
    log "⏳ Waiting for LoadBalancer services..." "$YELLOW"
    sleep 30
    
    log "✅ Azure external access configured!" "$GREEN"
    log "🌐 EXTERNAL ACCESS INFORMATION" "$CYAN"
    log "=============================" "$CYAN"
    log "🔗 Access your services via these URLs:" "$CYAN"
    log "📊 Using nip.io domains (recommended):" "$YELLOW"
    log "   - Jenkins:   http://jenkins.$EXTERNAL_IP.nip.io" "$CYAN"
    log "   - SonarQube: http://sonarqube.$EXTERNAL_IP.nip.io" "$CYAN"
    log "   - Grafana:   http://grafana.$EXTERNAL_IP.nip.io" "$CYAN"
    log "   - Flask App: http://app.$EXTERNAL_IP.nip.io" "$CYAN"
    log "🌐 Using LoadBalancer IPs:" "$YELLOW"
    log "   - Check the table below for assigned external IPs" "$CYAN"
    log "📋 LoadBalancer External IPs:" "$YELLOW"
    microk8s kubectl get svc -A -o=jsonpath='{range .items[?(@.spec.type=="LoadBalancer")]}{"NAMESPACE: "}{.metadata.namespace}{"\tSERVICE: "}{.metadata.name}{"\tEXTERNAL-IP: "}{.status.loadBalancer.ingress[0].ip}{"\n"}{end}'
    log "🛡️ Security Notes:" "$YELLOW"
    log "   - Ensure Azure NSG allows inbound traffic on ports 80, 443, 8080, 9000, 3000, 5000" "$YELLOW"
    log "   - Consider setting up SSL/TLS certificates for production use" "$YELLOW"
    log "   - Default credentials provided in access info section" "$YELLOW"
}

# Function to run development mode with Docker Compose
run_development_mode() {
    log "🧪 Starting Development Mode with Docker Compose..." "$BLUE"
    
    if ! check_command docker-compose && ! docker compose version &>/dev/null; then
        log "❌ Docker Compose not found. Please install Docker Compose." "$RED"
        return 1
    fi
    
    log "Starting all services with Docker Compose..." "$YELLOW"
    docker compose up -d
    
    log "⏳ Waiting for services to start..." "$YELLOW"
    sleep 10
    
    log "✅ Development environment started!" "$GREEN"
    log "🔗 Development Access URLs:" "$CYAN"
    log "   - Flask App: http://localhost:5000" "$CYAN"
    log "   - SonarQube: http://localhost:9000" "$CYAN"
    log "   - Grafana:   http://localhost:3000" "$CYAN"
    log "   - Loki:      http://localhost:3100" "$CYAN"
}

# Function to run cleanup
run_cleanup() {
    log "🧹 Running Cleanup..." "$BLUE"
    
    if [ ! -f "$SCRIPT_DIR/cleanup.sh" ]; then
        log "❌ cleanup.sh not found!" "$RED"
        return 1
    fi
    
    # Source the cleanup functions
    source "$SCRIPT_DIR/cleanup.sh"
    
    while true; do
        echo ""
        log "Select cleanup action:" "$YELLOW"
        echo "  1) Cleanup Core Services (Jenkins, SonarQube)"
        echo "  2) Cleanup Monitoring Stack (Loki, Grafana, Alloy)"
        echo "  3) Cleanup Application Deployment"
        echo "  4) Cleanup Development Environment (Docker Compose)"
        echo "  5) Cleanup Azure External Access"
        echo "  6) Cleanup ALL"
        echo "  7) Return to main menu"
        read -p "Enter your choice [1-7]: " cleanup_choice
        
        case $cleanup_choice in
            1)
                cleanup_core_services
                log "✅ Core services cleanup complete." "$GREEN"
                ;;
            2)
                cleanup_monitoring
                log "✅ Monitoring stack cleanup complete." "$GREEN"
                ;;
            3)
                cleanup_application
                log "✅ Application deployment cleanup complete." "$GREEN"
                ;;
            4)
                log "Stopping Docker Compose services..." "$YELLOW"
                docker compose down -v
                log "✅ Development environment cleanup complete." "$GREEN"
                ;;
            5)
                log "Removing Azure LoadBalancer services..." "$YELLOW"
                microk8s kubectl delete service jenkins-loadbalancer -n jenkins || true
                microk8s kubectl delete service sonarqube-loadbalancer -n sonarqube || true
                microk8s kubectl delete service grafana-loadbalancer -n monitoring || true
                microk8s kubectl delete service flask-app-loadbalancer -n flask-app || true
                log "✅ Azure external access cleanup complete." "$GREEN"
                ;;
            6)
                cleanup_all
                docker compose down -v || true
                log "✅ Full cleanup completed!" "$GREEN"
                ;;
            7)
                return 0
                ;;
            *)
                log "Invalid option. Please try again." "$RED"
                ;;
        esac
    done
}

# Function to display access information
show_access_info() {
    log "🔗 Service Access Information" "$CYAN"
    log "=============================" "$CYAN"
    
    # Get Jenkins initial admin password
    if JENKINS_PASS=$(microk8s kubectl exec --namespace jenkins -it svc/jenkins -c jenkins -- /bin/cat /run/secrets/additional/chart-admin-password 2>/dev/null); then
        log "Retrieved Jenkins password from pod." "$GREEN"
    else
        JENKINS_PASS=$(microk8s kubectl get secret jenkins -n jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode 2>/dev/null || echo "Unable to retrieve")
    fi
    
    # Get external IP
    EXTERNAL_IP=$(curl -s ifconfig.me || curl -s ipinfo.io/ip || curl -s icanhazip.com || echo "unknown")
    
    echo ""
    log "📝 Add these lines to your /etc/hosts file for local access:" "$YELLOW"
    echo "127.0.0.1 jenkins.local"
    echo "127.0.0.1 sonarqube.local"
    echo "127.0.0.1 grafana.local"
    echo "127.0.0.1 flask-app.local"
    echo ""
    
    log "🌐 Local Access URLs:" "$CYAN"
    log "   - Flask App: http://flask-app.local" "$CYAN"
    log "   - Jenkins:   http://jenkins.local (admin/${JENKINS_PASS})" "$CYAN"
    log "   - SonarQube: http://sonarqube.local (admin/admin)" "$CYAN"
    log "   - Grafana:   http://grafana.local (admin/admin123)" "$CYAN"
    echo ""
    
    log "🌐 External Access URLs:" "$CYAN"
    log "   - Flask App: http://app.$EXTERNAL_IP.nip.io" "$CYAN"
    log "   - Jenkins:   http://jenkins.$EXTERNAL_IP.nip.io (admin/${JENKINS_PASS})" "$CYAN"
    log "   - SonarQube: http://sonarqube.$EXTERNAL_IP.nip.io (admin/admin)" "$CYAN"
    log "   - Grafana:   http://grafana.$EXTERNAL_IP.nip.io (admin/admin123)" "$CYAN"
    echo ""
    
    log "🔒 SIEM Security Monitoring:" "$PURPLE"
    log "   - Webhook URL: http://webhook.$EXTERNAL_IP.nip.io/webhook" "$CYAN"
    log "   - SIEM Dashboard: Available in Grafana (import siem-dashboard.json)" "$CYAN"
    log "   - Security Logs: /var/log/siem/" "$CYAN"
    log "   - Audit Logs: /var/log/audit-k8s.log" "$CYAN"
    echo ""
    
    log "�️ Security Features Enabled:" "$YELLOW"
    log "   ✅ SSH Login Monitoring (failed/successful attempts)" "$GREEN"
    log "   ✅ Git Webhook Event Processing" "$GREEN"
    log "   ✅ Kubernetes Audit Logging" "$GREEN"
    log "   ✅ Container Security Monitoring" "$GREEN"
    log "   ✅ fail2ban SSH Protection" "$GREEN"
    log "   ✅ Real-time Security Alerts" "$GREEN"
    echo ""
    
    log "�🛠️  CI/CD Pipeline Setup:" "$YELLOW"
    log "   1. Configure a new 'Pipeline' job in Jenkins" "$YELLOW"
    log "   2. Point it to your Git repository" "$YELLOW"
    log "   3. Set 'Script Path' to 'jenkins/Jenkinsfile'" "$YELLOW"
    log "   4. Configure webhook URL in your Git repository settings" "$YELLOW"
    echo ""
    
    log "📊 Grafana Dashboard Setup:" "$YELLOW"
    log "   1. Access Grafana and login with admin/admin123" "$YELLOW"
    log "   2. Import dashboards from monitoring/grafana/dashboards/:" "$YELLOW"
    log "      - app-logs.json (Application monitoring)" "$CYAN"
    log "      - security.json (Basic security events)" "$CYAN"
    log "      - siem-dashboard.json (Enhanced SIEM monitoring)" "$CYAN"
    echo ""
    
    log "🔧 Git Webhook Configuration:" "$YELLOW"
    log "   Configure your Git repositories to send webhooks to:" "$YELLOW"
    log "   http://webhook.$EXTERNAL_IP.nip.io/webhook" "$CYAN"
    log "   This enables commit monitoring and security analysis." "$YELLOW"
}

# Main menu function
show_main_menu() {
    while true; do
        echo ""
        log "🚀 DevSecOps Setup Menu" "$PURPLE"
        log "======================" "$PURPLE"
        echo "  1) Install Docker"
        echo "  2) Check Prerequisites"
        echo "  3) Setup MicroK8s"
        echo "  4) Build Jenkins Image"
        echo "  5) Deploy Core Services (Jenkins, SonarQube)"
        echo "  6) Deploy Monitoring Stack with SIEM (Loki, Grafana, Alloy)"
        echo "  7) Deploy Flask Application"
        echo "  8) Configure Azure External Access"
        echo "  9) Setup SIEM Dashboards"
        echo " 10) Full Production Setup (3-8)"
        echo " 11) Development Mode (Docker Compose)"
        echo " 12) Cleanup Options"
        echo " 13) Show Access Information"
        echo " 14) SIEM Status Check"
        echo " 15) Exit"
        echo ""
        read -p "Enter your choice [1-15]: " choice
        
        case $choice in
            1)
                install_docker
                ;;
            2)
                check_prerequisites
                ;;
            3)
                setup_microk8s
                ;;
            4)
                build_jenkins_image
                ;;
            5)
                deploy_core_services
                ;;
            6)
                deploy_monitoring_stack
                ;;
            7)
                deploy_application
                ;;
            8)
                configure_azure_access
                ;;
            9)
                setup_siem_dashboards
                ;;
            10)
                log "🚀 Starting Full Production Setup with SIEM..." "$PURPLE"
                check_prerequisites
                setup_microk8s
                build_jenkins_image
                deploy_core_services
                deploy_monitoring_stack
                deploy_application
                configure_azure_access
                setup_siem_dashboards
                show_access_info
                log "✅ Full production setup with SIEM completed!" "$GREEN"
                ;;
            11)
                run_development_mode
                ;;
            12)
                run_cleanup
                ;;
            13)
                show_access_info
                ;;
            14)
                show_siem_status
                ;;
            15)
                log "👋 Exiting DevSecOps Setup. Goodbye!" "$GREEN"
                exit 0
                ;;
            *)
                log "❌ Invalid option. Please try again." "$RED"
                ;;
        esac
    done
}

# Cleanup functions (embedded from cleanup.sh)
cleanup_core_services() {
    log "❌ Uninstalling Jenkins..." "$YELLOW"
    microk8s helm3 uninstall jenkins -n jenkins || true
    log "Deleting Jenkins namespace..." "$YELLOW"
    microk8s kubectl delete ns jenkins --ignore-not-found

    log "❌ Uninstalling SonarQube..." "$YELLOW"
    microk8s helm3 uninstall sonarqube -n sonarqube || true
    log "❌ Uninstalling PostgreSQL..." "$YELLOW"
    microk8s helm3 uninstall postgresql -n sonarqube || true
    log "Deleting SonarQube PVCs..." "$YELLOW"
    microk8s kubectl delete pvc -n sonarqube --all || true
    log "Deleting SonarQube namespace..." "$YELLOW"
    microk8s kubectl delete ns sonarqube --ignore-not-found
}

cleanup_monitoring() {
    log "❌ Uninstalling Loki..." "$YELLOW"
    microk8s helm3 uninstall loki -n monitoring || true
    log "❌ Uninstalling Grafana..." "$YELLOW"
    microk8s helm3 uninstall grafana -n monitoring || true
    log "❌ Uninstalling Alloy..." "$YELLOW"
    microk8s helm3 uninstall alloy -n monitoring || true
    log "❌ Removing SIEM webhook..." "$YELLOW"
    microk8s kubectl delete deployment siem-webhook -n monitoring || true
    microk8s kubectl delete service siem-webhook -n monitoring || true
    microk8s kubectl delete ingress siem-webhook-ingress -n monitoring || true
    log "Deleting Monitoring namespace..." "$YELLOW"
    microk8s kubectl delete ns monitoring --ignore-not-found
    
    # Clean up SIEM components
    log "❌ Cleaning up SIEM components..." "$YELLOW"
    sudo rm -rf /var/log/siem || true
    sudo rm -f /etc/rsyslog.d/49-siem-ssh.conf || true
    sudo rm -f /etc/rsyslog.d/50-siem-security.conf || true
    sudo rm -f /etc/logrotate.d/siem-logs || true
    sudo rm -f /usr/local/bin/siem-security-check.sh || true
    sudo crontab -l | grep -v "siem-security-check.sh" | sudo crontab - || true
    sudo systemctl restart rsyslog || true
}

cleanup_application() {
    log "❌ Deleting Flask application resources..." "$YELLOW"
    microk8s kubectl delete -f k8s/ --ignore-not-found
    log "Reverting image in deployment.yaml..." "$YELLOW"
    sed -i 's|localhost:32000/flask-k8s-app:latest|flask-k8s-app:latest|g' k8s/deployment.yaml || true
    log "❌ Removing local Docker images..." "$YELLOW"
    docker rmi flask-k8s-app:latest localhost:32000/flask-k8s-app:latest || true
}

cleanup_repos() {
    log "Removing Helm repositories..." "$YELLOW"
    microk8s helm3 repo remove jenkins || true
    microk8s helm3 repo remove sonarqube || true
    microk8s helm3 repo remove grafana || true
    microk8s helm3 repo remove bitnami || true
}

cleanup_all() {
    cleanup_core_services
    cleanup_monitoring
    cleanup_application
    cleanup_repos
}

# SIEM-specific functions
# Function to setup Kubernetes audit logging
setup_kubernetes_audit_logging() {
    log "🔍 Setting up Kubernetes audit logging..." "$YELLOW"
    
    # Create audit policy
    sudo mkdir -p /var/snap/microk8s/current/args
    
    cat <<EOF | sudo tee /var/snap/microk8s/current/args/audit-policy.yaml
apiVersion: audit.k8s.io/v1
kind: Policy
rules:
# Authentication and authorization events
- level: Metadata
  namespaces: ["kube-system", "jenkins", "sonarqube", "monitoring", "flask-app"]
  verbs: ["create", "delete", "patch", "update"]
  resources:
  - group: ""
    resources: ["secrets", "configmaps", "serviceaccounts"]
  - group: "rbac.authorization.k8s.io"
    resources: ["roles", "rolebindings", "clusterroles", "clusterrolebindings"]

# Security-relevant pod events
- level: Request
  verbs: ["create", "delete"]
  resources:
  - group: ""
    resources: ["pods", "services"]

# Network policy changes
- level: Request
  verbs: ["create", "delete", "patch", "update"]
  resources:
  - group: "networking.k8s.io"
    resources: ["networkpolicies"]

# Ingress and service exposure changes
- level: Request
  verbs: ["create", "delete", "patch", "update"]
  resources:
  - group: "networking.k8s.io"
    resources: ["ingresses"]
  - group: ""
    resources: ["services"]

# Security context and privileged operations
- level: Request
  verbs: ["create", "patch", "update"]
  resources:
  - group: ""
    resources: ["pods"]
  namespaces: ["jenkins", "sonarqube", "monitoring", "flask-app"]
EOF

    # Configure kube-apiserver with audit logging
    if ! grep -q "audit-log-path" /var/snap/microk8s/current/args/kube-apiserver; then
        echo "--audit-log-path=/var/log/audit-k8s.log" | sudo tee -a /var/snap/microk8s/current/args/kube-apiserver
        echo "--audit-policy-file=/var/snap/microk8s/current/args/audit-policy.yaml" | sudo tee -a /var/snap/microk8s/current/args/kube-apiserver
        echo "--audit-log-maxage=30" | sudo tee -a /var/snap/microk8s/current/args/kube-apiserver
        echo "--audit-log-maxbackup=3" | sudo tee -a /var/snap/microk8s/current/args/kube-apiserver
        echo "--audit-log-maxsize=100" | sudo tee -a /var/snap/microk8s/current/args/kube-apiserver
        
        log "Restarting MicroK8s to apply audit configuration..." "$YELLOW"
        microk8s stop
        sleep 5
        microk8s start
        microk8s status --wait-ready
    fi
    
    log "✅ Kubernetes audit logging configured." "$GREEN"
}

# Function to deploy SIEM webhook service
deploy_siem_webhook_service() {
    log "🕸️ Creating SIEM webhook service..." "$YELLOW"
    
    # Create webhook service
    cat <<EOF | microk8s kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: siem-webhook
  namespace: monitoring
  labels:
    app: siem-webhook
spec:
  replicas: 1
  selector:
    matchLabels:
      app: siem-webhook
  template:
    metadata:
      labels:
        app: siem-webhook
    spec:
      containers:
      - name: webhook-receiver
        image: python:3.9-slim
        ports:
        - containerPort: 8080
        workingDir: /app
        env:
        - name: PYTHONUNBUFFERED
          value: "1"
        command: 
        - /bin/sh
        - -c
        - |
          mkdir -p /app
          pip install --no-cache-dir flask requests gunicorn
          cat > /app/webhook_receiver.py << 'PYEOF'
          from flask import Flask, request, jsonify
          import json
          import logging
          from datetime import datetime
          import os
          import sys

          # Configure logging
          logging.basicConfig(
              level=logging.INFO,
              format='%(asctime)s %(levelname)s %(message)s',
              handlers=[
                  logging.StreamHandler(sys.stdout)
              ]
          )

          app = Flask(__name__)
          logger = logging.getLogger(__name__)

          @app.route('/webhook', methods=['POST', 'GET'])
          def webhook():
              try:
                  if request.method == 'GET':
                      return jsonify({"status": "webhook endpoint ready", "methods": ["POST"]}), 200
                      
                  data = request.get_json(force=True) if request.is_json else {}
                  timestamp = datetime.utcnow().isoformat()
                  
                  # Log security-relevant webhook events
                  security_event = {
                      "timestamp": timestamp,
                      "event_type": "webhook_received",
                      "source_ip": request.environ.get('REMOTE_ADDR', 'unknown'),
                      "user_agent": request.headers.get('User-Agent', ''),
                      "content_type": request.headers.get('Content-Type', ''),
                      "webhook_data": data,
                      "severity": "info"
                  }
                  
                  # Detect potential security events
                  if data and isinstance(data, dict):
                      if 'commits' in data:
                          security_event['event_type'] = 'git_commit'
                          security_event['severity'] = 'medium'
                          commits = data.get('commits', [])
                          for commit in commits:
                              commit_str = str(commit).lower()
                              if any(keyword in commit_str for keyword in ['password', 'secret', 'key', 'token', 'credential']):
                                  security_event['severity'] = 'high'
                                  security_event['alert'] = 'Potential credential exposure in commit'
                                  break
                      
                      if 'pull_request' in data:
                          security_event['event_type'] = 'pull_request'
                          security_event['severity'] = 'medium'
                      
                      if 'action' in data:
                          security_event['action'] = data['action']
                  
                  # Log the security event in JSON format for Loki
                  logger.info(json.dumps(security_event))
                  
                  return jsonify({"status": "received", "timestamp": timestamp, "events_processed": 1}), 200
                  
              except Exception as e:
                  error_event = {
                      "timestamp": datetime.utcnow().isoformat(),
                      "event_type": "webhook_error",
                      "error": str(e),
                      "severity": "high"
                  }
                  logger.error(json.dumps(error_event))
                  return jsonify({"error": str(e), "status": "error"}), 500

          @app.route('/health', methods=['GET'])
          def health():
              return jsonify({"status": "healthy", "timestamp": datetime.utcnow().isoformat()}), 200

          @app.route('/', methods=['GET'])
          def root():
              return jsonify({
                  "service": "SIEM Webhook Receiver",
                  "endpoints": {
                      "/webhook": "POST - Receive webhook events",
                      "/health": "GET - Health check",
                      "/": "GET - Service info"
                  },
                  "status": "ready"
              }), 200

          if __name__ == '__main__':
              logger.info("Starting SIEM Webhook Receiver...")
              app.run(host='0.0.0.0', port=8080, debug=False, threaded=True)
          PYEOF
          
          cd /app
          python webhook_receiver.py
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 5
        resources:
          requests:
            memory: "64Mi"
            cpu: "50m"
          limits:
            memory: "128Mi"
            cpu: "100m"
---
apiVersion: v1
kind: Service
metadata:
  name: siem-webhook
  namespace: monitoring
spec:
  selector:
    app: siem-webhook
  ports:
  - protocol: TCP
    port: 80
    targetPort: 8080
EOF

    # Create ingress for webhook access
    EXTERNAL_IP=$(curl -s ifconfig.me || curl -s ipinfo.io/ip || curl -s icanhazip.com)
    
    cat <<EOF | microk8s kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: siem-webhook-ingress
  namespace: monitoring
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
spec:
  ingressClassName: public
  rules:
  - host: webhook.${EXTERNAL_IP}.nip.io
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: siem-webhook
            port:
              number: 80
EOF

    # Wait for deployment to be ready
    log "⏳ Waiting for SIEM webhook deployment..." "$YELLOW"
    microk8s kubectl rollout status deployment/siem-webhook -n monitoring --timeout=2m

    log "✅ SIEM webhook service deployed at http://webhook.${EXTERNAL_IP}.nip.io" "$GREEN"
}

# Function to configure system log forwarding
configure_system_log_forwarding() {
    log "📝 Configuring system log forwarding to Loki..." "$YELLOW"
    
    # Install rsyslog if not present
    if ! command -v rsyslog &> /dev/null; then
        sudo apt-get update && sudo apt-get install -y rsyslog
    fi
    
    # Create SIEM log directory
    sudo mkdir -p /var/log/siem
    sudo chmod 755 /var/log/siem
    
    # Configure enhanced SSH logging
    cat <<EOF | sudo tee /etc/rsyslog.d/49-siem-ssh.conf
# SIEM SSH Authentication Logging
auth,authpriv.*                 /var/log/siem/auth.log
auth,authpriv.info              /var/log/siem/ssh-info.log
auth,authpriv.warn              /var/log/siem/ssh-warn.log
auth,authpriv.err               /var/log/siem/ssh-error.log
EOF

    # Configure security event logging
    cat <<EOF | sudo tee /etc/rsyslog.d/50-siem-security.conf
# SIEM Security Event Logging
*.emerg                         /var/log/siem/emergency.log
kern.crit                       /var/log/siem/kernel-critical.log
mail.crit                       /var/log/siem/mail-critical.log
news.crit                       /var/log/siem/news-critical.log
EOF

    # Create log rotation configuration
    cat <<EOF | sudo tee /etc/logrotate.d/siem-logs
/var/log/siem/*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    copytruncate
    postrotate
        systemctl reload rsyslog
    endscript
}
EOF

    # Restart rsyslog
    sudo systemctl restart rsyslog
    
    log "✅ System log forwarding configured." "$GREEN"
}

# Function to install security monitoring tools
install_security_tools() {
    log "🛡️ Installing security monitoring tools..." "$YELLOW"
    
    # Install fail2ban for SSH protection
    if ! command -v fail2ban-client &> /dev/null; then
        sudo apt-get update
        sudo apt-get install -y fail2ban
        
        # Configure fail2ban for SSH
        cat <<EOF | sudo tee /etc/fail2ban/jail.local
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3
backend = systemd

[sshd]
enabled = true
port = ssh
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600
findtime = 600

[sshd-ddos]
enabled = true
port = ssh
logpath = /var/log/auth.log
maxretry = 2
bantime = 7200
findtime = 300
EOF

        sudo systemctl enable fail2ban
        sudo systemctl start fail2ban
    fi
    
    # Install chkrootkit for rootkit detection
    if ! command -v chkrootkit &> /dev/null; then
        sudo apt-get install -y chkrootkit
    fi
    
    # Install rkhunter for additional security scanning
    if ! command -v rkhunter &> /dev/null; then
        sudo apt-get install -y rkhunter
        sudo rkhunter --update
    fi
    
    # Create security monitoring script
    cat <<EOF | sudo tee /usr/local/bin/siem-security-check.sh
#!/bin/bash
# SIEM Security Monitoring Script

LOG_FILE="/var/log/siem/security-monitor.log"
mkdir -p /var/log/siem

echo "\$(date): Starting SIEM security check" >> \$LOG_FILE

# Check for failed SSH logins
FAILED_LOGINS=\$(grep "Failed password" /var/log/auth.log | grep "\$(date +%Y-%m-%d)" | wc -l)
if [ \$FAILED_LOGINS -gt 5 ]; then
    echo "\$(date): WARNING: High number of failed SSH logins today: \$FAILED_LOGINS" >> \$LOG_FILE
    echo '{"timestamp":"'\$(date -Iseconds)'","event_type":"ssh_failed_logins","severity":"high","count":'\$FAILED_LOGINS',"alert":"High number of failed SSH login attempts"}' >> \$LOG_FILE
fi

# Check for successful SSH logins
SUCCESSFUL_LOGINS=\$(grep "Accepted password" /var/log/auth.log | grep "\$(date +%Y-%m-%d)" | wc -l)
if [ \$SUCCESSFUL_LOGINS -gt 0 ]; then
    echo '{"timestamp":"'\$(date -Iseconds)'","event_type":"ssh_successful_logins","severity":"info","count":'\$SUCCESSFUL_LOGINS'}' >> \$LOG_FILE
fi

# Check for new user accounts
NEW_USERS=\$(grep "new user" /var/log/auth.log | grep "\$(date +%Y-%m-%d)")
if [ ! -z "\$NEW_USERS" ]; then
    echo "\$(date): INFO: New user activities detected" >> \$LOG_FILE
    echo '{"timestamp":"'\$(date -Iseconds)'","event_type":"new_user_activity","severity":"medium","details":"'"New user account activities detected"'"}' >> \$LOG_FILE
fi

# Check disk space
DISK_USAGE=\$(df / | tail -1 | awk '{print \$5}' | sed 's/%//')
if [ \$DISK_USAGE -gt 85 ]; then
    echo "\$(date): WARNING: Disk space usage is at \$DISK_USAGE%" >> \$LOG_FILE
    echo '{"timestamp":"'\$(date -Iseconds)'","event_type":"disk_space_warning","severity":"medium","usage":'\$DISK_USAGE',"alert":"High disk space usage"}' >> \$LOG_FILE
fi

# Check for suspicious processes
SUSPICIOUS_PROCS=\$(ps aux | grep -E "(nc|netcat|socat|nmap)" | grep -v grep | wc -l)
if [ \$SUSPICIOUS_PROCS -gt 0 ]; then
    echo "\$(date): WARNING: Suspicious processes detected" >> \$LOG_FILE
    echo '{"timestamp":"'\$(date -Iseconds)'","event_type":"suspicious_processes","severity":"high","count":'\$SUSPICIOUS_PROCS',"alert":"Potentially malicious processes detected"}' >> \$LOG_FILE
fi

# Check fail2ban status
if command -v fail2ban-client &> /dev/null; then
    BANNED_IPS=\$(fail2ban-client status sshd 2>/dev/null | grep "Banned IP list" | awk -F: '{print \$2}' | wc -w)
    if [ \$BANNED_IPS -gt 0 ]; then
        echo '{"timestamp":"'\$(date -Iseconds)'","event_type":"fail2ban_activity","severity":"medium","banned_ips":'\$BANNED_IPS'}' >> \$LOG_FILE
    fi
fi

echo "\$(date): SIEM security check completed" >> \$LOG_FILE
EOF

    sudo chmod +x /usr/local/bin/siem-security-check.sh
    
    # Create cron job for security monitoring
    (sudo crontab -l 2>/dev/null; echo "*/5 * * * * /usr/local/bin/siem-security-check.sh") | sudo crontab -
    
    log "✅ Security monitoring tools installed and configured." "$GREEN"
}

# Function to setup SIEM dashboards and alerts
setup_siem_dashboards() {
    log "📊 Setting up SIEM dashboards..." "$YELLOW"
    
    # Wait for Grafana to be ready
    sleep 30
    
    # Create SIEM dashboard configuration
    cat <<EOF > /tmp/siem-dashboard.json
{
  "dashboard": {
    "title": "SIEM Security Dashboard",
    "tags": ["siem", "security"],
    "panels": [
      {
        "title": "SSH Login Attempts",
        "type": "stat",
        "targets": [
          {
            "expr": "sum(count_over_time({job=\"ssh_logs\", event_type=\"ssh_failed_logins\"} [24h]))",
            "legendFormat": "Failed Logins"
          }
        ]
      },
      {
        "title": "Security Events Timeline",
        "type": "logs",
        "targets": [
          {
            "expr": "{job=\"security_logs\"} |= \"event_type\""
          }
        ]
      },
      {
        "title": "Webhook Events",
        "type": "table",
        "targets": [
          {
            "expr": "{namespace=\"monitoring\", pod=~\"siem-webhook.*\"}"
          }
        ]
      },
      {
        "title": "Kubernetes Audit Events",
        "type": "logs",
        "targets": [
          {
            "expr": "{job=\"audit_logs\"}"
          }
        ]
      }
    ]
  }
}
EOF
    
    log "✅ SIEM dashboard configuration created." "$GREEN"
}

# Function to show SIEM status
show_siem_status() {
    log "🔍 SIEM Security Status Check" "$CYAN"
    log "============================" "$CYAN"
    
    # Check webhook service status
    log "📡 Webhook Service Status:" "$YELLOW"
    if microk8s kubectl get deployment siem-webhook -n monitoring &>/dev/null; then
        WEBHOOK_STATUS=$(microk8s kubectl get deployment siem-webhook -n monitoring -o jsonpath='{.status.readyReplicas}')
        if [ "$WEBHOOK_STATUS" = "1" ]; then
            log "   ✅ SIEM Webhook service is running" "$GREEN"
        else
            log "   ❌ SIEM Webhook service is not ready" "$RED"
        fi
    else
        log "   ❌ SIEM Webhook service not deployed" "$RED"
    fi
    
    # Check audit logging
    log "📝 Kubernetes Audit Logging:" "$YELLOW"
    if [ -f /var/log/audit-k8s.log ]; then
        AUDIT_LINES=$(wc -l < /var/log/audit-k8s.log)
        log "   ✅ Audit log active with $AUDIT_LINES entries" "$GREEN"
    else
        log "   ❌ Kubernetes audit logging not configured" "$RED"
    fi
    
    # Check security tools
    log "🛡️ Security Tools Status:" "$YELLOW"
    if command -v fail2ban-client &> /dev/null; then
        FAIL2BAN_STATUS=$(sudo systemctl is-active fail2ban)
        if [ "$FAIL2BAN_STATUS" = "active" ]; then
            BANNED_COUNT=$(sudo fail2ban-client status sshd 2>/dev/null | grep "Currently banned" | awk '{print $4}' || echo "0")
            log "   ✅ Fail2ban active (${BANNED_COUNT} IPs banned)" "$GREEN"
        else
            log "   ❌ Fail2ban not active" "$RED"
        fi
    else
        log "   ❌ Fail2ban not installed" "$RED"
    fi
    
    # Check log forwarding
    log "📋 Log Forwarding Status:" "$YELLOW"
    if [ -d /var/log/siem ]; then
        LOG_COUNT=$(find /var/log/siem -name "*.log" | wc -l)
        log "   ✅ SIEM log directory exists with $LOG_COUNT log files" "$GREEN"
    else
        log "   ❌ SIEM log directory not configured" "$RED"
    fi
    
    # Check recent security events
    log "🚨 Recent Security Events (last 24h):" "$YELLOW"
    if [ -f /var/log/siem/security-monitor.log ]; then
        RECENT_EVENTS=$(grep "$(date +%Y-%m-%d)" /var/log/siem/security-monitor.log | wc -l)
        log "   📊 $RECENT_EVENTS security events logged today" "$CYAN"
        
        # Show last few events
        if [ $RECENT_EVENTS -gt 0 ]; then
            log "   📄 Latest events:" "$CYAN"
            tail -5 /var/log/siem/security-monitor.log | grep "$(date +%Y-%m-%d)" | while read -r line; do
                log "     $line" "$CYAN"
            done
        fi
    else
        log "   ❌ No security monitoring log found" "$RED"
    fi
    
    # Show access URLs
    EXTERNAL_IP=$(curl -s ifconfig.me || curl -s ipinfo.io/ip || curl -s icanhazip.com || echo "unknown")
    log "🌐 SIEM Access URLs:" "$CYAN"
    log "   🕸️ Webhook Endpoint: http://webhook.$EXTERNAL_IP.nip.io/webhook" "$CYAN"
    log "   📊 Grafana SIEM Dashboard: http://grafana.$EXTERNAL_IP.nip.io" "$CYAN"
    log "   📋 Configure your Git repositories to send webhooks to the endpoint above" "$YELLOW"
}

# Start the script
log "🎬 Starting DevSecOps Setup Script..." "$PURPLE"
log "Log file: $LOG_FILE" "$CYAN"

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    log "⚠️  This script should not be run as root. Please run as a regular user." "$YELLOW"
    log "Some commands will prompt for sudo when needed." "$YELLOW"
fi

# Show main menu
show_main_menu
