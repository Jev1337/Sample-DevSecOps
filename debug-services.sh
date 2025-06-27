#!/bin/bash

echo "🔍 Debugging Service Connectivity Issues"
echo "========================================"

echo ""
echo "📋 Checking Services and Endpoints:"
echo "-----------------------------------"
echo "Flask App services:"
microk8s kubectl get svc -n flask-app
echo ""
echo "SonarQube services:"
microk8s kubectl get svc -n sonarqube
echo ""

echo "📋 Checking Endpoints:"
echo "----------------------"
echo "Flask App endpoints:"
microk8s kubectl get endpoints -n flask-app
echo ""
echo "SonarQube endpoints:"
microk8s kubectl get endpoints -n sonarqube
echo ""

echo "📋 Checking Ingress:"
echo "--------------------"
microk8s kubectl get ingress -A
echo ""

echo "📋 Checking Pod Status:"
echo "-----------------------"
echo "Flask App pods:"
microk8s kubectl get pods -n flask-app -o wide
echo ""
echo "SonarQube pods:"
microk8s kubectl get pods -n sonarqube -o wide
echo ""

echo "📋 Ingress Controller Status:"
echo "-----------------------------"
microk8s kubectl get pods -n ingress -o wide
echo ""

echo "📋 Suggested fixes:"
echo "1. Verify service names match in ingress backend"
echo "2. Check if pods are actually ready and responding"
echo "3. Verify ingress controller is running properly"
echo "4. Test service connectivity with: kubectl port-forward"
