#!/bin/bash

set -e

echo "🧹 DevSecOps Cleanup Script (MicroK8s installation preserved)"
echo "=============================================================="

# --- 1. Remove Jenkins and SonarQube ---
echo "❌ Uninstalling Jenkins..."
microk8s helm3 uninstall jenkins -n jenkins || true
echo "Deleting Jenkins namespace..."
microk8s kubectl delete ns jenkins --ignore-not-found

echo "❌ Uninstalling SonarQube..."
microk8s helm3 uninstall sonarqube -n sonarqube || true
echo "❌ Uninstalling PostgreSQL..."
microk8s helm3 uninstall postgresql -n sonarqube || true
echo "Deleting SonarQube PVCs..."
microk8s kubectl delete pvc -n sonarqube --all || true
echo "Deleting SonarQube namespace..."
microk8s kubectl delete ns sonarqube --ignore-not-found

# --- 2. Remove Monitoring Stack ---
echo "❌ Uninstalling Loki..."
microk8s helm3 uninstall loki -n monitoring || true
echo "❌ Uninstalling Grafana..."
microk8s helm3 uninstall grafana -n monitoring || true
echo "❌ Uninstalling Alloy..."
microk8s helm3 uninstall alloy -n monitoring || true
echo "Deleting Monitoring namespace..."
microk8s kubectl delete ns monitoring --ignore-not-found

# --- 3. Remove Application Deployment ---
echo "❌ Deleting Flask application resources..."
microk8s kubectl delete -f k8s/ --ignore-not-found
echo "Reverting image in deployment.yaml..."
sed -i 's|localhost:32000/flask-k8s-app:latest|flask-k8s-app:latest|g' k8s/deployment.yaml || true

echo "❌ Removing local Docker images..."
docker rmi flask-k8s-app:latest localhost:32000/flask-k8s-app:latest || true

# --- 4. Remove Helm Repositories ---
echo "Removing Jenkins Helm repo..."
microk8s helm3 repo remove jenkins || true
echo "Removing SonarQube Helm repo..."
microk8s helm3 repo remove sonarqube || true
echo "Removing Grafana Helm repo..."
microk8s helm3 repo remove grafana || true
echo "Removing Bitnami Helm repo..."
microk8s helm3 repo remove bitnami || true

echo "✅ Cleanup completed! MicroK8s remains installed."
