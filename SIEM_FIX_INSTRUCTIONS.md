# SIEM Dashboard Data Issues - Solutions

## Problem Summary

Your SIEM dashboard is showing "No data" for several panels because:

1. **Missing System Logs**: The dashboard expects logs from `/var/log/auth.log`, `/var/log/dpkg.log`, etc., but these may not exist or have the expected format.
2. **GitHub Webhook Data Loss**: The webhook receives events but doesn't extract meaningful details from the payload.
3. **Log Source Mismatch**: Alloy configuration looks for logs that don't exist in your environment.

## Solutions Implemented

### 1. Sample Data Generator

Created `scripts/generate-siem-sample-data.py` that generates realistic security events:
- SSH invalid user attempts
- Sudo usage logs
- Package installation events  
- Successful login attempts

### 2. Enhanced GitHub Webhook Handler

Updated `webhook/app.py` to extract detailed information from GitHub events:
- Repository information
- Actor/user details
- Event-specific data (PR actions, issue actions, workflow status)
- Security-relevant flags

### 3. Fixed Dashboard Queries

Updated Grafana dashboard queries to be more flexible and handle missing data gracefully.

### 4. Deployment Script

Created `scripts/deploy-siem-sample-generator.sh` to easily deploy the sample data generator.

## How to Fix Your Dashboard

### Step 1: Deploy the Sample Data Generator

```bash
# Make the script executable
chmod +x scripts/deploy-siem-sample-generator.sh

# Deploy the generator
./scripts/deploy-siem-sample-generator.sh
```

This will:
- Create a Kubernetes deployment that generates sample security events
- Send data directly to Loki with proper labels
- Start generating events immediately

### Step 2: Update the Webhook Service

Redeploy your webhook service with the enhanced handler:

```bash
# Rebuild and redeploy the webhook container
cd webhook
docker build -t webhook-receiver:enhanced .

# If using Kubernetes, update the deployment
kubectl set image deployment/webhook-receiver webhook=webhook-receiver:enhanced -n monitoring
```

### Step 3: Update the Grafana Dashboard

The dashboard queries have been updated in the file. Import the updated dashboard or restart Grafana to pick up changes:

```bash
# Restart Grafana to reload the dashboard
kubectl rollout restart deployment/grafana -n monitoring
```

### Step 4: Verify Data Flow

1. **Check Sample Data Generator Logs**:
```bash
kubectl logs -f deployment/siem-sample-data-generator -n monitoring
```

2. **Check Webhook Logs**:
```bash
kubectl logs -f deployment/webhook-receiver -n monitoring
```

3. **Query Loki Directly**:
```bash
# Access Loki and run test queries
curl -G -s "http://localhost:3100/loki/api/v1/query" --data-urlencode 'query={job="system-auth"}'
```

### Step 5: Test GitHub Webhooks

1. Go to your GitHub repository settings
2. Create a test webhook pointing to your webhook endpoint
3. Trigger some events (push code, create issues, etc.)
4. Check the webhook logs and Grafana dashboard

## Expected Results

After implementing these fixes, you should see:

1. **SSH Invalid User Attempts**: Regular simulated attack attempts
2. **Sudo Usage Activity**: Simulated admin command execution
3. **Package Installation Activity**: Simulated software changes
4. **User Activity Summary**: Aggregated user actions
5. **GitHub Webhook Events**: Detailed information about repository events including:
   - Repository names
   - User/actor information
   - Event-specific details (PR actions, issue status, etc.)
   - Workflow execution status

## Troubleshooting

### If you still see "No data":

1. **Check Loki Connection**:
```bash
kubectl port-forward svc/loki 3100:3100 -n monitoring
curl http://localhost:3100/ready
```

2. **Check Alloy Logs**:
```bash
kubectl logs -l app.kubernetes.io/name=alloy -n monitoring
```

3. **Verify Label Matching**:
   - The dashboard queries look for specific job labels
   - Make sure your data has the right labels: `job="system-auth"`, `job="webhook-receiver"`, etc.

4. **Check Time Range**:
   - The dashboard shows data from the last hour by default
   - Make sure your sample data generator has been running long enough

### If GitHub webhooks still show minimal data:

1. **Check webhook payload structure**:
   - Add logging to see what GitHub is actually sending
   - Verify the webhook is configured for the right events

2. **Test with curl**:
```bash
curl -X POST http://your-webhook-endpoint/webhook \
  -H "Content-Type: application/json" \
  -H "X-GitHub-Event: push" \
  -d '{"repository":{"full_name":"test/repo"},"sender":{"login":"testuser"}}'
```

The fixes should resolve your data visibility issues and provide meaningful security monitoring data in your SIEM dashboard.
