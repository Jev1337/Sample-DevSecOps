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
    
    # Deploy dashboard ConfigMap
    log "Deploying Grafana dashboards ConfigMap..." "$YELLOW"
    microk8s kubectl apply -f k8s/grafana-dashboards-configmap.yaml
    
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

# Function to deploy SIEM stack
deploy_siem_stack() {
    log "🛡️ Deploying SIEM Security Stack..." "$BLUE"
    
    # Create security namespace
    microk8s kubectl get ns security >/dev/null 2>&1 || microk8s kubectl create ns security
    
    # Install system hardening tools
    setup_system_hardening
    
    # Deploy security monitoring components
    deploy_security_monitoring
    
    # Configure Alloy for security log collection
    update_alloy_security_config
    
    # Deploy webhook receiver for Git events
    deploy_webhook_receiver
    
    # Update Grafana with SIEM dashboards
    deploy_siem_dashboards
    
    log "✅ SIEM stack deployed successfully." "$GREEN"
}

# Function to setup system hardening
setup_system_hardening() {
    log "🔒 Setting up system hardening..." "$YELLOW"   
    
    # Install auditd
    if ! command -v auditctl &> /dev/null; then
        log "Installing auditd..." "$YELLOW"
        sudo apt-get update
        sudo apt-get install -y auditd audispd-plugins
        
        # Configure auditd rules
        sudo tee /etc/audit/rules.d/siem.rules > /dev/null <<EOF
# SIEM Security Monitoring Rules

# Monitor authentication events
-w /var/log/auth.log -p wa -k authentication
-w /var/log/secure -p wa -k authentication
-w /etc/passwd -p wa -k passwd_changes
-w /etc/shadow -p wa -k shadow_changes
-w /etc/group -p wa -k group_changes
-w /etc/gshadow -p wa -k gshadow_changes

# Monitor sudo usage
-w /var/log/sudo.log -p wa -k sudo_log
-w /etc/sudoers -p wa -k sudoers_changes

# Monitor SSH configuration
-w /etc/ssh/sshd_config -p wa -k ssh_config

# Monitor package management
-w /var/log/dpkg.log -p wa -k package_changes
-w /var/log/apt/ -p wa -k apt_logs

# Monitor system calls for suspicious activity
-a always,exit -F arch=b64 -S execve -k exec_monitoring
-a always,exit -F arch=b32 -S execve -k exec_monitoring

# Monitor file access in sensitive directories
-w /etc/ -p wa -k etc_changes
-w /bin/ -p wa -k bin_changes
-w /sbin/ -p wa -k sbin_changes
-w /usr/bin/ -p wa -k usr_bin_changes
-w /usr/sbin/ -p wa -k usr_sbin_changes

# Monitor network configuration
-w /etc/hosts -p wa -k network_config
-w /etc/hostname -p wa -k network_config
-w /etc/network/ -p wa -k network_config

# Lock configuration
-e 2
EOF
        
        sudo systemctl enable auditd
        sudo systemctl restart auditd
        log "✅ Auditd configured and started." "$GREEN"
    else
        log "✅ Auditd is already installed." "$GREEN"
    fi
    
    # Install and configure fail2ban
    if ! command -v fail2ban-client &> /dev/null; then
        log "Installing fail2ban..." "$YELLOW"
        sudo apt-get install -y fail2ban
        
        # Configure fail2ban
        sudo tee /etc/fail2ban/jail.local > /dev/null <<EOF
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5
backend = systemd

[sshd]
enabled = true
port = ssh
logpath = /var/log/auth.log
maxretry = 3
bantime = 7200

[nginx-http-auth]
enabled = true
filter = nginx-http-auth
port = http,https
logpath = /var/log/nginx/error.log
maxretry = 3

[webhook-security]
enabled = true
filter = webhook-security
port = http,https
logpath = /var/log/webhook-security.log
maxretry = 5
bantime = 1800
EOF

        # Create custom filter for webhook security
        sudo tee /etc/fail2ban/filter.d/webhook-security.conf > /dev/null <<EOF
[Definition]
failregex = ^.*\[security\].*suspicious webhook attempt from <HOST>.*$
            ^.*\[security\].*invalid signature from <HOST>.*$
            ^.*\[security\].*rate limit exceeded from <HOST>.*$
ignoreregex =
EOF
        
        sudo systemctl enable fail2ban
        sudo systemctl restart fail2ban
        log "✅ Fail2ban configured and started." "$GREEN"
    else
        log "✅ Fail2ban is already installed." "$GREEN"
    fi
    
    # Configure rsyslog for security logging
    log "Configuring rsyslog for security logging..." "$YELLOW"
    sudo tee /etc/rsyslog.d/90-siem.conf > /dev/null <<EOF
# SIEM Security Logging Configuration

# Create separate log files for security events
:msg, contains, "authentication failure" /var/log/security/auth-failures.log
:msg, contains, "sudo:" /var/log/security/sudo.log
:msg, contains, "ssh" /var/log/security/ssh.log
:msg, contains, "fail2ban" /var/log/security/fail2ban.log

# APT package monitoring
:programname, isequal, "dpkg" /var/log/security/package-changes.log
:programname, contains, "apt" /var/log/security/apt.log

# Stop processing these messages after logging
:msg, contains, "authentication failure" stop
:msg, contains, "sudo:" stop
:msg, contains, "ssh" stop
:msg, contains, "fail2ban" stop
:programname, isequal, "dpkg" stop
:programname, contains, "apt" stop
EOF
    
    # Create security log directories
    sudo mkdir -p /var/log/security
    sudo chmod 755 /var/log/security
    
    sudo systemctl restart rsyslog
    log "✅ Rsyslog configured for security logging." "$GREEN"
}

