# Azure External Access Configuration Script (PowerShell)
# This script configures your DevSecOps stack for external access on Azure

Write-Host "🌐 Configuring External Access for Azure Instance" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green

# Get the external IP of the Azure VM
Write-Host "🔍 Detecting Azure VM external IP..." -ForegroundColor Yellow
try {
    $EXTERNAL_IP = (Invoke-RestMethod -Uri "https://ipinfo.io/ip" -TimeoutSec 10).Trim()
    Write-Host "✅ External IP detected: $EXTERNAL_IP" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to detect external IP. Please set it manually." -ForegroundColor Red
    $EXTERNAL_IP = Read-Host "Enter your Azure VM's external IP address"
}

# --- Azure NSG Configuration Instructions ---
Write-Host ""
Write-Host "🛡️ AZURE NETWORK SECURITY GROUP CONFIGURATION" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Please ensure your Azure VM's Network Security Group allows the following inbound rules:" -ForegroundColor Yellow
Write-Host "1. HTTP (Port 80) - Source: Any - Destination: Any" -ForegroundColor White
Write-Host "2. HTTPS (Port 443) - Source: Any - Destination: Any" -ForegroundColor White
Write-Host "3. Jenkins (Port 8080) - Source: Any - Destination: Any" -ForegroundColor White
Write-Host "4. SonarQube (Port 9000) - Source: Any - Destination: Any" -ForegroundColor White
Write-Host "5. Grafana (Port 3000) - Source: Any - Destination: Any" -ForegroundColor White
Write-Host "6. Flask App (Port 5000) - Source: Any - Destination: Any" -ForegroundColor White
Write-Host ""

# --- Option 1: NodePort Services ---
Write-Host "📋 Option 1: Creating NodePort Services for Direct Access" -ForegroundColor Cyan

$nodePortServices = @"
# Jenkins NodePort Service
apiVersion: v1
kind: Service
metadata:
  name: jenkins-nodeport
  namespace: jenkins
spec:
  type: NodePort
  ports:
  - port: 8080
    targetPort: 8080
    nodePort: 30080
    name: http
  selector:
    app.kubernetes.io/component: jenkins-controller
    app.kubernetes.io/instance: jenkins
---
# SonarQube NodePort Service
apiVersion: v1
kind: Service
metadata:
  name: sonarqube-nodeport
  namespace: sonarqube
spec:
  type: NodePort
  ports:
  - port: 9000
    targetPort: 9000
    nodePort: 30090
    name: http
  selector:
    app: sonarqube
---
# Grafana NodePort Service
apiVersion: v1
kind: Service
metadata:
  name: grafana-nodeport
  namespace: monitoring
spec:
  type: NodePort
  ports:
  - port: 3000
    targetPort: 3000
    nodePort: 30030
    name: http
  selector:
    app.kubernetes.io/name: grafana
---
# Flask App NodePort Service
apiVersion: v1
kind: Service
metadata:
  name: flask-app-nodeport
  namespace: flask-app
spec:
  type: NodePort
  ports:
  - port: 5000
    targetPort: 5000
    nodePort: 30050
    name: http
  selector:
    app: flask-app
"@

$nodePortServices | microk8s kubectl apply -f -

Write-Host "✅ NodePort services created" -ForegroundColor Green
Write-Host ""

# --- Display Access Information ---
Write-Host ""
Write-Host "🌐 EXTERNAL ACCESS INFORMATION" -ForegroundColor Green
Write-Host "=============================" -ForegroundColor Green
Write-Host ""
Write-Host "🔗 Access your services via these URLs:" -ForegroundColor Yellow
Write-Host ""
Write-Host "📊 **Direct IP Access (NodePort):**" -ForegroundColor Cyan
Write-Host "   - Jenkins:   http://${EXTERNAL_IP}:30080" -ForegroundColor White
Write-Host "   - SonarQube: http://${EXTERNAL_IP}:30090" -ForegroundColor White
Write-Host "   - Grafana:   http://${EXTERNAL_IP}:30030" -ForegroundColor White
Write-Host "   - Flask App: http://${EXTERNAL_IP}:30050" -ForegroundColor White
Write-Host ""

