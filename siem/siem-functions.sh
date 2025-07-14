#!/bin/bash

# SIEM deployment functions

# Function to deploy security monitoring
deploy_siem() {
    log "🔒 Deploying SIEM and Security Monitoring..." "$BLUE"
    
    # Create config directory if needed
    log "Creating SIEM configuration files..." "$YELLOW"
    microk8s kubectl get ns monitoring >/dev/null 2>&1 || microk8s kubectl create ns monitoring
    
    # Deploy webhook receiver
    log "Deploying webhook receiver..." "$YELLOW"
    
    # Get the external IP
    EXTERNAL_IP=$(curl -s ifconfig.me || curl -s ipinfo.io/ip || curl -s icanhazip.com)
    
    # Update the webhook hostname in the manifest
    sed "s/webhook\.EXTERNAL_IP\.nip\.io/webhook\.$EXTERNAL_IP\.nip\.io/g" siem/configs/webhook-receiver.yaml | microk8s kubectl apply -f -
    
    log "✅ Webhook receiver deployed." "$GREEN"
    
    # Create ConfigMap for Alloy security config
    log "Creating Alloy security configuration..." "$YELLOW"
    microk8s kubectl create configmap alloy-security-config -n monitoring --from-file=config.river=siem/configs/alloy-security-config.river -o yaml --dry-run=client | microk8s kubectl apply -f -
    
    # Update Alloy deployment to use the security configuration
    log "Updating Alloy configuration to collect security logs..." "$YELLOW"
    
    # Check if we're using the Helm deployment or direct kubectl
    if microk8s helm3 status alloy -n monitoring &> /dev/null; then
        log "Updating Alloy Helm deployment..." "$YELLOW"
        
        # Create custom values file for security monitoring
        cat > /tmp/alloy-siem-values.yaml << EOF
alloy:
  configMap:
    name: alloy-security-config
    content: null
  extraVolumeMounts:
    - name: varlog
      mountPath: /var/log
    - name: varlibdockercontainers
      mountPath: /var/lib/docker/containers
    - name: audit-logs
      mountPath: /var/log/audit
  extraVolumes:
    - name: varlog
      hostPath:
        path: /var/log
    - name: varlibdockercontainers
      hostPath:
        path: /var/lib/docker/containers
    - name: audit-logs
      hostPath:
        path: /var/log/audit
        type: DirectoryOrCreate
EOF
        
        # Upgrade Alloy with new values
        microk8s helm3 upgrade alloy grafana/alloy -n monitoring -f /tmp/alloy-siem-values.yaml
    else
        # Direct kubectl update
        log "Updating Alloy DaemonSet directly..." "$YELLOW"
        
        # Patch the DaemonSet to mount host logs and use the security config
        microk8s kubectl patch daemonset alloy -n monitoring --patch '
        {
            "spec": {
                "template": {
                    "spec": {
                        "volumes": [
                            {
                                "name": "config",
                                "configMap": {
                                    "name": "alloy-security-config"
                                }
                            },
                            {
                                "name": "varlog",
                                "hostPath": {
                                    "path": "/var/log"
                                }
                            },
                            {
                                "name": "varlibdockercontainers",
                                "hostPath": {
                                    "path": "/var/lib/docker/containers"
                                }
                            },
                            {
                                "name": "audit-logs",
                                "hostPath": {
                                    "path": "/var/log/audit",
                                    "type": "DirectoryOrCreate"
                                }
                            }
                        ],
                        "containers": [
                            {
                                "name": "alloy",
                                "volumeMounts": [
                                    {
                                        "name": "config",
                                        "mountPath": "/etc/alloy"
                                    },
                                    {
                                        "name": "varlog",
                                        "mountPath": "/var/log"
                                    },
                                    {
                                        "name": "varlibdockercontainers",
                                        "mountPath": "/var/lib/docker/containers"
                                    },
                                    {
                                        "name": "audit-logs",
                                        "mountPath": "/var/log/audit"
                                    }
                                ]
                            }
                        ]
                    }
                }
            }
        }'
    fi
    
    # Deploy Grafana Dashboard for SIEM
    log "Deploying SIEM dashboards to Grafana..." "$YELLOW"
    
    # Create ConfigMap for the dashboard
    microk8s kubectl create configmap siem-dashboard -n monitoring --from-file=siem-dashboard.json=siem/dashboards/siem-dashboard.json -o yaml --dry-run=client | microk8s kubectl apply -f -
    
    # Create ConfigMap for alert rules
    microk8s kubectl create configmap siem-alerts -n monitoring --from-file=alert-rules.json=siem/dashboards/alert-rules.json -o yaml --dry-run=client | microk8s kubectl apply -f -
    
    # Annotate ConfigMap for Grafana to pick it up
    microk8s kubectl annotate configmap siem-dashboard -n monitoring grafana_dashboard=1 --overwrite
    
    log "✅ SIEM dashboards deployed." "$GREEN"
    
    # Configure host system security tools
    log "🛡️ Setting up host-level security tools..." "$BLUE"
    
    # Install security tools if they don't exist
    if ! command -v auditd &> /dev/null || ! command -v fail2ban-client &> /dev/null; then
        log "Installing security monitoring tools..." "$YELLOW"
        sudo apt-get update
        sudo apt-get install -y auditd audispd-plugins rsyslog fail2ban
    fi
    
    # Configure auditd
    log "Configuring auditd..." "$YELLOW"
    sudo cp -f siem/configs/auditd-config.yaml /etc/audit/rules.d/audit.rules
    
    # Configure rsyslog
    log "Configuring rsyslog..." "$YELLOW"
    sudo cp -f siem/configs/rsyslog-config.yaml /etc/rsyslog.d/99-siem.conf
    
    # Configure fail2ban
    log "Configuring fail2ban..." "$YELLOW"
    sudo cp -f siem/configs/fail2ban-config.yaml /etc/fail2ban/jail.local
    
    # Restart services
    log "Restarting security services..." "$YELLOW"
    sudo systemctl restart auditd
    sudo systemctl restart rsyslog
    sudo systemctl restart fail2ban
    
    log "✅ Host security tools configured." "$GREEN"
    
    # Configure Kubernetes audit logging if MicroK8s is used
    if command -v microk8s &> /dev/null; then
        log "Configuring Kubernetes audit logging..." "$YELLOW"
        
        # Create audit policy directory
        sudo mkdir -p /var/snap/microk8s/current/audit
        
        # Copy audit policy
        sudo cp -f siem/configs/k8s-audit-policy.yaml /var/snap/microk8s/current/audit/audit-policy.yaml
        
        # Update kube-apiserver arguments
        sudo microk8s.stop
        
        # Add audit logging parameters
        sudo sed -i '/^CERT_ARGS/ a AUDIT_ARGS="--audit-log-path=/var/snap/microk8s/current/audit/audit.log --audit-log-maxage=30 --audit-log-maxbackup=10 --audit-log-maxsize=100 --audit-policy-file=/var/snap/microk8s/current/audit/audit-policy.yaml"' /var/snap/microk8s/current/args/kube-apiserver
        
        # Add audit parameters to kube-apiserver command
        sudo sed -i 's/^\(.*\)\"${CERT_ARGS}\"/\1\"${CERT_ARGS}\" \"${AUDIT_ARGS}\"/' /var/snap/microk8s/current/args/kube-apiserver
        
        sudo microk8s.start
        
        log "✅ Kubernetes audit logging configured." "$GREEN"
    fi
    
    log "⏳ Waiting for SIEM components..." "$YELLOW"
    microk8s kubectl rollout status daemonset/alloy -n monitoring --timeout=2m || true
    microk8s kubectl rollout status deployment/webhook-receiver -n monitoring --timeout=2m || true
    
    log "✅ SIEM deployment completed!" "$GREEN"
    log "🔗 Security Information and Event Monitoring Access:" "$CYAN"
    log "   - SIEM Dashboard: http://grafana.$EXTERNAL_IP.nip.io" "$CYAN"
    log "   - Webhook URL: http://webhook.$EXTERNAL_IP.nip.io/webhook" "$CYAN"
    log "   - Configure GitHub/GitLab webhooks to point to the webhook URL" "$CYAN"
}

