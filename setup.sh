#!/bin/bash

set -e

echo "🚀 DevSecOps Environment Setup Script for MicroK8s on Linux"
echo "============================================================"

# Function to check if a command exists
check_command() {
    if ! command -v $1 &> /dev/null; then
        echo "❌ Error: $1 is not installed. Please install it and re-run the script."
        exit 1
    fi
}

# --- 1. Prerequisites Check ---
echo "📝 Step 1: Checking prerequisites..."
check_command snap
check_command git
check_command docker
echo "✅ Prerequisites are met."
echo ""

# --- 2. Install and Configure MicroK8s ---
echo "🔧 Step 2: Setting up MicroK8s..."
if ! command -v microk8s &> /dev/null; then
    echo "Installing MicroK8s..."
    sudo snap install microk8s --classic --channel=1.30/stable
    sudo usermod -a -G microk8s $USER
    sudo chown -f -R $USER ~/.kube
    echo "✅ MicroK8s installed. IMPORTANT: Please run 'newgrp microk8s' or log out and log back in for group changes to take effect, then re-run this script."
    exit 0
else
    echo "✅ MicroK8s is already installed."
fi

echo "Waiting for MicroK8s to be ready..."
microk8s status --wait-ready

echo "🔌 Enabling MicroK8s addons..."
microk8s enable dns
microk8s enable helm3
microk8s enable ingress
microk8s enable metrics-server
microk8s enable storage
microk8s enable registry --size 20Gi
echo "✅ Addons enabled."
echo ""

# --- 3. Deploy Core Services (Jenkins & SonarQube) ---
echo "🚀 Step 3: Deploying Jenkins and SonarQube..."

# Create Namespaces
echo "Creating namespaces..."
microk8s kubectl apply -f k8s/namespace.yaml
microk8s kubectl get ns jenkins >/dev/null 2>&1 || microk8s kubectl create ns jenkins
microk8s kubectl get ns sonarqube >/dev/null 2>&1 || microk8s kubectl create ns sonarqube

# Deploy Jenkins
if ! microk8s helm3 status jenkins -n jenkins &> /dev/null; then
    echo "Deploying Jenkins via Helm..."
    microk8s helm3 repo add jenkins https://charts.jenkins.io
    microk8s helm3 repo update
    # Using a simple values file for ingress and persistence
    cat <<EOF > jenkins/jenkins-values.yaml
controller:
  ingress:
    enabled: true
    hostName: jenkins.local
    ingressClassName: public
  servicePort: 8080
  jenkinsUrl: http://jenkins.local/
  podSecurityContext:
    fsGroup: 1000
    runAsUser: 1000
  sidecars:
    configAutoReload:
      enabled: false
persistence:
  storageClass: "microk8s-hostpath"
  size: "8Gi"
EOF
    microk8s helm3 install jenkins jenkins/jenkins -n jenkins -f jenkins/jenkins-values.yaml
else
    echo "✅ Jenkins is already deployed."
fi

# Deploy SonarQube
if ! microk8s helm3 status sonarqube -n sonarqube &> /dev/null; then
    echo "Deploying SonarQube via Helm..."
    microk8s helm3 repo add sonarqube https://SonarSource.github.io/helm-chart-sonarqube
    microk8s helm3 repo update
    # Using a simple values file for ingress and persistence
    cat <<EOF > security/sonarqube/sonarqube-values.yaml
ingress:
  enabled: true
  hosts:
    - name: sonarqube.local
  ingressClassName: public
persistence:
  storageClass: "microk8s-hostpath"
  size: "8Gi"
monitoringPasscode: "admin"
edition: ""
community:
  enabled: true
EOF
    microk8s helm3 install sonarqube sonarqube/sonarqube -n sonarqube -f security/sonarqube/sonarqube-values.yaml
else
    echo "✅ SonarQube is already deployed."
fi

echo "⏳ Waiting for Jenkins and SonarQube to be ready..."
microk8s kubectl rollout status statefulset/jenkins -n jenkins --timeout=5m
microk8s kubectl rollout status statefulset/sonarqube-sonarqube -n sonarqube --timeout=5m
echo "✅ Jenkins and SonarQube are ready."
echo ""

# --- 4. Deploy Monitoring Stack ---
echo "📊 Step 4: Deploying Monitoring Stack via Helm..."
microk8s kubectl get ns monitoring >/dev/null 2>&1 || microk8s kubectl create ns monitoring

# Add Grafana Helm Repo if not already added
if ! microk8s helm3 repo list | grep -q "grafana"; then
    echo "Adding Grafana Helm repository..."
    microk8s helm3 repo add grafana https://grafana.github.io/helm-charts
    microk8s helm3 repo update
else
    echo "✅ Grafana Helm repository already exists."
fi

