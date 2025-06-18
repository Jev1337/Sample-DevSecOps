#!/bin/bash

set -e

echo "🚀 Flask K8s DevSecOps Setup Script"
echo "===================================="

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

check_command() {
    if ! command -v $1 &> /dev/null; then
        echo "❌ $1 is not installed. Please install it first."
        exit 1
    else
        echo "✅ $1 is available"
    fi
}

echo "📝 Checking prerequisites..."
check_command docker
check_command kubectl
check_command helm
check_command minikube

echo ""
echo "🔧 Setting up minikube..."
if minikube status &> /dev/null; then
    echo "✅ minikube is already running"
else
    echo "🚀 Starting minikube..."
    minikube start --memory=6144 --cpus=4 --disk-size=20g --driver=docker
fi

echo ""
echo "🔌 Enabling minikube addons..."
minikube addons enable ingress
minikube addons enable metrics-server
minikube addons enable dashboard

echo ""
echo "🐳 Building Docker image..."
eval $(minikube docker-env)
docker build -t flask-k8s-app:latest ./app

echo ""
echo "📦 Creating Kubernetes namespaces..."
kubectl apply -f k8s/namespace.yaml
kubectl apply -f monitoring/alloy/alloy-config.yaml | grep "namespace/monitoring"

echo ""
echo "🚀 Deploying Flask application..."
kubectl apply -f k8s/

echo "⏳ Waiting for application deployment..."
kubectl rollout status deployment/flask-app -n flask-app --timeout=300s

echo ""
echo "📊 Deploying monitoring stack..."
echo "Deploying Loki..."
kubectl apply -f monitoring/loki/loki-config.yaml

echo "Deploying Grafana..."
kubectl apply -f monitoring/grafana/grafana-config.yaml
kubectl apply -f monitoring/grafana/dashboards-configmap.yaml

echo "Deploying Alloy..."
kubectl apply -f monitoring/alloy/alloy-config.yaml

echo "⏳ Waiting for monitoring components..."
kubectl rollout status deployment/loki -n monitoring --timeout=300s
kubectl rollout status deployment/grafana -n monitoring --timeout=300s

echo ""
echo "🌐 Setting up ingress..."
kubectl get ingress -n flask-app

echo ""
echo "🔍 Adding hosts entries..."
MINIKUBE_IP=$(minikube ip)
echo "Add these entries to your /etc/hosts file:"
echo "$MINIKUBE_IP flask-app.local"
echo "$MINIKUBE_IP grafana.local"

echo ""
echo "🧪 Running smoke tests..."
kubectl port-forward service/flask-app-service 8080:80 -n flask-app &
PF_PID=$!
sleep 10

if curl -f http://localhost:8080/health > /dev/null 2>&1; then
    echo "✅ Health check passed"
else
    echo "❌ Health check failed"
fi

if curl -f http://localhost:8080/api/users > /dev/null 2>&1; then
    echo "✅ API test passed"
else
    echo "❌ API test failed"
fi

kill $PF_PID 2>/dev/null || true

echo ""
echo "📈 Getting service URLs..."
GRAFANA_PORT=$(kubectl get service grafana -n monitoring -o jsonpath='{.spec.ports[0].nodePort}')
FLASK_APP_URL="http://flask-app.local"
GRAFANA_URL="http://$MINIKUBE_IP:$GRAFANA_PORT"

echo ""
echo "✅ Setup completed successfully!"
echo ""
echo "🌐 Access URLs:"
echo "   Flask App: $FLASK_APP_URL"
echo "   Grafana:   $GRAFANA_URL (admin/admin123)"
echo ""
echo "📊 Useful commands:"
echo "   View pods:           kubectl get pods -A"
echo "   View services:       kubectl get services -A"
echo "   View logs:           kubectl logs -f deployment/flask-app -n flask-app"
echo "   Grafana port-forward: kubectl port-forward service/grafana 3000:3000 -n monitoring"
echo "   Minikube dashboard:   minikube dashboard"
echo ""
echo "🔧 Troubleshooting:"
echo "   Check pod status:    kubectl describe pod <pod-name> -n <namespace>"
echo "   Check events:        kubectl get events -n <namespace> --sort-by='.lastTimestamp'"
echo "   Restart minikube:    minikube delete && minikube start"
echo ""
echo "🎉 Your Flask K8s DevSecOps environment is ready!"
