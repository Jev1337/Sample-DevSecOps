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
    
    # Check if we need to adjust the ingress class name
    INGRESS_CLASS="public"
    if ! microk8s kubectl get ingressclass public &>/dev/null; then
        if microk8s kubectl get ingressclass nginx &>/dev/null; then
            INGRESS_CLASS="nginx"
            log "Using 'nginx' ingress class..." "$YELLOW"
        else
            # Find any available ingress class
            AVAILABLE_CLASS=$(microk8s kubectl get ingressclass -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
            if [ -n "$AVAILABLE_CLASS" ]; then
                INGRESS_CLASS="$AVAILABLE_CLASS"
                log "Using '$AVAILABLE_CLASS' ingress class..." "$YELLOW"
            else
                log "⚠️ No ingress class found. Using default 'public'..." "$YELLOW"
            fi
        fi
    fi
    
    # Update both the webhook hostname and ingress class in the manifest
    cat siem/configs/webhook-receiver.yaml | \
        sed "s/webhook\.EXTERNAL_IP\.nip\.io/webhook\.$EXTERNAL_IP\.nip\.io/g" | \
        sed "s/ingressClassName: public/ingressClassName: $INGRESS_CLASS/g" | \
        microk8s kubectl apply -f -
    
    log "✅ Webhook receiver deployed with hostname: webhook.$EXTERNAL_IP.nip.io" "$GREEN"
    
    # Update Alloy deployment to use the security configuration
    log "Updating Alloy configuration to collect security logs..." "$YELLOW"
    
    # Check if we're using the Helm deployment or direct kubectl
    if microk8s helm3 status alloy -n monitoring &> /dev/null; then
        log "Updating Alloy Helm deployment..." "$YELLOW"
        
        # For Helm deployments, we'll include the config directly in the values file
        # to avoid conflicts with manually created ConfigMaps
        
        # First, read the security configuration
        SECURITY_CONFIG=$(cat siem/configs/alloy-security-config.river)
        
        # Create custom values file for security monitoring with inline config
        cat > /tmp/alloy-siem-values.yaml << EOF
alloy:
  configMap:
    create: true
    content: |
$(echo "$SECURITY_CONFIG" | sed 's/^/      /')
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
        if ! microk8s helm3 upgrade alloy grafana/alloy -n monitoring -f /tmp/alloy-siem-values.yaml; then
            log "⚠️ Helm upgrade failed. Attempting alternative approach..." "$YELLOW"
            
            # If Helm upgrade fails due to ConfigMap conflicts, try removing the ConfigMap first
            log "Removing existing ConfigMap..." "$YELLOW"
            microk8s kubectl delete configmap -n monitoring alloy-security-config --ignore-not-found
            
            # Retry the Helm upgrade
            log "Retrying Helm upgrade..." "$YELLOW"
            microk8s helm3 upgrade alloy grafana/alloy -n monitoring -f /tmp/alloy-siem-values.yaml
        fi
    else
        # For direct kubectl deployments, create the ConfigMap manually
        log "Creating Alloy security configuration..." "$YELLOW"
        microk8s kubectl create configmap alloy-security-config -n monitoring --from-file=config.river=siem/configs/alloy-security-config.river -o yaml --dry-run=client | microk8s kubectl apply -f -
        
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
    
    # Check if dashboard files exist
    if [ ! -f "siem/dashboards/siem-dashboard.json" ] || [ ! -f "siem/dashboards/alert-rules.json" ]; then
        log "⚠️ Dashboard files not found. Creating from defaults..." "$YELLOW"
        
        # Ensure directories exist
        mkdir -p siem/dashboards
        
        # If dashboard file doesn't exist, copy from what we've created previously
        if [ ! -f "siem/dashboards/siem-dashboard.json" ]; then
            cp /tmp/siem-dashboard.json siem/dashboards/siem-dashboard.json 2>/dev/null || \
            echo '{"annotations":{"list":[]},"title":"SIEM Dashboard","uid":"siem-dashboard"}' > siem/dashboards/siem-dashboard.json
        fi
        
        # If alert rules file doesn't exist, create a minimal one
        if [ ! -f "siem/dashboards/alert-rules.json" ]; then
            cp /tmp/alert-rules.json siem/dashboards/alert-rules.json 2>/dev/null || \
            echo '{"apiVersion":1,"groups":[{"name":"Security Alerts","folder":"SIEM","rules":[]}]}' > siem/dashboards/alert-rules.json
        fi
    fi
    
    # Create ConfigMap for the dashboard with error handling
    if ! microk8s kubectl create configmap siem-dashboard -n monitoring --from-file=siem-dashboard.json=siem/dashboards/siem-dashboard.json -o yaml --dry-run=client | microk8s kubectl apply -f -; then
        log "⚠️ Failed to create dashboard ConfigMap. Trying alternative method..." "$YELLOW"
        # Try direct create instead of apply
        microk8s kubectl create configmap siem-dashboard -n monitoring --from-file=siem-dashboard.json=siem/dashboards/siem-dashboard.json || true
    fi
    
    # Create ConfigMap for alert rules with error handling
    if ! microk8s kubectl create configmap siem-alerts -n monitoring --from-file=alert-rules.json=siem/dashboards/alert-rules.json -o yaml --dry-run=client | microk8s kubectl apply -f -; then
        log "⚠️ Failed to create alerts ConfigMap. Trying alternative method..." "$YELLOW"
        # Try direct create instead of apply
        microk8s kubectl create configmap siem-alerts -n monitoring --from-file=alert-rules.json=siem/dashboards/alert-rules.json || true
    fi
    
    # Annotate ConfigMap for Grafana to pick it up
    microk8s kubectl annotate configmap siem-dashboard -n monitoring grafana_dashboard=1 --overwrite || true
    
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
        if ! sudo mkdir -p /var/snap/microk8s/current/audit 2>/dev/null; then
            log "⚠️ Unable to create audit directory. May need to run with elevated permissions." "$YELLOW"
            log "Trying alternative approach..." "$YELLOW"
            
            # Alternative: Use the /tmp directory for audit policy
            sudo mkdir -p /tmp/microk8s-audit
            sudo cp -f siem/configs/k8s-audit-policy.yaml /tmp/microk8s-audit/audit-policy.yaml
            
            # Update kube-apiserver arguments with tmp path
            sudo microk8s.stop
            sudo sed -i '/^CERT_ARGS/ a AUDIT_ARGS="--audit-log-path=/tmp/microk8s-audit/audit.log --audit-log-maxage=30 --audit-log-maxbackup=10 --audit-log-maxsize=100 --audit-policy-file=/tmp/microk8s-audit/audit-policy.yaml"' /var/snap/microk8s/current/args/kube-apiserver
            sudo sed -i 's/^\(.*\)\"${CERT_ARGS}\"/\1\"${CERT_ARGS}\" \"${AUDIT_ARGS}\"/' /var/snap/microk8s/current/args/kube-apiserver
            sudo microk8s.start
            
            log "✅ Kubernetes audit logging configured with alternative path." "$GREEN"
        else
            # Standard path configuration
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
    
    # Remove ConfigMaps that are not managed by Helm
    log "Removing SIEM ConfigMaps..." "$YELLOW"
    microk8s kubectl delete configmap -n monitoring siem-dashboard siem-alerts --ignore-not-found
    
    # Reset Alloy to default configuration
    if microk8s helm3 status alloy -n monitoring &> /dev/null; then
        log "Resetting Alloy to default configuration..." "$YELLOW"
        
        # Check if the original values file exists
        if [ -f "helm/alloy/values.yaml" ]; then
            microk8s helm3 upgrade alloy grafana/alloy -n monitoring -f helm/alloy/values.yaml
        else
            # If original values file doesn't exist, use minimal default values
            cat > /tmp/alloy-default-values.yaml << EOF
alloy:
  configMap:
    create: true
    content: |
      discovery.kubernetes "pods" {
        role = "pod"
      }
      
      discovery.relabel "kubernetes_pods" {
        targets = discovery.kubernetes.pods.targets
        rule {
          source_labels = ["__meta_kubernetes_pod_phase"]
          regex = "Pending|Succeeded|Failed|Completed"
          action = "drop"
        }
        rule {
          source_labels = ["__meta_kubernetes_pod_container_name"]
          regex = ""
          action = "drop"
        }
        rule {
          source_labels = ["__meta_kubernetes_pod_name"]
          target_label = "pod"
        }
        rule {
          source_labels = ["__meta_kubernetes_namespace"]
          target_label = "namespace"
        }
        rule {
          source_labels = ["__meta_kubernetes_pod_container_name"]
          target_label = "container"
        }
      }
      
      loki.source.kubernetes "pods" {
        targets    = discovery.relabel.kubernetes_pods.output
        forward_to = [loki.write.default.receiver]
      }
      
      loki.write "default" {
        endpoint {
          url = "http://loki.monitoring.svc.cluster.local:3100/loki/api/v1/push"
        }
      }
EOF
            microk8s helm3 upgrade alloy grafana/alloy -n monitoring -f /tmp/alloy-default-values.yaml
        fi
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
