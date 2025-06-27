#!/bin/bash

set -e

echo "🔧 Fixing Jenkins Docker Access Issue..."
echo "======================================="

# Get the Docker group ID from the host
DOCKER_GID=$(getent group docker | cut -d: -f3 || echo 999)
echo "Host Docker group ID: ${DOCKER_GID}"

# First, let's try a quick restart approach
echo "Attempting quick restart of Jenkins pod..."
microk8s kubectl delete pod -l app.kubernetes.io/component=jenkins-controller -n jenkins || true

# Wait for pod to restart
echo "Waiting for Jenkins to restart..."
sleep 30
microk8s kubectl rollout status statefulset/jenkins -n jenkins --timeout=5m

# Test Docker access
JENKINS_POD=$(microk8s kubectl get pods -n jenkins -l app.kubernetes.io/component=jenkins-controller -o jsonpath='{.items[0].metadata.name}')
echo "Testing Docker access in pod: $JENKINS_POD"

if microk8s kubectl exec -n jenkins $JENKINS_POD -- docker version > /dev/null 2>&1; then
    echo "✅ Docker access is working! Quick fix successful."
    exit 0
fi

echo "Quick fix didn't work. Performing full rebuild..."

# Stop existing Jenkins
echo "Stopping existing Jenkins deployment..."
microk8s helm3 uninstall jenkins -n jenkins || true

# Wait for pods to terminate
echo "Waiting for Jenkins pods to terminate..."
sleep 30

# Rebuild Jenkins image with correct Docker GID
echo "Rebuilding Jenkins image with Docker GID: ${DOCKER_GID}..."
cd jenkins
docker build --build-arg DOCKER_GID=${DOCKER_GID} -t jenkins-devsecops:latest .
docker tag jenkins-devsecops:latest localhost:32000/jenkins-devsecops:latest
docker push localhost:32000/jenkins-devsecops:latest
cd ..

# Redeploy Jenkins
echo "Redeploying Jenkins with updated configuration..."
microk8s helm3 install jenkins jenkins/jenkins -n jenkins -f helm/jenkins/values.yaml

# Wait for Jenkins to be ready
echo "Waiting for Jenkins to be ready..."
microk8s kubectl rollout status statefulset/jenkins -n jenkins --timeout=5m

# Get Jenkins admin password
echo "Retrieving Jenkins admin password..."
JENKINS_PASS=$(microk8s kubectl get secret jenkins -n jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode)

echo "✅ Jenkins Docker access fix completed!"
echo ""
echo "🔗 Access Jenkins at: http://jenkins.local"
echo "   Username: admin"
echo "   Password: ${JENKINS_PASS}"
echo ""
echo "🧪 Test Docker access by running a simple pipeline with:"
echo "   stage('Test Docker') {"
echo "     steps {"
echo "       sh 'docker version'"
echo "       sh 'docker info'"
echo "     }"
echo "   }"
