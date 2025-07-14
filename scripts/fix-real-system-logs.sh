#!/bin/bash

# REAL System Log Collection Fix Script
# This script fixes Alloy to collect ACTUAL system security logs

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "🔒 REAL System Log Collection Fix"
echo "================================="
echo "Fixing Alloy to collect ACTUAL system security logs!"

# Create the REAL Alloy configuration
create_real_alloy_config() {
    echo "📝 Creating REAL system log collection configuration..."
    
    cat <<EOF > "$PROJECT_ROOT/monitoring/alloy/real-siem-config.alloy"
// REAL System Log Collection for SIEM Dashboard
// This configuration collects ACTUAL system logs from the host

// Real system authentication logs
loki.source.file "real_auth_logs" {
	targets = [
		{__path__ = "/var/log/auth.log", job = "system-auth"},
		{__path__ = "/var/log/sudo.log", job = "system-auth"},
		{__path__ = "/var/log/ssh-failures.log", job = "system-auth"},
		{__path__ = "/var/log/btmp", job = "system-auth"},
	]
	forward_to = [loki.process.real_auth_logs.receiver]
}

// Real package management logs  
loki.source.file "real_package_logs" {
	targets = [
		{__path__ = "/var/log/dpkg.log", job = "package-install"},
		{__path__ = "/var/log/apt/*.log", job = "package-install"},
	]
	forward_to = [loki.process.real_package_logs.receiver]
}

// Real audit logs
loki.source.file "real_audit_logs" {
	targets = [
		{__path__ = "/var/log/audit/*.log", job = "system-audit"},
		{__path__ = "/var/log/audit-k8s.log", job = "kubernetes-audit"},
		{__path__ = "/var/log/audit-forwarded.log", job = "system-audit"},
	]
	forward_to = [loki.process.real_audit_logs.receiver]
}

// Real webhook logs (your actual webhook)
loki.source.file "real_webhook_logs" {
	targets = [
		{__path__ = "/var/log/webhook.log", job = "webhook-receiver"},
		{__path__ = "/var/log/webhook/*.log", job = "webhook-receiver"},
		{__path__ = "/var/log/webhooks/*.log", job = "webhook-receiver"},
	]
	forward_to = [loki.process.real_webhook_logs.receiver]
}

// Process REAL authentication logs
loki.process "real_auth_logs" {
	forward_to = [loki.write.default.receiver]
	
	// Parse auth.log format
	stage.regex {
		expression = "^(?P<timestamp>\\w+\\s+\\d+\\s+\\d+:\\d+:\\d+)\\s+(?P<hostname>\\S+)\\s+(?P<program>\\S+)(\\[(?P<pid>\\d+)\\])?:\\s*(?P<message>.*)"
	}
	
	// Extract SSH invalid user attempts
	stage.match {
		selector = "{job=\"system-auth\"} |~ \"(?i)invalid user\""
		pipeline_name = "ssh_invalid_user"
		
		stage.regex {
			expression = ".*(?i)invalid user\\s+(?P<invalid_user>\\S+)\\s+from\\s+(?P<source_ip>[0-9\\.]+)"
			source = "message"
		}
		
		stage.labels {
			values = {
				event_type = "ssh_invalid_user",
				level = "warning",
				invalid_user = "",
				source_ip = "",
			}
		}
	}
	
	// Extract failed password attempts
	stage.match {
		selector = "{job=\"system-auth\"} |~ \"(?i)failed password\""
		pipeline_name = "failed_password"
		
		stage.regex {
			expression = ".*(?i)failed password for\\s+(?P<failed_user>\\S+)\\s+from\\s+(?P<source_ip>[0-9\\.]+)"
			source = "message"
		}
		
		stage.labels {
			values = {
				event_type = "auth_failure",
				level = "warning",
				failed_user = "",
				source_ip = "",
			}
		}
	}
	
	// Extract successful logins
	stage.match {
		selector = "{job=\"system-auth\"} |~ \"(?i)(session opened|accepted)\""
		pipeline_name = "successful_login"
		
		stage.regex {
			expression = ".*(?i)(session opened for user|accepted.*for)\\s+(?P<user>\\S+)"
			source = "message"
		}
		
		stage.regex {
			expression = ".*from\\s+(?P<source_ip>[0-9\\.]+)"
			source = "message"
		}
		
		stage.labels {
			values = {
				event_type = "successful_login",
				level = "info",
				user = "",
				source_ip = "",
			}
		}
	}
	
	// Extract sudo usage from sudo.log
	stage.match {
		selector = "{job=\"system-auth\"} |~ \"(?i)sudo\""
		pipeline_name = "sudo_usage"
		
		stage.regex {
			expression = ".*sudo:\\s*(?P<sudo_user>\\S+)\\s*:\\s*TTY=(?P<tty>\\S+)\\s*;\\s*PWD=(?P<pwd>\\S+)\\s*;\\s*USER=(?P<target_user>\\S+)\\s*;\\s*COMMAND=(?P<command>.*)"
			source = "message"
		}
		
		stage.labels {
			values = {
				event_type = "sudo_usage",
				level = "info",
				sudo_user = "",
				target_user = "",
				command = "",
				tty = "",
			}
		}
	}
	
	// Default labels for auth logs
	stage.labels {
		values = {
			job = "system-auth",
			hostname = "",
			program = "",
			level = "info",
		}
	}
}

// Process REAL package installation logs
loki.process "real_package_logs" {
	forward_to = [loki.write.default.receiver]
	
	// Parse dpkg.log format
	stage.regex {
		expression = "^(?P<timestamp>\\d{4}-\\d{2}-\\d{2}\\s+\\d{2}:\\d{2}:\\d{2})\\s+(?P<action>\\S+)\\s+(?P<package>\\S+)\\s*(?P<version_info>.*)"
	}
	
	// Extract version information
	stage.regex {
		expression = "(?P<old_version>\\S+)\\s*(?P<new_version>\\S+)?"
		source = "version_info"
	}
	
	stage.labels {
		values = {
			job = "package-install",
			event_type = "package_change",
			action = "",
			package = "",
			old_version = "",
			new_version = "",
			level = "info",
		}
	}
}

// Process REAL audit logs
loki.process "real_audit_logs" {
	forward_to = [loki.write.default.receiver]
	
	// Handle system audit logs
	stage.match {
		selector = "{job=\"system-audit\"}"
		pipeline_name = "system_audit"
		
		stage.regex {
			expression = "^type=(?P<audit_type>\\S+)\\s+msg=audit\\((?P<audit_timestamp>[^)]+)\\):\\s*(?P<audit_message>.*)"
		}
		
		stage.labels {
			values = {
				job = "system-audit",
				audit_type = "",
				level = "info",
			}
		}
	}
	
	// Handle Kubernetes audit logs (JSON format)
	stage.match {
		selector = "{job=\"kubernetes-audit\"}"
		pipeline_name = "k8s_audit"
		
		stage.json {
			expressions = {
				kind = "kind",
				verb = "verb",
				user_username = "user.username",
				resource = "objectRef.resource",
				namespace = "objectRef.namespace",
				response_code = "responseStatus.code",
			}
		}
		
		stage.labels {
			values = {
				job = "kubernetes-audit",
				verb = "",
				resource = "",
				namespace = "",
				level = "info",
			}
		}
	}
}

// Process REAL webhook logs
loki.process "real_webhook_logs" {
	forward_to = [loki.write.default.receiver]
	
	// Try to parse as JSON first (structured logs)
	stage.json {
		expressions = {
			timestamp = "timestamp",
			event_type = "event_type", 
			source = "source",
			repository = "repository",
			actor = "actor",
			level = "level",
			message = "message",
		}
	}
	
	// If not JSON, try to parse plain text format
	stage.regex {
		expression = "^(?P<timestamp>\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}\\.\\d+)\\s*(?P<level>\\w+)?\\s*(?P<message>.*)"
	}
	
	stage.labels {
		values = {
			job = "webhook-receiver",
			event_type = "",
			source = "",
			level = "info",
		}
	}
}

// Send all logs to Loki
loki.write "default" {
	endpoint {
		url = "http://loki.monitoring.svc.cluster.local:3100/loki/api/v1/push"
	}
	
	external_labels = {
		cluster = "real-devsecops",
		environment = "production",
	}
}
EOF
}

