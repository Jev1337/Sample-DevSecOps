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
    
    if ! check_command curl; then
        missing_tools+=("curl")
    fi
    
    if ! check_command docker; then
        log "⚠️  Docker not found. Will offer installation." "$YELLOW"
    fi
    
    # Check for SIEM prerequisites
    log "📝 Checking SIEM prerequisites..." "$BLUE"
    if ! check_command systemctl; then
        missing_tools+=("systemctl")
    fi
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        log "❌ Missing required tools: ${missing_tools[*]}" "$RED"
        log "Please install missing tools and re-run the script." "$RED"
        exit 1
    fi
    
    # Check if running as non-root user
    if [[ $EUID -eq 0 ]]; then
        log "⚠️  This script should not be run as root for security reasons." "$YELLOW"
        log "Please run as a regular user with sudo privileges." "$YELLOW"
        exit 1
    fi
    
    # Check sudo access
    if ! sudo -v &>/dev/null; then
        log "❌ Sudo access required for SIEM installation." "$RED"
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
    
    # Deploy Grafana with SIEM configuration
    if ! microk8s helm3 status grafana -n monitoring &> /dev/null; then
        log "Deploying Grafana with SIEM dashboards..." "$YELLOW"
        microk8s helm3 install grafana grafana/grafana -n monitoring -f helm/grafana/siem-values.yaml
    else
        log "✅ Grafana is already deployed." "$GREEN"
    fi
    
    # Deploy Alloy with SIEM configuration
    if ! microk8s helm3 status alloy -n monitoring &> /dev/null; then
        log "Deploying Alloy with SIEM log collection..." "$YELLOW"
        microk8s helm3 install alloy grafana/alloy -n monitoring -f helm/alloy/siem-values.yaml
    else
        log "✅ Alloy is already deployed." "$GREEN"
    fi
    
    log "⏳ Waiting for monitoring components..." "$YELLOW"
    microk8s kubectl rollout status statefulset/loki -n monitoring --timeout=5m
    microk8s kubectl rollout status deployment/grafana -n monitoring --timeout=5m
    microk8s kubectl rollout status daemonset/alloy -n monitoring --timeout=5m
    
    log "✅ Monitoring stack deployed successfully." "$GREEN"
}