# --- Alternative: Using nip.io ---
Write-Host "🌐 **Alternative: Using nip.io (if you set up ingress):**" -ForegroundColor Cyan
Write-Host "   - Jenkins:   http://jenkins.${EXTERNAL_IP}.nip.io" -ForegroundColor White
Write-Host "   - SonarQube: http://sonarqube.${EXTERNAL_IP}.nip.io" -ForegroundColor White
Write-Host "   - Grafana:   http://grafana.${EXTERNAL_IP}.nip.io" -ForegroundColor White
Write-Host "   - Flask App: http://app.${EXTERNAL_IP}.nip.io" -ForegroundColor White
Write-Host ""

# --- Security and Access Information ---
Write-Host "🛡️ **Security & Access Information:**" -ForegroundColor Red
Write-Host "   - Ensure Azure NSG allows inbound traffic on the ports listed above" -ForegroundColor Yellow
Write-Host "   - Consider setting up SSL/TLS certificates for production use" -ForegroundColor Yellow
Write-Host "   - Default credentials:" -ForegroundColor Yellow
Write-Host "     • Jenkins: admin / (run setup script to get password)" -ForegroundColor White
Write-Host "     • SonarQube: admin / admin" -ForegroundColor White
Write-Host "     • Grafana: admin / admin123" -ForegroundColor White
Write-Host ""

# --- Azure CLI Commands for NSG ---
Write-Host "🔧 **Azure CLI Commands to Configure NSG (run in Azure Cloud Shell or with Azure CLI):**" -ForegroundColor Cyan
Write-Host ""
Write-Host "# Get your resource group and NSG name first:" -ForegroundColor Gray
Write-Host "az vm show --name YOUR_VM_NAME --resource-group YOUR_RESOURCE_GROUP --query 'networkProfile.networkInterfaces[0].id' -o tsv | xargs az network nic show --ids | Select networkSecurityGroup" -ForegroundColor Gray
Write-Host ""
Write-Host "# Then add the security rules:" -ForegroundColor Gray
Write-Host "az network nsg rule create --resource-group YOUR_RESOURCE_GROUP --nsg-name YOUR_NSG_NAME --name AllowJenkins --protocol Tcp --priority 1001 --destination-port-range 30080 --access Allow" -ForegroundColor Gray
Write-Host "az network nsg rule create --resource-group YOUR_RESOURCE_GROUP --nsg-name YOUR_NSG_NAME --name AllowSonarQube --protocol Tcp --priority 1002 --destination-port-range 30090 --access Allow" -ForegroundColor Gray
Write-Host "az network nsg rule create --resource-group YOUR_RESOURCE_GROUP --nsg-name YOUR_NSG_NAME --name AllowGrafana --protocol Tcp --priority 1003 --destination-port-range 30030 --access Allow" -ForegroundColor Gray
Write-Host "az network nsg rule create --resource-group YOUR_RESOURCE_GROUP --nsg-name YOUR_NSG_NAME --name AllowFlaskApp --protocol Tcp --priority 1004 --destination-port-range 30050 --access Allow" -ForegroundColor Gray
Write-Host "az network nsg rule create --resource-group YOUR_RESOURCE_GROUP --nsg-name YOUR_NSG_NAME --name AllowHTTP --protocol Tcp --priority 1005 --destination-port-range 80 --access Allow" -ForegroundColor Gray
Write-Host ""

Write-Host "✅ External access configuration completed!" -ForegroundColor Green
Write-Host ""
Write-Host "🚀 **Next Steps:**" -ForegroundColor Yellow
Write-Host "1. Configure Azure NSG rules as shown above" -ForegroundColor White
Write-Host "2. Test access to your services using the URLs provided" -ForegroundColor White
Write-Host "3. Set up SSL certificates for production use" -ForegroundColor White
Write-Host "4. Consider using Azure Application Gateway for advanced load balancing" -ForegroundColor White