# Function to deploy security monitoring components
deploy_security_monitoring() {
    log "🔍 Deploying security monitoring components..." "$YELLOW"
    
    # Deploy security log collector
    cat <<EOF | microk8s kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: security-log-collector
  namespace: security
data:
  fluent-bit.conf: |
    [SERVICE]
        Flush         1
        Log_Level     info
        Daemon        off
        Parsers_File  parsers.conf
        HTTP_Server   On
        HTTP_Listen   0.0.0.0
        HTTP_Port     2020

    [INPUT]
        Name              tail
        Path              /host/var/log/security/*.log
        Tag               security.*
        Refresh_Interval  5
        Mem_Buf_Limit     50MB

    [INPUT]
        Name              tail
        Path              /host/var/log/audit/audit.log
        Tag               audit
        Parser            audit
        Refresh_Interval  5
        Mem_Buf_Limit     50MB

    [INPUT]
        Name              tail
        Path              /host/var/log/auth.log
        Tag               auth
        Parser            syslog
        Refresh_Interval  5
        Mem_Buf_Limit     50MB

    [OUTPUT]
        Name  http
        Match *
        Host  loki.monitoring.svc.cluster.local
        Port  3100
        URI   /loki/api/v1/push
        Format json
        Json_date_key timestamp
        Json_date_format iso8601

  parsers.conf: |
    [PARSER]
        Name        audit
        Format      regex
        Regex       ^type=(?<type>[^ ]+) msg=audit\((?<timestamp>[0-9.]+):(?<serial>[0-9]+)\): (?<message>.*)$
        Time_Key    timestamp
        Time_Format %s.%L

    [PARSER]
        Name        syslog
        Format      regex
        Regex       ^(?<timestamp>[^ ]+ [^ ]+ [^ ]+) (?<hostname>[^ ]+) (?<program>[^:]+): (?<message>.*)$
        Time_Key    timestamp
        Time_Format %b %d %H:%M:%S
---
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: security-log-collector
  namespace: security
  labels:
    app: security-log-collector
spec:
  selector:
    matchLabels:
      app: security-log-collector
  template:
    metadata:
      labels:
        app: security-log-collector
    spec:
      serviceAccountName: security-log-collector
      containers:
      - name: fluent-bit
        image: fluent/fluent-bit:3.0
        resources:
          limits:
            memory: 200Mi
            cpu: 100m
          requests:
            memory: 100Mi
            cpu: 50m
        volumeMounts:
        - name: config
          mountPath: /fluent-bit/etc/
        - name: var-log
          mountPath: /host/var/log
          readOnly: true
        - name: var-log-security
          mountPath: /host/var/log/security
          readOnly: true
        securityContext:
          privileged: true
          runAsUser: 0
      volumes:
      - name: config
        configMap:
          name: security-log-collector
      - name: var-log
        hostPath:
          path: /var/log
      - name: var-log-security
        hostPath:
          path: /var/log/security
      tolerations:
      - key: node-role.kubernetes.io/control-plane
        operator: Exists
        effect: NoSchedule
      - operator: "Exists"
        effect: "NoExecute"
      - operator: "Exists"
        effect: "NoSchedule"
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: security-log-collector
  namespace: security
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: security-log-collector
rules:
- apiGroups: [""]
  resources: ["pods", "nodes"]
  verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: security-log-collector
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: security-log-collector
subjects:
- kind: ServiceAccount
  name: security-log-collector
  namespace: security
EOF
    
    log "✅ Security log collector deployed." "$GREEN"
}

# Function to update Alloy configuration for security logging
update_alloy_security_config() {
    log "🔧 Updating Alloy configuration for security logging..." "$YELLOW"
    
    # Create enhanced Alloy configuration
    cat <<EOF | microk8s kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: alloy-security-config
  namespace: monitoring
data:
  config.alloy: |
    // Kubernetes pod discovery
    discovery.kubernetes "pods" {
      role = "pod"
    }

    // Pod log collection with security filtering
    discovery.relabel "kubernetes_pods" {
      targets = discovery.kubernetes.pods.targets
      rule {
        source_labels = ["__meta_kubernetes_pod_phase"]
        regex = "Pending|Succeeded|Failed|Completed"
        action = "drop"
      }
      rule {
        source_labels = ["__meta_kubernetes_pod_name"]
        target_label = "pod"
      }
      rule {
        source_labels = ["__meta_kubernetes_namespace"]
        target_label = "namespace"
      }
      rule {
        source_labels = ["__meta_kubernetes_pod_container_name"]
        target_label = "container"
      }
      rule {
        source_labels = ["__meta_kubernetes_pod_label_app"]
        target_label = "app"
      }
    }

    // Host log discovery for security logs
    discovery.file "security_logs" {
      targets = [
        {
          __path__ = "/host/var/log/security/*.log",
          job = "security-logs",
          host = env("HOSTNAME"),
        },
        {
          __path__ = "/host/var/log/audit/audit.log",
          job = "audit-logs", 
          host = env("HOSTNAME"),
        },
        {
          __path__ = "/host/var/log/auth.log",
          job = "auth-logs",
          host = env("HOSTNAME"),
        },
        {
          __path__ = "/host/var/log/fail2ban.log",
          job = "fail2ban-logs",
          host = env("HOSTNAME"),
        },
        {
          __path__ = "/host/var/log/dpkg.log",
          job = "package-logs",
          host = env("HOSTNAME"),
        },
      ]
    }

    // Kubernetes logs processing
    loki.source.kubernetes "pods" {
      targets    = discovery.relabel.kubernetes_pods.output
      forward_to = [loki.process.security_enrichment.receiver]
    }

    // Host security logs processing
    loki.source.file "security_logs" {
      targets    = discovery.file.security_logs.targets
      forward_to = [loki.process.security_enrichment.receiver]
    }

    // Security log processing and enrichment
    loki.process "security_enrichment" {
      stage.json {
        expressions = {
          timestamp = "timestamp",
          level = "level",
          message = "message",
        }
      }

      stage.regex {
        expression = "authentication failure.*from (?P<src_ip>[0-9.]+)"
        source = "message"
      }

      stage.regex {
        expression = "Failed password for (?P<user>\\w+) from (?P<src_ip>[0-9.]+)"
        source = "message"
      }

      stage.regex {
        expression = "sudo.*USER=(?P<sudo_user>\\w+).*COMMAND=(?P<command>.*)"
        source = "message"
      }

      stage.labels {
        values = {
          src_ip = "",
          user = "",
          sudo_user = "",
          command = "",
          security_event = "",
        }
      }

      // Mark security events
      stage.match {
        selector = '{job="auth-logs"}'
        stage.template {
          source = "security_event"
          template = "auth_event"
        }
      }

      stage.match {
        selector = '{job="audit-logs"}'
        stage.template {
          source = "security_event"
          template = "audit_event"
        }
      }

      stage.match {
        selector = '{job="fail2ban-logs"}'
        stage.template {
          source = "security_event"
          template = "intrusion_prevention"
        }
      }

      stage.match {
        selector = '{job="package-logs"}'
        stage.template {
          source = "security_event"
          template = "package_management"
        }
      }

      forward_to = [loki.write.default.receiver]
    }

    // Write to Loki
    loki.write "default" {
      endpoint {
        url = "http://loki.monitoring.svc.cluster.local:3100/loki/api/v1/push"
      }
    }
EOF
    
    # Check if Alloy is already deployed and upgrade it with SIEM configuration
    if microk8s helm3 status alloy -n monitoring &> /dev/null; then
        log "Upgrading existing Alloy deployment with SIEM configuration..." "$YELLOW"
        
        # Upgrade Alloy with the enhanced security configuration
        if microk8s helm3 upgrade alloy grafana/alloy -n monitoring -f helm/alloy/values-siem.yaml; then
            log "✅ Alloy upgraded with security configuration." "$GREEN"
        else
            log "⚠️ Alloy upgrade failed, keeping current configuration..." "$YELLOW"
            log "The Alloy security ConfigMap has been created and can be used manually." "$YELLOW"
        fi
    else
        log "Alloy not found. Deploying with SIEM configuration..." "$YELLOW"
        
        # Deploy Alloy with the enhanced security configuration
        if microk8s helm3 install alloy grafana/alloy -n monitoring -f helm/alloy/values-siem.yaml; then
            log "✅ Alloy deployed with security configuration." "$GREEN"
        else
            log "❌ Failed to deploy Alloy with SIEM configuration." "$RED"
            return 1
        fi
    fi
    
    log "✅ Alloy configuration updated for security logging." "$GREEN"
}

# Function to deploy webhook receiver for Git events
deploy_webhook_receiver() {
    log "🔗 Deploying webhook receiver for Git events..." "$YELLOW"
    
    cat <<EOF | microk8s kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: webhook-config
  namespace: security
data:
  app.py: |
    import os
    import json
    import hmac
    import hashlib
    import logging
    from datetime import datetime
    from flask import Flask, request, jsonify
    import requests

    app = Flask(__name__)

    # Configure logging
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s [%(levelname)s] %(message)s',
        handlers=[
            logging.FileHandler('/var/log/webhook-security.log'),
            logging.StreamHandler()
        ]
    )

    WEBHOOK_SECRET = os.environ.get('WEBHOOK_SECRET', 'default-secret')
    LOKI_URL = os.environ.get('LOKI_URL', 'http://loki.monitoring.svc.cluster.local:3100')

    def verify_signature(payload, signature):
        if not signature:
            return False
        
        expected = 'sha256=' + hmac.new(
            WEBHOOK_SECRET.encode(),
            payload,
            hashlib.sha256
        ).hexdigest()
        
        return hmac.compare_digest(signature, expected)

    def send_to_loki(log_entry):
        timestamp = str(int(datetime.now().timestamp() * 1000000000))
        
        loki_payload = {
            "streams": [
                {
                    "stream": {
                        "job": "webhook-security",
                        "source": "git-webhook",
                        "security_event": "git_activity"
                    },
                    "values": [
                        [timestamp, json.dumps(log_entry)]
                    ]
                }
            ]
        }
        
        try:
            response = requests.post(
                f'{LOKI_URL}/loki/api/v1/push',
                json=loki_payload,
                headers={'Content-Type': 'application/json'}
            )
            app.logger.info(f"Sent to Loki: {response.status_code}")
        except Exception as e:
            app.logger.error(f"Failed to send to Loki: {e}")

    @app.route('/webhook', methods=['POST'])
    def webhook():
        signature = request.headers.get('X-Hub-Signature-256')
        payload = request.get_data()
        client_ip = request.headers.get('X-Forwarded-For', request.remote_addr)
        
        # Log all webhook attempts
        app.logger.info(f"Webhook attempt from {client_ip}")
        
        # Verify signature
        if not verify_signature(payload, signature):
            app.logger.warning(f"[security] invalid signature from {client_ip}")
            return jsonify({'error': 'Invalid signature'}), 403
        
        try:
            data = request.get_json()
            
            # Extract security-relevant information
            log_entry = {
                'timestamp': datetime.now().isoformat(),
                'source_ip': client_ip,
                'event_type': 'git_webhook',
                'repository': data.get('repository', {}).get('full_name', 'unknown'),
                'action': data.get('action', 'unknown'),
                'actor': data.get('sender', {}).get('login', 'unknown'),
                'ref': data.get('ref', ''),
                'commits': len(data.get('commits', [])),
                'user_agent': request.headers.get('User-Agent', ''),
            }
            
            # Check for suspicious activities
            if log_entry['commits'] > 50:
                log_entry['alert'] = 'large_commit_batch'
                app.logger.warning(f"[security] large commit batch from {client_ip}")
            
            if 'password' in str(data).lower() or 'secret' in str(data).lower():
                log_entry['alert'] = 'potential_secret_exposure'
                app.logger.warning(f"[security] potential secret in commit from {client_ip}")
            
            # Send to Loki
            send_to_loki(log_entry)
            
            app.logger.info(f"Processed webhook from {log_entry['repository']} by {log_entry['actor']}")
            return jsonify({'status': 'success'})
            
        except Exception as e:
            app.logger.error(f"[security] webhook processing error from {client_ip}: {e}")
            return jsonify({'error': 'Processing failed'}), 500

    @app.route('/health', methods=['GET'])
    def health():
        return jsonify({'status': 'healthy'})

    if __name__ == '__main__':
        # Create log directory
        os.makedirs('/var/log', exist_ok=True)
        app.run(host='0.0.0.0', port=5000)

  requirements.txt: |
    Flask==3.0.0
    requests==2.31.0

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webhook-receiver
  namespace: security
  labels:
    app: webhook-receiver
spec:
  replicas: 2
  selector:
    matchLabels:
      app: webhook-receiver
  template:
    metadata:
      labels:
        app: webhook-receiver
    spec:
      containers:
      - name: webhook-receiver
        image: python:3.11-slim
        command: ["/bin/sh"]
        args:
          - -c
          - |
            cd /app
            pip install -r requirements.txt
            python app.py
        ports:
        - containerPort: 5000
        env:
        - name: WEBHOOK_SECRET
          valueFrom:
            secretKeyRef:
              name: webhook-secret
              key: secret
        - name: LOKI_URL
          value: "http://loki.monitoring.svc.cluster.local:3100"
        volumeMounts:
        - name: app-code
          mountPath: /app
        - name: webhook-logs
          mountPath: /var/log
        resources:
          limits:
            memory: 256Mi
            cpu: 200m
          requests:
            memory: 128Mi
            cpu: 100m
        securityContext:
          runAsNonRoot: true
          runAsUser: 1000
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: false
      volumes:
      - name: app-code
        configMap:
          name: webhook-config
      - name: webhook-logs
        emptyDir: {}
---
apiVersion: v1
kind: Secret
metadata:
  name: webhook-secret
  namespace: security
type: Opaque
data:
  secret: ZGV2c2Vjb3BzLXdlYmhvb2stc2VjcmV0 # devsecops-webhook-secret (base64)
---
apiVersion: v1
kind: Service
metadata:
  name: webhook-receiver
  namespace: security
  labels:
    app: webhook-receiver
spec:
  selector:
    app: webhook-receiver
  ports:
  - port: 80
    targetPort: 5000
    name: http
  type: ClusterIP
EOF
    
    log "✅ Webhook receiver deployed." "$GREEN"
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
# Function to deploy SIEM dashboards
deploy_siem_dashboards() {
    log "📊 Deploying SIEM dashboards..." "$YELLOW"
    
    # Create comprehensive SIEM dashboard ConfigMap
    cat <<EOF | microk8s kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: siem-dashboards
  namespace: monitoring
  labels:
    grafana_dashboard: "1"
data:
  siem-overview.json: |
    {
      "dashboard": {
        "id": null,
        "title": "SIEM Security Overview",
        "tags": ["security", "siem"],
        "style": "dark",
        "timezone": "browser",
        "panels": [
          {
            "id": 1,
            "title": "Security Events Summary",
            "type": "stat",
            "targets": [
              {
                "expr": "sum(rate({security_event=~\".+\"} [5m]))",
                "refId": "A"
              }
            ],
            "fieldConfig": {
              "defaults": {
                "color": {"mode": "thresholds"},
                "thresholds": {
                  "steps": [
                    {"color": "green", "value": null},
                    {"color": "yellow", "value": 10},
                    {"color": "red", "value": 50}
                  ]
                }
              }
            },
            "gridPos": {"h": 8, "w": 6, "x": 0, "y": 0}
          },
          {
            "id": 2,
            "title": "Authentication Failures",
            "type": "stat",
            "targets": [
              {
                "expr": "sum(count_over_time({job=\"auth-logs\"} |~ \"authentication failure\" [1h]))",
                "refId": "A"
              }
            ],
            "fieldConfig": {
              "defaults": {
                "color": {"mode": "thresholds"},
                "thresholds": {
                  "steps": [
                    {"color": "green", "value": null},
                    {"color": "yellow", "value": 5},
                    {"color": "red", "value": 20}
                  ]
                }
              }
            },
            "gridPos": {"h": 8, "w": 6, "x": 6, "y": 0}
          },
          {
            "id": 3,
            "title": "Failed SSH Logins",
            "type": "stat",
            "targets": [
              {
                "expr": "sum(count_over_time({job=\"auth-logs\"} |~ \"Failed password\" [1h]))",
                "refId": "A"
              }
            ],
            "fieldConfig": {
              "defaults": {
                "color": {"mode": "thresholds"},
                "thresholds": {
                  "steps": [
                    {"color": "green", "value": null},
                    {"color": "yellow", "value": 3},
                    {"color": "red", "value": 10}
                  ]
                }
              }
            },
            "gridPos": {"h": 8, "w": 6, "x": 12, "y": 0}
          },
          {
            "id": 4,
            "title": "Fail2ban Bans",
            "type": "stat",
            "targets": [
              {
                "expr": "sum(count_over_time({job=\"fail2ban-logs\"} |~ \"Ban\" [1h]))",
                "refId": "A"
              }
            ],
            "fieldConfig": {
              "defaults": {
                "color": {"mode": "thresholds"},
                "thresholds": {
                  "steps": [
                    {"color": "green", "value": null},
                    {"color": "orange", "value": 1},
                    {"color": "red", "value": 5}
                  ]
                }
              }
            },
            "gridPos": {"h": 8, "w": 6, "x": 18, "y": 0}
          },
          {
            "id": 5,
            "title": "Security Events Timeline",
            "type": "timeseries",
            "targets": [
              {
                "expr": "sum by (security_event) (rate({security_event=~\".+\"} [5m]))",
                "refId": "A"
              }
            ],
            "gridPos": {"h": 8, "w": 24, "x": 0, "y": 8}
          },
          {
            "id": 6,
            "title": "Top Failed Login IPs",
            "type": "table",
            "targets": [
              {
                "expr": "topk(10, sum by (src_ip) (count_over_time({job=\"auth-logs\"} | regexp \"(?P<src_ip>[0-9.]+)\" |~ \"Failed password\" [1h])))",
                "refId": "A"
              }
            ],
            "gridPos": {"h": 8, "w": 12, "x": 0, "y": 16}
          },
          {
            "id": 7,
            "title": "Sudo Commands",
            "type": "table",
            "targets": [
              {
                "expr": "sum by (sudo_user, command) (count_over_time({job=\"auth-logs\"} | regexp \"USER=(?P<sudo_user>\\\\w+).*COMMAND=(?P<command>.*)\" |~ \"sudo\" [1h]))",
                "refId": "A"
              }
            ],
            "gridPos": {"h": 8, "w": 12, "x": 12, "y": 16}
          },
          {
            "id": 8,
            "title": "Package Management Activity",
            "type": "timeseries",
            "targets": [
              {
                "expr": "rate({job=\"package-logs\"} [5m])",
                "refId": "A"
              }
            ],
            "gridPos": {"h": 8, "w": 24, "x": 0, "y": 24}
          },
          {
            "id": 9,
            "title": "Git Webhook Events",
            "type": "table",
            "targets": [
              {
                "expr": "sum by (repository, actor, action) (count_over_time({job=\"webhook-security\"} [1h]))",
                "refId": "A"
              }
            ],
            "gridPos": {"h": 8, "w": 24, "x": 0, "y": 32}
          }
        ],
        "time": {"from": "now-1h", "to": "now"},
        "timepicker": {},
        "templating": {"list": []},
        "annotations": {"list": []},
        "refresh": "30s",
        "schemaVersion": 16,
        "version": 0,
        "links": []
      }
    }
  
  audit-monitoring.json: |
    {
      "dashboard": {
        "id": null,
        "title": "Audit Log Monitoring",
        "tags": ["security", "audit"],
        "style": "dark",
        "timezone": "browser",
        "panels": [
          {
            "id": 1,
            "title": "System Call Monitoring",
            "type": "timeseries",
            "targets": [
              {
                "expr": "rate({job=\"audit-logs\"} |~ \"type=SYSCALL\" [5m])",
                "refId": "A"
              }
            ],
            "gridPos": {"h": 8, "w": 12, "x": 0, "y": 0}
          },
          {
            "id": 2,
            "title": "File Access Events",
            "type": "timeseries",
            "targets": [
              {
                "expr": "rate({job=\"audit-logs\"} |~ \"type=PATH\" [5m])",
                "refId": "A"
              }
            ],
            "gridPos": {"h": 8, "w": 12, "x": 12, "y": 0}
          },
          {
            "id": 3,
            "title": "User Account Changes",
            "type": "logs",
            "targets": [
              {
                "expr": "{job=\"audit-logs\"} |~ \"passwd|shadow|group\"",
                "refId": "A"
              }
            ],
            "gridPos": {"h": 12, "w": 24, "x": 0, "y": 8}
          },
          {
            "id": 4,
            "title": "Configuration Changes",
            "type": "logs",
            "targets": [
              {
                "expr": "{job=\"audit-logs\"} |~ \"/etc/\"",
                "refId": "A"
              }
            ],
            "gridPos": {"h": 12, "w": 24, "x": 0, "y": 20}
          }
        ],
        "time": {"from": "now-1h", "to": "now"},
        "timepicker": {},
        "templating": {"list": []},
        "annotations": {"list": []},
        "refresh": "30s",
        "schemaVersion": 16,
        "version": 0,
        "links": []
      }
    }

  network-security.json: |
    {
      "dashboard": {
        "id": null,
        "title": "Network Security Monitoring",
        "tags": ["security", "network"],
        "style": "dark",
        "timezone": "browser",
        "panels": [
          {
            "id": 1,
            "title": "Blocked IPs (Fail2ban)",
            "type": "table",
            "targets": [
              {
                "expr": "sum by (src_ip) (count_over_time({job=\"fail2ban-logs\"} | regexp \"Ban (?P<src_ip>[0-9.]+)\" [24h]))",
                "refId": "A"
              }
            ],
            "gridPos": {"h": 10, "w": 12, "x": 0, "y": 0}
          },
          {
            "id": 2,
            "title": "SSH Connection Attempts",
            "type": "timeseries",
            "targets": [
              {
                "expr": "rate({job=\"auth-logs\"} |~ \"sshd.*Connection\" [5m])",
                "refId": "A"
              }
            ],
            "gridPos": {"h": 10, "w": 12, "x": 12, "y": 0}
          },
          {
            "id": 3,
            "title": "Geographic Distribution of Failed Logins",
            "type": "table",
            "targets": [
              {
                "expr": "topk(20, sum by (src_ip) (count_over_time({job=\"auth-logs\"} | regexp \"from (?P<src_ip>[0-9.]+)\" |~ \"Failed\" [24h])))",
                "refId": "A"
              }
            ],
            "gridPos": {"h": 12, "w": 24, "x": 0, "y": 10}
          }
        ],
        "time": {"from": "now-24h", "to": "now"},
        "timepicker": {},
        "templating": {"list": []},
        "annotations": {"list": []},
        "refresh": "1m",
        "schemaVersion": 16,
        "version": 0,
        "links": []
      }
    }
EOF
    
    log "✅ SIEM dashboards deployed." "$GREEN"
}

# Function to configure Azure external access (enhanced for SIEM)
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
    
    # Webhook Receiver LoadBalancer
    cat <<EOF | microk8s kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: webhook-loadbalancer
  namespace: security
spec:
  type: LoadBalancer
  ports:
  - port: 80
    targetPort: 5000
    name: http
  selector:
    app: webhook-receiver
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
    
    # Webhook Receiver Ingress
    cat <<EOF | microk8s kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: webhook-external
  namespace: security
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/rate-limit: "10"
    nginx.ingress.kubernetes.io/rate-limit-window: "1m"
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
            name: webhook-receiver
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
    log "   - Webhook:   http://webhook.$EXTERNAL_IP.nip.io/webhook" "$CYAN"
    log "🌐 Using LoadBalancer IPs:" "$YELLOW"
    log "   - Check the table below for assigned external IPs" "$CYAN"
    log "📋 LoadBalancer External IPs:" "$YELLOW"
    microk8s kubectl get svc -A -o=jsonpath='{range .items[?(@.spec.type=="LoadBalancer")]}{"NAMESPACE: "}{.metadata.namespace}{"\tSERVICE: "}{.metadata.name}{"\tEXTERNAL-IP: "}{.status.loadBalancer.ingress[0].ip}{"\n"}{end}'
    log "🛡️ Security Notes:" "$YELLOW"
    log "   - Ensure Azure NSG allows inbound traffic on ports 80, 443, 8080, 9000, 3000, 5000" "$YELLOW"
    log "   - Webhook endpoint is rate-limited and requires valid signature" "$YELLOW"
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
        echo "  4) Cleanup SIEM Stack (Security monitoring, auditd, fail2ban)"
        echo "  5) Cleanup Development Environment (Docker Compose)"
        echo "  6) Cleanup Azure External Access"
        echo "  7) Cleanup ALL"
        echo "  8) Return to main menu"
        read -p "Enter your choice [1-8]: " cleanup_choice
        
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
                cleanup_siem_stack
                log "✅ SIEM stack cleanup complete." "$GREEN"
                ;;
            5)
                log "Stopping Docker Compose services..." "$YELLOW"
                docker compose down -v
                log "✅ Development environment cleanup complete." "$GREEN"
                ;;
            6)
                log "Removing Azure LoadBalancer services..." "$YELLOW"
                microk8s kubectl delete service jenkins-loadbalancer -n jenkins || true
                microk8s kubectl delete service sonarqube-loadbalancer -n sonarqube || true
                microk8s kubectl delete service grafana-loadbalancer -n monitoring || true
                microk8s kubectl delete service flask-app-loadbalancer -n flask-app || true
                microk8s kubectl delete service webhook-loadbalancer -n security || true
                log "✅ Azure external access cleanup complete." "$GREEN"
                ;;
            7)
                cleanup_all
                cleanup_siem_stack
                docker compose down -v || true
                log "✅ Full cleanup completed!" "$GREEN"
                ;;
            8)
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
    
    # Get external IP if available
    EXTERNAL_IP=$(curl -s ifconfig.me || curl -s ipinfo.io/ip || curl -s icanhazip.com)
    
    echo ""
    log "📝 Add these lines to your /etc/hosts file for local access:" "$YELLOW"
    echo "127.0.0.1 jenkins.local"
    echo "127.0.0.1 sonarqube.local"
    echo "127.0.0.1 grafana.local"
    echo "127.0.0.1 flask-app.local"
    echo "127.0.0.1 webhook.local"
    echo ""
    
    log "🌐 Local Access URLs:" "$CYAN"
    log "   - Flask App: http://flask-app.local" "$CYAN"
    log "   - Jenkins:   http://jenkins.local (admin/${JENKINS_PASS})" "$CYAN"
    log "   - SonarQube: http://sonarqube.local (admin/admin)" "$CYAN"
    log "   - Grafana:   http://grafana.local (admin/admin123)" "$CYAN"
    log "   - Webhook:   http://webhook.local/webhook" "$CYAN"
    echo ""
    
    if [ ! -z "$EXTERNAL_IP" ]; then
        log "🌐 External Access URLs (via nip.io):" "$CYAN"
        log "   - Flask App: http://app.$EXTERNAL_IP.nip.io" "$CYAN"
        log "   - Jenkins:   http://jenkins.$EXTERNAL_IP.nip.io (admin/${JENKINS_PASS})" "$CYAN"
        log "   - SonarQube: http://sonarqube.$EXTERNAL_IP.nip.io (admin/admin)" "$CYAN"
        log "   - Grafana:   http://grafana.$EXTERNAL_IP.nip.io (admin/admin123)" "$CYAN"
        log "   - Webhook:   http://webhook.$EXTERNAL_IP.nip.io/webhook" "$CYAN"
        echo ""
    fi
    
    log "🛡️ SIEM Security Monitoring:" "$YELLOW"
    log "   - Security Dashboard: Available in Grafana under 'SIEM Security Overview'" "$YELLOW"
    log "   - Audit Monitoring: Available in Grafana under 'Audit Log Monitoring'" "$YELLOW"
    log "   - Network Security: Available in Grafana under 'Network Security Monitoring'" "$YELLOW"
    log "   - Real-time Logs: Use Grafana's Explore feature with Loki datasource" "$YELLOW"
    echo ""
    
    log "� Security Features:" "$YELLOW"
    log "   - SSH Login Monitoring: Failed attempts tracked and blocked" "$YELLOW"
    log "   - Package Management: All apt installs/updates logged" "$YELLOW"
    log "   - System Calls: Auditd monitoring file access and executions" "$YELLOW"
    log "   - Git Webhook Security: Secured webhook endpoint with signature verification" "$YELLOW"
    log "   - Intrusion Prevention: Fail2ban automatically blocks suspicious IPs" "$YELLOW"
    echo ""
    
    log "�🛠️  CI/CD Pipeline Setup:" "$YELLOW"
    log "   1. Configure a new 'Pipeline' job in Jenkins" "$YELLOW"
    log "   2. Point it to your Git repository" "$YELLOW"
    log "   3. Set 'Script Path' to 'jenkins/Jenkinsfile'" "$YELLOW"
    log "   4. Configure webhook URL: http://webhook.$EXTERNAL_IP.nip.io/webhook" "$YELLOW"
    log "   5. Set webhook secret: 'devsecops-webhook-secret'" "$YELLOW"
    echo ""
    
    log "📋 SIEM Log Sources:" "$YELLOW"
    log "   - Authentication events: /var/log/security/auth-failures.log" "$YELLOW"
    log "   - SSH activity: /var/log/security/ssh.log" "$YELLOW"
    log "   - Sudo commands: /var/log/security/sudo.log" "$YELLOW"
    log "   - Package changes: /var/log/security/package-changes.log" "$YELLOW"
    log "   - Fail2ban activity: /var/log/security/fail2ban.log" "$YELLOW"
    log "   - Audit logs: /var/log/audit/audit.log" "$YELLOW"
    echo ""
    
    log "🔍 Monitoring Commands:" "$YELLOW"
    log "   - Check fail2ban status: sudo fail2ban-client status" "$YELLOW"
    log "   - View banned IPs: sudo fail2ban-client status sshd" "$YELLOW"
    log "   - Check audit rules: sudo auditctl -l" "$YELLOW"
    log "   - View security logs: tail -f /var/log/security/*.log" "$YELLOW"
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
        echo "  8) Deploy SIEM Stack (Security Monitoring)"
        echo "  9) Configure Azure External Access"
        echo " 10) Full Production Setup (3-8)"
        echo " 11) Full Production + SIEM Setup (3-9)"
        echo " 12) Development Mode (Docker Compose)"
        echo " 13) Cleanup Options"
        echo " 14) Show Access Information"
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
                deploy_siem_stack
                ;;
            9)
                configure_azure_access
                ;;
            10)
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
            11)
                log "🛡️ Starting Full Production + SIEM Setup..." "$PURPLE"
                check_prerequisites
                setup_microk8s
                build_jenkins_image
                deploy_core_services
                deploy_monitoring_stack
                deploy_application
                deploy_siem_stack
                configure_azure_access
                show_access_info
                log "✅ Full production + SIEM setup completed!" "$GREEN"
                ;;
            12)
                run_development_mode
                ;;
            13)
                run_cleanup
                ;;
            14)
                show_access_info
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
    log "Deleting Grafana dashboards ConfigMap..." "$YELLOW"
    microk8s kubectl delete configmap grafana-dashboards -n monitoring || true
    microk8s kubectl delete configmap siem-dashboards -n monitoring || true
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

cleanup_siem_stack() {
    log "❌ Cleaning up SIEM stack..." "$YELLOW"
    
    # Remove security namespace and all components
    log "Deleting security namespace..." "$YELLOW"
    microk8s kubectl delete ns security --ignore-not-found
    
    # Stop and disable system services
    log "Stopping fail2ban..." "$YELLOW"
    sudo systemctl stop fail2ban || true
    sudo systemctl disable fail2ban || true
    
    log "Stopping auditd..." "$YELLOW"
    sudo systemctl stop auditd || true
    sudo systemctl disable auditd || true
    
    # Remove configuration files
    log "Removing SIEM configuration files..." "$YELLOW"
    sudo rm -f /etc/audit/rules.d/siem.rules || true
    sudo rm -f /etc/fail2ban/jail.local || true
    sudo rm -f /etc/fail2ban/filter.d/webhook-security.conf || true
    sudo rm -f /etc/rsyslog.d/90-siem.conf || true
    
    # Remove security log directories
    log "Removing security log directories..." "$YELLOW"
    sudo rm -rf /var/log/security || true
    
    # Restart services to apply changes
    log "Restarting services..." "$YELLOW"
    sudo systemctl restart rsyslog || true
    
    log "✅ SIEM stack cleanup completed." "$GREEN"
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