# Function to deploy SIEM security agents and configuration
deploy_siem_agents() {
    log "🛡️ Deploying SIEM Security Agents..." "$BLUE"
    
    # Install auditd for system auditing
    log "Installing auditd for system auditing..." "$YELLOW"
    sudo apt-get update
    sudo apt-get install -y auditd audispd-plugins
    
    # Configure auditd rules for security monitoring
    log "Configuring auditd security rules..." "$YELLOW"
    sudo tee /etc/audit/rules.d/siem-security.rules > /dev/null << 'EOF'
# SIEM Security Audit Rules
# Monitor authentication events
-w /etc/passwd -p wa -k user_accounts
-w /etc/group -p wa -k user_accounts
-w /etc/shadow -p wa -k user_accounts
-w /etc/sudoers -p wa -k privilege_escalation

# Monitor SSH configuration and keys
-w /etc/ssh/sshd_config -p wa -k ssh_config
-w /etc/ssh/ -p wa -k ssh_config
-w /root/.ssh/ -p wa -k ssh_keys
-w /home/*/.ssh/ -p wa -k ssh_keys

# Monitor system executables
-w /usr/bin/wget -p x -k network_tools
-w /usr/bin/curl -p x -k network_tools
-w /usr/bin/nc -p x -k network_tools
-w /usr/bin/nmap -p x -k network_tools

# Monitor package management
-w /usr/bin/apt -p x -k package_management
-w /usr/bin/apt-get -p x -k package_management
-w /usr/bin/dpkg -p x -k package_management
-w /usr/bin/yum -p x -k package_management
-w /usr/bin/rpm -p x -k package_management

# Monitor sudo usage
-w /usr/bin/sudo -p x -k privilege_escalation
-w /etc/sudoers -p wa -k privilege_escalation

# Monitor critical system files
-w /etc/crontab -p wa -k system_config
-w /etc/cron.d/ -p wa -k system_config
-w /etc/systemd/ -p wa -k system_config
-w /etc/init.d/ -p wa -k system_config

# Monitor network configuration
-w /etc/hosts -p wa -k network_config
-w /etc/resolv.conf -p wa -k network_config
-w /etc/network/ -p wa -k network_config

# Monitor log files
-w /var/log/auth.log -p wa -k log_tampering
-w /var/log/secure -p wa -k log_tampering
-w /var/log/audit/ -p wa -k log_tampering
EOF
    
    # Enable and restart auditd
    sudo systemctl enable auditd
    sudo systemctl restart auditd
    
    # Configure rsyslog for centralized logging
    log "Configuring rsyslog for SIEM..." "$YELLOW"
    sudo tee /etc/rsyslog.d/50-siem.conf > /dev/null << 'EOF'
# SIEM Logging Configuration
# Log authentication events
auth,authpriv.*          /var/log/auth.log

# Log sudo commands
local0.*                 /var/log/sudo.log

# Log user account modifications
user.*                   /var/log/user.log

# Log network events (if available)
kern.*                   /var/log/kernel.log

# Log package management events
local1.*                 /var/log/package.log
EOF
    
    sudo systemctl restart rsyslog
    
    # Install and configure fail2ban for intrusion prevention
    log "Installing fail2ban for intrusion prevention..." "$YELLOW"
    sudo apt-get install -y fail2ban
    
    sudo tee /etc/fail2ban/jail.local > /dev/null << 'EOF'
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

[sshd-ddos]
enabled = true
port = ssh
logpath = /var/log/auth.log
maxretry = 6
bantime = 3600

[sudo]
enabled = true
logpath = /var/log/sudo.log
maxretry = 3
bantime = 3600
EOF
    
    sudo systemctl enable fail2ban
    sudo systemctl restart fail2ban
    
    # Setup webhook monitoring
    log "Setting up webhook monitoring..." "$YELLOW"
    sudo mkdir -p /var/log/webhooks
    sudo touch /var/log/webhook.log
    sudo chmod 644 /var/log/webhook.log
    
    # Create webhook monitoring script
    sudo tee /usr/local/bin/webhook-monitor.sh > /dev/null << 'EOF'
#!/bin/bash
# Webhook monitoring script for SIEM
WEBHOOK_URL="http://webhook.4.245.1.92.nip.io/webhook"
LOG_FILE="/var/log/webhook.log"

# Monitor webhook endpoint
while true; do
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "$WEBHOOK_URL" 2>/dev/null)
    echo "[$TIMESTAMP] Webhook check: $WEBHOOK_URL Response: $RESPONSE" >> "$LOG_FILE"
    sleep 300  # Check every 5 minutes
done
EOF
    
    sudo chmod +x /usr/local/bin/webhook-monitor.sh
    
    # Create systemd service for webhook monitoring
    sudo tee /etc/systemd/system/webhook-monitor.service > /dev/null << 'EOF'
[Unit]
Description=Webhook Monitoring Service for SIEM
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/webhook-monitor.sh
Restart=always
RestartSec=30

[Install]
WantedBy=multi-user.target
EOF
    
    sudo systemctl enable webhook-monitor.service
    sudo systemctl start webhook-monitor.service
    
    # Deploy host-based log collector as DaemonSet
    log "Deploying host-based log collector DaemonSet..." "$YELLOW"
    cat <<EOF | microk8s kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: siem-log-collector
  namespace: monitoring
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: siem-log-collector
rules:
- apiGroups: [""]
  resources: ["nodes", "pods"]
  verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: siem-log-collector
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: siem-log-collector
subjects:
- kind: ServiceAccount
  name: siem-log-collector
  namespace: monitoring
---
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: siem-log-collector
  namespace: monitoring
  labels:
    app: siem-log-collector
spec:
  selector:
    matchLabels:
      app: siem-log-collector
  template:
    metadata:
      labels:
        app: siem-log-collector
    spec:
      serviceAccountName: siem-log-collector
      hostNetwork: true
      hostPID: true
      containers:
      - name: log-collector
        image: grafana/alloy:latest
        env:
        - name: HOSTNAME
          valueFrom:
            fieldRef:
              fieldPath: spec.nodeName
        volumeMounts:
        - name: var-log
          mountPath: /var/log
          readOnly: true
        - name: var-lib-docker-containers
          mountPath: /var/lib/docker/containers
          readOnly: true
        - name: config
          mountPath: /etc/alloy
        securityContext:
          privileged: true
        command:
        - /bin/alloy
        - run
        - /etc/alloy/config.alloy
        - --storage.path=/tmp/alloy
        - --server.http.listen-addr=0.0.0.0:12345
      volumes:
      - name: var-log
        hostPath:
          path: /var/log
      - name: var-lib-docker-containers
        hostPath:
          path: /var/lib/docker/containers
      - name: config
        configMap:
          name: siem-host-config
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: siem-host-config
  namespace: monitoring
data:
  config.alloy: |
    // Host-based SIEM log collection
    loki.source.file "host_auth_logs" {
      targets = [
        {__path__ = "/var/log/auth.log", job = "host_auth", host = env("HOSTNAME")},
        {__path__ = "/var/log/sudo.log", job = "host_sudo", host = env("HOSTNAME")},
        {__path__ = "/var/log/audit/audit.log", job = "host_audit", host = env("HOSTNAME")},
        {__path__ = "/var/log/webhook.log", job = "host_webhook", host = env("HOSTNAME")},
        {__path__ = "/var/log/fail2ban.log", job = "host_security", host = env("HOSTNAME")},
      ]
      forward_to = [loki.process.host_security.receiver]
    }

    loki.process "host_security" {
      // SSH login detection
      stage.match {
        selector = '{job="host_auth"} |~ "sshd.*Accepted|sshd.*Failed"'
        stage.regex {
          expression = "(?P<timestamp>\\w{3}\\s+\\d{1,2}\\s+\\d{2}:\\d{2}:\\d{2}).*sshd.*?(?P<auth_status>Accepted|Failed)\\s+(?P<auth_method>\\w+)\\s+for\\s+(?P<username>\\w+)\\s+from\\s+(?P<source_ip>[\\d\\.]+)"
        }
        stage.labels {
          values = {
            event_type = "ssh_auth",
            auth_status = "",
            auth_method = "",
            username = "",
            source_ip = "",
          }
        }
      }

      // Sudo usage detection
      stage.match {
        selector = '{job="host_sudo"}'
        stage.regex {
          expression = "(?P<timestamp>\\w{3}\\s+\\d{1,2}\\s+\\d{2}:\\d{2}:\\d{2}).*?USER=(?P<sudo_user>\\w+).*?COMMAND=(?P<command>.*)"
        }
        stage.labels {
          values = {
            event_type = "sudo_usage",
            sudo_user = "",
            command = "",
          }
        }
      }

      // Audit log processing
      stage.match {
        selector = '{job="host_audit"}'
        stage.regex {
          expression = "type=(?P<audit_type>\\w+).*?uid=(?P<uid>\\d+).*?exe=\"(?P<executable>[^\"]+)\""
        }
        stage.labels {
          values = {
            event_type = "audit_event",
            audit_type = "",
            uid = "",
            executable = "",
          }
        }
      }

      // Webhook monitoring
      stage.match {
        selector = '{job="host_webhook"}'
        stage.regex {
          expression = "\\[(?P<timestamp>[^\\]]+)\\]\\s+Webhook check:\\s+(?P<webhook_url>\\S+)\\s+Response:\\s+(?P<response_code>\\d+)"
        }
        stage.labels {
          values = {
            event_type = "webhook_check",
            webhook_url = "",
            response_code = "",
          }
        }
      }

      // Fail2ban security events
      stage.match {
        selector = '{job="host_security"} |~ "fail2ban"'
        stage.regex {
          expression = "fail2ban.*?(?P<action>Ban|Unban)\\s+(?P<ip>[\\d\\.]+)"
        }
        stage.labels {
          values = {
            event_type = "intrusion_prevention",
            action = "",
            ip = "",
          }
        }
      }

      forward_to = [loki.write.default.receiver]
    }

    loki.write "default" {
      endpoint {
        url = "http://loki.monitoring.svc.cluster.local:3100/loki/api/v1/push"
      }
    }
EOF
    
    log "✅ SIEM security agents deployed successfully." "$GREEN"
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
    log "🔍 SIEM Monitoring Active:" "$CYAN"
    log "   - All external access attempts are being logged and monitored" "$CYAN"
    log "   - Failed authentication attempts trigger security alerts" "$CYAN"
    log "   - Access to Grafana SIEM dashboards: http://grafana.$EXTERNAL_IP.nip.io/d/siem-overview" "$CYAN"
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
                cleanup_siem
                log "✅ Monitoring stack and SIEM cleanup complete." "$GREEN"
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
                cleanup_siem
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
    
    log "�️ SIEM Security Dashboards:" "$YELLOW"
    log "   - SIEM Overview: http://grafana.local/d/siem-overview" "$CYAN"
    log "   - SSH Monitoring: http://grafana.local/d/ssh-monitoring" "$CYAN"
    log "   - Security Events: Navigate to SIEM folder in Grafana" "$CYAN"
    echo ""
    
    log "🔍 SIEM Security Monitoring:" "$YELLOW"
    log "   - Authentication events: Monitored via auditd and auth.log" "$CYAN"
    log "   - SSH access: Real-time monitoring with fail2ban protection" "$CYAN"
    log "   - Sudo usage: All sudo commands logged and tracked" "$CYAN"
    log "   - Package management: Installation/removal events tracked" "$CYAN"
    log "   - Git webhook: Monitoring http://webhook.4.245.1.92.nip.io/webhook" "$CYAN"
    log "   - System files: Critical file modifications monitored" "$CYAN"
    echo ""
    
    log "�🛠️ CI/CD Pipeline Setup:" "$YELLOW"
    log "   1. Configure a new 'Pipeline' job in Jenkins" "$YELLOW"
    log "   2. Point it to your Git repository" "$YELLOW"
    log "   3. Set 'Script Path' to 'jenkins/Jenkinsfile'" "$YELLOW"
    echo ""
    
    log "🚨 Security Alert Sources:" "$YELLOW"
    log "   - Failed SSH attempts logged to SIEM" "$CYAN"
    log "   - Privileged command execution tracked" "$CYAN"
    log "   - User account modifications monitored" "$CYAN"
    log "   - Network connection anomalies detected" "$CYAN"
    log "   - Package installations tracked for compliance" "$CYAN"
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
        echo "  6) Deploy Monitoring Stack (Loki, Grafana, Alloy)"
        echo "  7) Deploy Flask Application"
        echo "  8) Configure Azure External Access"
        echo "  9) Deploy SIEM Security Agents"
        echo " 10) Full Production Setup (3-7,9)"
        echo " 11) Development Mode (Docker Compose)"
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
                deploy_siem_agents
                ;;
            10)
                log "🚀 Starting Full Production Setup with SIEM..." "$PURPLE"
                check_prerequisites
                setup_microk8s
                build_jenkins_image
                deploy_core_services
                deploy_monitoring_stack
                deploy_siem_agents
                deploy_application
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
    cleanup_siem
}

# SIEM cleanup function
cleanup_siem() {
    log "❌ Cleaning up SIEM components..." "$YELLOW"
    
    # Stop and disable SIEM services
    sudo systemctl stop webhook-monitor.service || true
    sudo systemctl disable webhook-monitor.service || true
    sudo systemctl stop fail2ban || true
    sudo systemctl disable fail2ban || true
    
    # Remove SIEM service files
    sudo rm -f /etc/systemd/system/webhook-monitor.service
    sudo rm -f /usr/local/bin/webhook-monitor.sh
    
    # Remove SIEM configurations
    sudo rm -f /etc/audit/rules.d/siem-security.rules
    sudo rm -f /etc/rsyslog.d/50-siem.conf
    sudo rm -f /etc/fail2ban/jail.local
    
    # Remove SIEM log files
    sudo rm -f /var/log/webhook.log
    sudo rm -f /var/log/sudo.log
    sudo rm -f /var/log/user.log
    sudo rm -f /var/log/package.log
    
    # Remove SIEM Kubernetes resources
    microk8s kubectl delete daemonset siem-log-collector -n monitoring || true
    microk8s kubectl delete configmap siem-host-config -n monitoring || true
    microk8s kubectl delete serviceaccount siem-log-collector -n monitoring || true
    microk8s kubectl delete clusterrole siem-log-collector || true
    microk8s kubectl delete clusterrolebinding siem-log-collector || true
    
    # Restart services
    sudo systemctl restart rsyslog || true
    sudo systemctl restart auditd || true
    sudo systemctl daemon-reload
    
    log "✅ SIEM cleanup completed." "$GREEN"
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