# Update Alloy Helm values to use the real configuration
update_alloy_helm_values() {
    echo "📦 Updating Alloy Helm values for REAL log collection..."
    
    cat <<EOF > "$PROJECT_ROOT/helm/alloy/real-values.yaml"
alloy:
  configMap:
    create: true
    content: |
$(cat "$PROJECT_ROOT/monitoring/alloy/real-siem-config.alloy" | sed 's/^/      /')

  # Mount host log directories
  extraVolumes:
    - name: varlog
      hostPath:
        path: /var/log
        type: Directory
    - name: varlibdockercontainers
      hostPath:
        path: /var/lib/docker/containers
        type: DirectoryOrCreate

  extraVolumeMounts:
    - name: varlog
      mountPath: /var/log
      readOnly: true
    - name: varlibdockercontainers
      mountPath: /var/lib/docker/containers
      readOnly: true

  # Run as privileged to access system logs
  securityContext:
    privileged: true
    runAsUser: 0

  # Ensure Alloy runs on all nodes
  tolerations:
    - effect: NoSchedule
      operator: Exists

  # Add required capabilities
  controller:
    type: "daemonset"
    
  extraArgs:
    - --storage.path=/tmp/alloy
    - --server.http.listen-addr=0.0.0.0:12345
    - --cluster.enabled=true
    - --disable-reporting=true
EOF
}