# Deploy Loki
if ! microk8s helm3 status loki -n monitoring &> /dev/null; then
    echo "Deploying Loki via Helm..."
    cat <<EOF > monitoring/loki-values.yaml
loki:
  storage:
    type: filesystem
write:
  enabled: false
read:
  enabled: false
backend:
  enabled: false
singleBinary:
  enabled: true
  persistence:
    enabled: true
    storageClassName: "microk8s-hostpath"
    size: "10Gi"
EOF
    microk8s helm3 install loki grafana/loki -n monitoring -f monitoring/loki-values.yaml
else
    echo "✅ Loki is already deployed."
fi

# Deploy Grafana
if ! microk8s helm3 status grafana -n monitoring &> /dev/null; then
    echo "Deploying Grafana via Helm..."
    cat <<EOF > monitoring/grafana-values.yaml
persistence:
  enabled: true
  storageClassName: "microk8s-hostpath"
  size: "2Gi"
adminPassword: "admin123"
ingress:
  enabled: true
  ingressClassName: public
  hosts:
    - grafana.local
datasources:
  datasources.yaml:
    apiVersion: 1
    datasources:
    - name: Loki
      type: loki
      url: http://loki-read.monitoring.svc.cluster.local:3100
      access: proxy
      isDefault: true
EOF
    microk8s helm3 install grafana grafana/grafana -n monitoring -f monitoring/grafana-values.yaml
else
    echo "✅ Grafana is already deployed."
fi

# Deploy Alloy
if ! microk8s helm3 status alloy -n monitoring &> /dev/null; then
    echo "Deploying Alloy for log collection..."
    cat <<EOF > monitoring/alloy-values.yaml
alloy:
  configMap:
    create: true
    content: |
      discovery.kubernetes "pods" {
        forward_to = [loki.source.kubernetes_pods.receiver]
      }

      loki.source.kubernetes_pods "logs" {
        forward_to = [loki.write.default.receiver]
      }

      loki.write "default" {
        endpoint {
          url = "http://loki-write.monitoring.svc.cluster.local:3100/loki/api/v1/push"
        }
      }
EOF
    microk8s helm3 install alloy grafana/alloy -n monitoring -f monitoring/alloy-values.yaml --set-string 'alloy.nodeSelector.kubernetes\.io/os=linux'
else
    echo "✅ Alloy is already deployed."
fi


echo "⏳ Waiting for monitoring components..."
microk8s kubectl rollout status statefulset/loki -n monitoring --timeout=5m
microk8s kubectl rollout status deployment/grafana -n monitoring --timeout=5m
microk8s kubectl rollout status daemonset/alloy -n monitoring --timeout=5m
echo "✅ Monitoring stack deployed."
echo ""

# --- 5. Build and Deploy Application ---
echo "🐳 Step 5: Building and Deploying the Flask Application..."
echo "Building local Docker image..."
# Point shell to MicroK8s's Docker environment
eval $(microk8s docker-env)
# Build and push to the local registry
docker build -t localhost:32000/flask-k8s-app:latest ./app
docker push localhost:32000/flask-k8s-app:latest
# Unset Docker env
eval $(microk8s docker-env --unset)

echo "Deploying Flask application manifests..."
# We need to update the deployment to use the local registry image
sed -i 's|image: flask-k8s-app:latest|image: localhost:32000/flask-k8s-app:latest|g' k8s/deployment.yaml
microk8s kubectl apply -f k8s/

echo "⏳ Waiting for application deployment..."
microk8s kubectl rollout status deployment/flask-app -n flask-app --timeout=2m
echo "✅ Flask application deployed."
echo ""

# --- 6. Final Configuration and Access Info ---
echo "🌐 Step 6: Final Configuration and Access Information"
echo "❗ IMPORTANT: Add the following lines to your /etc/hosts file to access the services:"
echo "127.0.0.1 jenkins.local"
echo "127.0.0.1 sonarqube.local"
echo "127.0.0.1 grafana.local"
echo "127.0.0.1 flask-app.local"
echo ""

JENKINS_PASS=$(microk8s kubectl exec -n jenkins jenkins-0 -c jenkins -- cat /var/jenkins_home/secrets/initialAdminPassword)

echo "✅ Setup completed successfully!"
echo ""
echo "🔗 Access URLs:"
echo "   - Flask App: http://flask-app.local"
echo "   - Jenkins:   http://jenkins.local"
echo "     (Initial admin password: ${JENKINS_PASS})"
echo "   - SonarQube: http://sonarqube.local (admin/admin)"
echo "   - Grafana:   http://grafana.local (admin/admin123)"
echo ""
echo "🛠️ To start a CI/CD pipeline:"
echo "   1. Configure a new 'Pipeline' job in Jenkins."
echo "   2. Point it to your Git repository."
echo "   3. Set the 'Script Path' to 'jenkins/Jenkinsfile'."
echo ""
