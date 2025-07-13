# Debug script to check Loki logs and Grafana data
Write-Host "=== Loki Debug Check ===" -ForegroundColor Yellow

# Check if Loki is running
Write-Host "1. Checking Loki pod status..." -ForegroundColor Cyan
microk8s kubectl get pods -n monitoring | Select-String "loki"

# Check Loki logs
Write-Host "`n2. Checking Loki logs..." -ForegroundColor Cyan
microk8s kubectl logs -n monitoring deployment/loki --tail=20

# Check if Grafana is running
Write-Host "`n3. Checking Grafana pod status..." -ForegroundColor Cyan
microk8s kubectl get pods -n monitoring | Select-String "grafana"

# Check Grafana logs
Write-Host "`n4. Checking Grafana logs..." -ForegroundColor Cyan
microk8s kubectl logs -n monitoring deployment/grafana --tail=20

# Check if ConfigMaps exist for dashboards
Write-Host "`n5. Checking dashboard ConfigMaps..." -ForegroundColor Cyan
microk8s kubectl get configmaps -n monitoring | Select-String "dashboard"

# Check Alloy status
Write-Host "`n6. Checking Alloy pod status..." -ForegroundColor Cyan
microk8s kubectl get pods -n monitoring | Select-String "alloy"

# Check Alloy logs
Write-Host "`n7. Checking Alloy logs..." -ForegroundColor Cyan
microk8s kubectl logs -n monitoring deployment/alloy --tail=20

# Try to query Loki directly
Write-Host "`n8. Testing Loki query API..." -ForegroundColor Cyan
try {
    $lokiPod = (microk8s kubectl get pods -n monitoring -l app.kubernetes.io/name=loki -o jsonpath='{.items[0].metadata.name}')
    if ($lokiPod) {
        Write-Host "Found Loki pod: $lokiPod" -ForegroundColor Green
        
        # Start port forwarding in background
        $job = Start-Job -ScriptBlock {
            param($pod)
            microk8s kubectl port-forward -n monitoring pod/$pod 3100:3100
        } -ArgumentList $lokiPod
        
        Start-Sleep -Seconds 3
        
        Write-Host "Querying Loki for labels..." -ForegroundColor Cyan
        try {
            $response = Invoke-RestMethod -Uri "http://localhost:3100/loki/api/v1/labels" -TimeoutSec 5
            $response | ConvertTo-Json -Depth 3
        } catch {
            Write-Host "Could not query Loki labels: $_" -ForegroundColor Red
        }
        
        Write-Host "Querying for any logs in last hour..." -ForegroundColor Cyan
        $query = [System.Web.HttpUtility]::UrlEncode('{job=~".*"}')
        $start = [DateTimeOffset]::Now.AddHours(-1).ToUnixTimeMilliseconds() * 1000000
        $end = [DateTimeOffset]::Now.ToUnixTimeMilliseconds() * 1000000
        
        try {
            $logResponse = Invoke-RestMethod -Uri "http://localhost:3100/loki/api/v1/query_range?query=$query&start=$start&end=$end" -TimeoutSec 10
            $logResponse | ConvertTo-Json -Depth 3
        } catch {
            Write-Host "Could not query Loki logs: $_" -ForegroundColor Red
        }
        
        # Stop port forwarding
        Stop-Job $job -Force
        Remove-Job $job -Force
    } else {
        Write-Host "No Loki pod found" -ForegroundColor Red
    }
} catch {
    Write-Host "Error testing Loki: $_" -ForegroundColor Red
}

Write-Host "`n=== Debug Check Complete ===" -ForegroundColor Yellow
