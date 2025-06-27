#!/bin/bash

# Azure External Access Configuration Script
# This script configures your DevSecOps stack for external access on Azure

set -e

echo "🌐 Configuring External Access for Azure Instance"
echo "================================================"

# Get the external IP of the Azure VM
echo "🔍 Detecting Azure VM external IP..."
EXTERNAL_IP=$(curl -s ifconfig.me || curl -s ipinfo.io/ip || curl -s icanhazip.com)
echo "✅ External IP detected: $EXTERNAL_IP"

# --- Option 1: LoadBalancer Services ---
echo ""
echo "📋 Option 1: Creating LoadBalancer Services"
echo "This will expose services directly on Azure Load Balancer"

# Create LoadBalancer service for Jenkins
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

# Create LoadBalancer service for SonarQube
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

# Create LoadBalancer service for Grafana
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

# Create LoadBalancer service for Flask App
cat <<EOF | microk8s kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: flask-app-loadbalancer
  namespace: flask-app
spec:
  type: LoadBalancer
  ports:
  - port: 5000
    targetPort: 5000
    name: http
  selector:
    app: flask-app
EOF

echo "✅ LoadBalancer services created"
echo ""

# --- Option 2: Ingress with External IP ---
echo "📋 Option 2: Updating Ingress for External Access"

# Update Jenkins ingress
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

# Update SonarQube ingress
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
            name: sonarqube
            port:
              number: 9000
EOF

# Update Grafana ingress
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
              number: 3000
EOF

# Update Flask App ingress
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
            name: flask-app
            port:
              number: 5000
EOF

echo "✅ External ingress configurations created"
echo ""

# Wait for services to be ready
echo "⏳ Waiting for services to get external IPs..."
sleep 30

# Display access information
echo ""
echo "🌐 EXTERNAL ACCESS INFORMATION"
echo "============================="
echo ""
echo "🔗 Access your services via these URLs:"
echo ""
echo "📊 **Using nip.io domains (recommended):**"
echo "   - Jenkins:   http://jenkins.${EXTERNAL_IP}.nip.io"
echo "   - SonarQube: http://sonarqube.${EXTERNAL_IP}.nip.io"
echo "   - Grafana:   http://grafana.${EXTERNAL_IP}.nip.io"
echo "   - Flask App: http://app.${EXTERNAL_IP}.nip.io"
echo ""
echo "🌐 **Using LoadBalancer IPs (check table below):**"
echo "   - Access services directly via their assigned external IPs"
echo ""

# Check LoadBalancer external IPs
echo "📋 **LoadBalancer External IPs:**"
microk8s kubectl get svc -A -o wide | grep LoadBalancer

echo ""
echo "🛡️ **Security Notes:**"
echo "   - Ensure Azure NSG allows inbound traffic on ports 80, 443, 8080, 9000, 3000, 5000"
echo "   - Consider setting up SSL/TLS certificates for production use"
echo "   - Default credentials:"
echo "     • Jenkins: admin / (check output above for password)"
echo "     • SonarQube: admin / admin"
echo "     • Grafana: admin / admin123"
echo ""
echo "✅ External access configuration completed!"
EOF

echo "✅ External ingress configurations created"
echo ""

# Wait for services to be ready
echo "⏳ Waiting for services to get external IPs..."
sleep 30

# Display access information
echo ""
echo "🌐 EXTERNAL ACCESS INFORMATION"
echo "============================="
echo ""
echo "🔗 Access your services via these URLs:"
echo ""
echo "📊 **Using nip.io domains (recommended):**"
echo "   - Jenkins:   http://jenkins.${EXTERNAL_IP}.nip.io"
echo "   - SonarQube: http://sonarqube.${EXTERNAL_IP}.nip.io"
echo "   - Grafana:   http://grafana.${EXTERNAL_IP}.nip.io"
echo "   - Flask App: http://app.${EXTERNAL_IP}.nip.io"
echo ""
echo "🌐 **Using direct IP with paths:**"
echo "   - Jenkins:   http://${EXTERNAL_IP}/jenkins"
echo "   - SonarQube: http://${EXTERNAL_IP}/sonarqube"
echo "   - Grafana:   http://${EXTERNAL_IP}/grafana"
echo "   - Flask App: http://${EXTERNAL_IP}/app"
echo ""

# Check LoadBalancer external IPs
echo "📋 **LoadBalancer External IPs:**"
microk8s kubectl get svc -A --field-selector spec.type=LoadBalancer

echo ""
echo "🛡️ **Security Notes:**"
echo "   - Ensure Azure NSG allows inbound traffic on ports 80, 443, 8080, 9000, 3000, 5000"
echo "   - Consider setting up SSL/TLS certificates for production use"
echo "   - Default credentials:"
echo "     • Jenkins: admin / (check output above for password)"
echo "     • SonarQube: admin / admin"
echo "     • Grafana: admin / admin123"
echo ""
echo "✅ External access configuration completed!"
