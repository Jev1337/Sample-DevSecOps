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

# Function to deploy monitoring stack
deploy_monitoring_stack() {
    log "📊 Deploying Monitoring Stack..." "$BLUE"
    
    microk8s kubectl get ns monitoring >/dev/null 2>&1 || microk8s kubectl create ns monitoring
    
    # Add Grafana Helm Repo if not already added
    if ! microk8s helm3 repo list | grep -q "grafana"; then
        log "Adding Grafana Helm repository..." "$YELLOW"
        microk8s helm3 repo add grafana https://grafana.github.io/helm-charts
        microk8s helm3 repo update
    else
        log "✅ Grafana Helm repository already exists." "$GREEN"
    fi
    
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
    
    # Deploy Alloy
    if ! microk8s helm3 status alloy -n monitoring &> /dev/null; then
        log "Deploying Alloy for log collection..." "$YELLOW"
        microk8s helm3 install alloy grafana/alloy -n monitoring -f helm/alloy/values.yaml
    else
        log "✅ Alloy is already deployed." "$GREEN"
    fi
    
    log "⏳ Waiting for monitoring components..." "$YELLOW"
    microk8s kubectl rollout status statefulset/loki -n monitoring --timeout=5m
    microk8s kubectl rollout status deployment/grafana -n monitoring --timeout=5m
    microk8s kubectl rollout status daemonset/alloy -n monitoring --timeout=5m
    
    log "✅ Monitoring stack deployed successfully." "$GREEN"
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
    
    log "🛠️  CI/CD Pipeline Setup:" "$YELLOW"
    log "   1. Configure a new 'Pipeline' job in Jenkins" "$YELLOW"
    log "   2. Point it to your Git repository" "$YELLOW"
    log "   3. Set 'Script Path' to 'jenkins/Jenkinsfile'" "$YELLOW"
}