# Function to clean up SIEM resources
cleanup_siem() {
    log "🧹 Cleaning up SIEM components..." "$BLUE"
    
    # Remove webhook receiver
    log "Removing webhook receiver..." "$YELLOW"
    microk8s kubectl delete -f siem/configs/webhook-receiver.yaml --ignore-not-found
    
    # Remove ConfigMaps
    log "Removing SIEM ConfigMaps..." "$YELLOW"
    microk8s kubectl delete configmap -n monitoring alloy-security-config siem-dashboard siem-alerts --ignore-not-found
    
    # Reset Alloy to default configuration
    if microk8s helm3 status alloy -n monitoring &> /dev/null; then
        log "Resetting Alloy to default configuration..." "$YELLOW"
        microk8s helm3 upgrade alloy grafana/alloy -n monitoring -f helm/alloy/values.yaml
    fi
    
    # Remove Kubernetes audit logging if enabled
    if [ -f /var/snap/microk8s/current/audit/audit-policy.yaml ]; then
        log "Removing Kubernetes audit logging configuration..." "$YELLOW"
        sudo microk8s.stop
        sudo sed -i '/AUDIT_ARGS=/d' /var/snap/microk8s/current/args/kube-apiserver
        sudo sed -i 's/\"${CERT_ARGS}\" \"${AUDIT_ARGS}\"/\"${CERT_ARGS}\"/' /var/snap/microk8s/current/args/kube-apiserver
        sudo microk8s.start
        
        # Remove audit directory
        sudo rm -rf /var/snap/microk8s/current/audit
    fi
    
    log "✅ SIEM cleanup completed!" "$GREEN"
}
