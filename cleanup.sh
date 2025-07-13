#!/bin/bash

set -e

echo "🧹 DevSecOps Cleanup Script (MicroK8s installation preserved)"
echo "=============================================================="

# --- Function to remove Jenkins and SonarQube ---
cleanup_core_services() {
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
}

# --- Function to remove Monitoring Stack ---
cleanup_monitoring() {
    echo "❌ Uninstalling Loki..."
    microk8s helm3 uninstall loki -n monitoring || true
    echo "❌ Uninstalling Grafana..."
    microk8s helm3 uninstall grafana -n monitoring || true
    echo "❌ Uninstalling Alloy..."
    microk8s helm3 uninstall alloy -n monitoring || true
    echo "❌ Removing SIEM webhook services..."
    microk8s kubectl delete service alloy-webhook-service -n monitoring || true
    microk8s kubectl delete ingress alloy-webhook-ingress -n monitoring || true
    echo "Deleting Monitoring namespace..."
    microk8s kubectl delete ns monitoring --ignore-not-found
}

# --- Function to remove Application Deployment ---
cleanup_application() {
    echo "❌ Deleting Flask application resources..."
    microk8s kubectl delete -f k8s/ --ignore-not-found
    echo "Reverting image in deployment.yaml..."
    sed -i 's|localhost:32000/flask-k8s-app:latest|flask-k8s-app:latest|g' k8s/deployment.yaml || true

    echo "❌ Removing local Docker images..."
    docker rmi flask-k8s-app:latest localhost:32000/flask-k8s-app:latest || true
}

# --- Function to cleanup SIEM host monitoring ---
cleanup_siem() {
    echo "❌ Removing SIEM monitoring configurations..."
    sudo rm -rf /opt/siem || true
    sudo crontab -l | grep -v "SIEM Security Monitor" | crontab - || true
    echo "❌ Stopping fail2ban..."
    sudo systemctl stop fail2ban || true
    sudo systemctl disable fail2ban || true
    echo "❌ Removing SIEM packages..."
    sudo apt-get remove -y fail2ban logwatch chkrootkit || true
    echo "✅ SIEM cleanup complete."
}
    echo "Removing Jenkins Helm repo..."
    microk8s helm3 repo remove jenkins || true
    echo "Removing SonarQube Helm repo..."
    microk8s helm3 repo remove sonarqube || true
    echo "Removing Grafana Helm repo..."
    microk8s helm3 repo remove grafana || true
    echo "Removing Bitnami Helm repo..."
    microk8s helm3 repo remove bitnami || true
    echo "Removing Aqua Security Helm repo..."
    microk8s helm3 repo remove aquasecurity || true
}

# --- Function to clean up everything ---
cleanup_all() {
    cleanup_core_services
    cleanup_monitoring
    cleanup_application
    cleanup_repos
}

# --- Main Menu ---
while true; do
    echo ""
    echo "Select the cleanup action:"
    echo "  1) Cleanup Core Services (Jenkins, SonarQube)"
    echo "  2) Cleanup Monitoring Stack (Loki, Grafana, Alloy)"
    echo "  3) Cleanup Application Deployment"
    echo "  4) Cleanup SIEM Host Monitoring"
    echo "  5) Cleanup ALL"
    echo "  6) Exit"
    read -p "Enter your choice [1-6]: " choice

    case $choice in
        1)
            cleanup_core_services
            echo "✅ Core services cleanup complete."
            ;;
        2)
            cleanup_monitoring
            echo "✅ Monitoring stack cleanup complete."
            ;;
        3)
            cleanup_application
            echo "✅ Application deployment cleanup complete."
            ;;
        4)
            cleanup_siem
            echo "✅ SIEM host monitoring cleanup complete."
            ;;
        5)
            cleanup_all
            cleanup_siem
            echo "✅ Full cleanup completed! MicroK8s remains installed."
            ;;
        6)
            echo "Exiting cleanup script."
            exit 0
            ;;
        *)
            echo "Invalid option. Please try again."
            ;;
    esac
done