# Apply the configuration
apply_real_config() {
    echo "🚀 Applying REAL system log collection configuration..."
    
    # Upgrade Alloy with real configuration
    microk8s helm3 upgrade alloy grafana/alloy \
        -n monitoring \
        -f "$PROJECT_ROOT/helm/alloy/real-values.yaml" \
        --create-namespace \
        --wait
}

# Restart Alloy to pick up new configuration
restart_alloy() {
    echo "🔄 Restarting Alloy to apply REAL log collection..."
    
    microk8s kubectl rollout restart daemonset/alloy -n monitoring
    microk8s kubectl rollout status daemonset/alloy -n monitoring --timeout=120s
}

# Verify real log collection
verify_real_logs() {
    echo "🔍 Verifying REAL log collection..."
    
    echo "Checking Alloy logs for errors:"
    microk8s kubectl logs -l app.kubernetes.io/name=alloy -n monitoring --tail=20
    
    echo ""
    echo "Testing Loki queries for REAL data:"
    
    # Port forward to Loki
    microk8s kubectl port-forward svc/loki 3100:3100 -n monitoring &
    LOKI_PID=\$!
    sleep 5
    
    echo "Querying for real auth logs:"
    curl -s -G "http://localhost:3100/loki/api/v1/query" \
        --data-urlencode 'query={job="system-auth"}' \
        --data-urlencode 'limit=5' | jq .
    
    echo ""
    echo "Querying for real package logs:"
    curl -s -G "http://localhost:3100/loki/api/v1/query" \
        --data-urlencode 'query={job="package-install"}' \
        --data-urlencode 'limit=5' | jq .
    
    echo ""
    echo "Querying for real webhook logs:"
    curl -s -G "http://localhost:3100/loki/api/v1/query" \
        --data-urlencode 'query={job="webhook-receiver"}' \
        --data-urlencode 'limit=5' | jq .
    
    # Kill port forward
    kill \$LOKI_PID 2>/dev/null || true
}

# Main execution
main() {
    echo "🔥 FIXING REAL SYSTEM LOG COLLECTION!"
    echo "======================================"
    echo "This will configure Alloy to collect ACTUAL system logs:"
    echo "• /var/log/auth.log - SSH attempts, logins"
    echo "• /var/log/sudo.log - Sudo usage"
    echo "• /var/log/ssh-failures.log - SSH failures"
    echo "• /var/log/dpkg.log - Package installations"
    echo "• /var/log/audit/*.log - System audit events"
    echo "• /var/log/webhook.log - Your webhook events"
    echo ""
    
    create_real_alloy_config
    update_alloy_helm_values
    apply_real_config
    restart_alloy
    
    echo "✅ REAL system log collection configured!"
    echo ""
    echo "🔍 Your dashboard should now show REAL data from:"
    echo "   • SSH invalid user attempts from /var/log/auth.log"
    echo "   • Sudo usage from /var/log/sudo.log"
    echo "   • Package installations from /var/log/dpkg.log"
    echo "   • Webhook events from /var/log/webhook.log"
    echo ""
    echo "📊 Check your Grafana dashboard now!"
    echo ""
    echo "To verify logs are being collected:"
    echo "   microk8s kubectl logs -f daemonset/alloy -n monitoring"
    echo ""
    echo "To check what's in Loki:"
    verify_real_logs
}

# Run main function
main
EOF
