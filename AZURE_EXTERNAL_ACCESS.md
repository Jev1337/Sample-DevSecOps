# Azure External Access Guide

This guide explains how to expose your DevSecOps stack (Jenkins, SonarQube, Grafana, Flask App) externally on an Azure VM.

## 🎯 Overview

Your current setup uses `.local` domains which only work locally. To access these services from anywhere on the internet, you need to:

1. **Configure Azure Network Security Group (NSG)**
2. **Expose services via NodePort or LoadBalancer**
3. **Optionally set up proper DNS/domain names**

## 🛡️ Step 1: Configure Azure Network Security Group

### Via Azure Portal:
1. Go to Azure Portal → Your VM → Networking
2. Click "Add inbound port rule"
3. Add these rules:

| Name | Port | Protocol | Source | Priority |
|------|------|----------|---------|----------|
| AllowHTTP | 80 | TCP | Any | 1000 |
| AllowHTTPS | 443 | TCP | Any | 1001 |
| AllowJenkins | 30080 | TCP | Any | 1002 |
| AllowSonarQube | 30090 | TCP | Any | 1003 |
| AllowGrafana | 30030 | TCP | Any | 1004 |
| AllowFlaskApp | 30050 | TCP | Any | 1005 |

### Via Azure CLI:
```bash
# Replace YOUR_RESOURCE_GROUP and YOUR_NSG_NAME with your actual values
RESOURCE_GROUP="YOUR_RESOURCE_GROUP"
NSG_NAME="YOUR_NSG_NAME"

az network nsg rule create --resource-group $RESOURCE_GROUP --nsg-name $NSG_NAME --name AllowJenkins --protocol Tcp --priority 1002 --destination-port-range 30080 --access Allow
az network nsg rule create --resource-group $RESOURCE_GROUP --nsg-name $NSG_NAME --name AllowSonarQube --protocol Tcp --priority 1003 --destination-port-range 30090 --access Allow
az network nsg rule create --resource-group $RESOURCE_GROUP --nsg-name $NSG_NAME --name AllowGrafana --protocol Tcp --priority 1004 --destination-port-range 30030 --access Allow
az network nsg rule create --resource-group $RESOURCE_GROUP --nsg-name $NSG_NAME --name AllowFlaskApp --protocol Tcp --priority 1005 --destination-port-range 30050 --access Allow
az network nsg rule create --resource-group $RESOURCE_GROUP --nsg-name $NSG_NAME --name AllowHTTP --protocol Tcp --priority 1006 --destination-port-range 80 --access Allow
```

## 🚀 Step 2: Run the External Access Configuration

### Option A: Bash Script (Linux/WSL)
```bash
chmod +x azure-external-access.sh
./azure-external-access.sh
```

### Option B: PowerShell Script (Windows)
```powershell
.\azure-external-access.ps1
```

## 🌐 Step 3: Access Your Services

After running the configuration script, you can access your services via:

### Direct IP Access (NodePort):
- **Jenkins**: `http://YOUR_VM_IP:30080`
- **SonarQube**: `http://YOUR_VM_IP:30090`
- **Grafana**: `http://YOUR_VM_IP:30030`
- **Flask App**: `http://YOUR_VM_IP:30050`

### Using nip.io (Wildcard DNS):
- **Jenkins**: `http://jenkins.YOUR_VM_IP.nip.io`
- **SonarQube**: `http://sonarqube.YOUR_VM_IP.nip.io`
- **Grafana**: `http://grafana.YOUR_VM_IP.nip.io`
- **Flask App**: `http://app.YOUR_VM_IP.nip.io`

## 🔐 Default Credentials

| Service | Username | Password |
|---------|----------|----------|
| Jenkins | admin | (Run setup script to get password) |
| SonarQube | admin | admin |
| Grafana | admin | admin123 |

## 🔧 Advanced Options

### Option 1: Azure Application Gateway
For production environments, consider using Azure Application Gateway:
- SSL termination
- Web Application Firewall (WAF)
- Advanced routing
- Better performance

### Option 2: Azure Load Balancer
For high availability:
```bash
# This creates Azure Load Balancer services
kubectl patch svc jenkins -n jenkins -p '{"spec":{"type":"LoadBalancer"}}'
kubectl patch svc sonarqube -n sonarqube -p '{"spec":{"type":"LoadBalancer"}}'
```

### Option 3: Custom Domain with DNS
1. Purchase a domain (e.g., from Azure DNS, GoDaddy, etc.)
2. Create DNS A records pointing to your Azure VM IP
3. Update ingress configurations to use your domain
4. Set up SSL certificates (Let's Encrypt recommended)

## 📊 Monitoring External Access

### Check service status:
```bash
# Check NodePort services
microk8s kubectl get svc -A --field-selector spec.type=NodePort

# Check ingress
microk8s kubectl get ingress -A

# Check pods
microk8s kubectl get pods -A
```

### View logs:
```bash
# Jenkins logs
microk8s kubectl logs -n jenkins -l app.kubernetes.io/component=jenkins-controller

# SonarQube logs
microk8s kubectl logs -n sonarqube -l app=sonarqube
```

## 🛡️ Security Best Practices

1. **Change Default Passwords**: Update all default passwords immediately
2. **Enable HTTPS**: Set up SSL certificates for production
3. **Network Segmentation**: Limit access to specific IP ranges if possible
4. **Regular Updates**: Keep all services updated
5. **Backup Strategy**: Implement regular backups
6. **Monitoring**: Set up proper monitoring and alerting

## 🆘 Troubleshooting

### Service not accessible:
1. Check Azure NSG rules
2. Verify service is running: `microk8s kubectl get pods -A`
3. Check service endpoints: `microk8s kubectl get svc -A`
4. Test locally first: `curl http://localhost:30080` (for Jenkins)

### DNS not resolving:
1. Try direct IP access first
2. Check if nip.io is accessible: `nslookup jenkins.YOUR_IP.nip.io`
3. Consider using /etc/hosts or custom DNS

### Permission issues:
1. Check pod security contexts
2. Verify persistent volume permissions
3. Review service account permissions

## 📝 Notes

- **nip.io** is a free wildcard DNS service that automatically resolves to the IP in the domain name
- **NodePort** exposes services on high ports (30000-32767) on all cluster nodes
- **LoadBalancer** creates an Azure Load Balancer (requires Azure integration)
- For production, always use HTTPS and proper domain names