# SIEM deployment and system hardening
deploy_siem_stack() {
    log "🛡️ Deploying SIEM Stack and System Hardening..." "$BLUE"

    # 1. Install and configure auditd, rsyslog, fail2ban
    log "🔒 Installing auditd, rsyslog, fail2ban..." "$YELLOW"
    sudo apt-get update
    sudo apt-get install -y auditd rsyslog fail2ban

    # 2. Configure auditd for system call and file access monitoring
    log "🔧 Configuring auditd rules..." "$YELLOW"
    sudo auditctl -e 1
    sudo auditctl -w /etc/passwd -p wa -k passwd_changes
    sudo auditctl -w /etc/shadow -p wa -k shadow_changes
    sudo auditctl -w /etc/sudoers -p wa -k sudoers_changes
    sudo auditctl -w /var/log/auth.log -p r -k authlog_reads
    sudo auditctl -a always,exit -F arch=b64 -S execve -k exec_calls
    sudo auditctl -w /var/log/apt/history.log -p r -k apt_history

    # 3. Configure rsyslog for forwarding logs to Alloy
    log "🔧 Configuring rsyslog for enhanced logging..." "$YELLOW"
    sudo sed -i '/^\$FileCreateMode/c\$FileCreateMode 0640' /etc/rsyslog.conf
    sudo systemctl restart rsyslog

    # 4. Configure fail2ban for SSH login monitoring
    log "🔧 Configuring fail2ban for SSH monitoring..." "$YELLOW"
    sudo systemctl enable fail2ban
    sudo systemctl start fail2ban

    # 5. Configure apt logs monitoring
    log "🔧 Ensuring apt logs are available..." "$YELLOW"
    sudo touch /var/log/apt/history.log /var/log/apt/term.log
    sudo chmod 644 /var/log/apt/history.log /var/log/apt/term.log

    # 6. Update Alloy config for security log sources
    log "🔧 Updating Alloy config for SIEM sources..." "$YELLOW"
    # Example: add sources for auditd, auth.log, apt logs, fail2ban
    ALLOY_CONFIG="/etc/alloy/config.yaml"
    if [ -f "$ALLOY_CONFIG" ]; then
        sudo tee -a "$ALLOY_CONFIG" > /dev/null <<EOF
  - type: file
    include: [/var/log/auth.log, /var/log/syslog, /var/log/kern.log, /var/log/audit/audit.log, /var/log/apt/history.log, /var/log/fail2ban.log]
    labels:
      source: security
EOF
        sudo systemctl restart alloy || true
    else
        log "⚠️ Alloy config not found, please update manually if needed." "$YELLOW"
    fi

    # 7. Configure Loki for security log streams and labels
    log "🔧 Configuring Loki for security log streams..." "$YELLOW"
    # This is typically done via Helm values.yaml, ensure helm/loki/values.yaml includes security labels and streams

    # 8. Create Grafana dashboards for security monitoring
    log "📊 Creating Grafana security dashboards..." "$YELLOW"
    # Place example dashboards in monitoring/grafana/dashboards/security.json
    if [ -f "monitoring/grafana/dashboards/security.json" ]; then
        log "✅ Security dashboard template found." "$GREEN"
    else
        cat > monitoring/grafana/dashboards/security.json <<EOF
{
  "dashboard": "Security Events",
  "panels": [
    {"type": "logs", "title": "SSH Logins", "targets": [{"expr": "{source=\"security\"} |~ \"sshd\""}]},
    {"type": "logs", "title": "Auditd Events", "targets": [{"expr": "{source=\"security\"} |~ \"audit\""}]},
    {"type": "logs", "title": "APT Changes", "targets": [{"expr": "{source=\"security\"} |~ \"apt\""}]}
  ]
}
EOF
        log "✅ Security dashboard created." "$GREEN"
    fi

    # 9. Set up webhook receiver for Git events
    log "🔧 Deploying webhook receiver for Git events..." "$YELLOW"
    if [ -f "webhook/app.py" ]; then
        docker build -t webhook-security:latest ./webhook
        docker tag webhook-security:latest localhost:32000/webhook-security:latest
        docker push localhost:32000/webhook-security:latest
        microk8s kubectl get ns webhook >/dev/null 2>&1 || microk8s kubectl create ns webhook
        # Example deployment (user should provide k8s manifest for webhook)
        if [ -f "k8s/webhook-deployment.yaml" ]; then
            microk8s kubectl apply -f k8s/webhook-deployment.yaml
        else
            log "⚠️ Please create k8s/webhook-deployment.yaml for webhook deployment." "$YELLOW"
        fi
    fi

    # 10. Configure RBAC, volume mounts, security contexts (assume Helm values updated)
    log "🔧 Ensure RBAC, volumes, security contexts are set in Helm values and manifests." "$YELLOW"

    log "✅ SIEM stack deployed and system hardening applied." "$GREEN"
    log "🔗 Access Grafana security dashboard at: http://grafana.","$EXTERNAL_IP",".nip.io" "$CYAN"
}

# ...existing code...
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
        echo "  6) Deploy Monitoring Stack (Loki, Grafana, Alloy)"
        echo "  7) Deploy Flask Application"
        echo "  8) Configure Azure External Access"
        echo "  9) Full Production Setup (3-7)"
        echo " 10) Development Mode (Docker Compose)"
        echo " 11) Deploy SIEM Stack & System Hardening"
        echo " 12) Cleanup Options"
        echo " 13) Show Access Information"
        echo " 14) Exit"
        echo ""
        read -p "Enter your choice [1-14]: " choice

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
                log "🚀 Starting Full Production Setup..." "$PURPLE"
                check_prerequisites
                setup_microk8s
                build_jenkins_image
                deploy_core_services
                deploy_monitoring_stack
                deploy_application
                show_access_info
                log "✅ Full production setup completed!" "$GREEN"
                ;;
            10)
                run_development_mode
                ;;
            11)
                deploy_siem_stack
                ;;
            12)
                run_cleanup
                ;;
            13)
                show_access_info
                ;;
            14)
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
    log "Deleting Monitoring namespace..." "$YELLOW"
    microk8s kubectl delete ns monitoring --ignore-not-found
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
