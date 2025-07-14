#!/usr/bin/env python3
"""
Security-focused Webhook Receiver for DevSecOps SIEM
Monitors Git events, code changes, and security-related activities
"""

import json
import logging
import os
import hashlib
import hmac
from datetime import datetime, timezone
from flask import Flask, request, jsonify
import requests

# Configure logging for security monitoring
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s - %(extra)s',
    handlers=[
        logging.FileHandler('/var/log/webhook/security.log'),
        logging.StreamHandler()
    ]
)

logger = logging.getLogger(__name__)

app = Flask(__name__)

# Configuration
SECRET_TOKEN = os.environ.get('WEBHOOK_SECRET', 'default-secret-change-me')
LOKI_URL = os.environ.get('LOKI_URL', 'http://loki.monitoring.svc.cluster.local:3100/loki/api/v1/push')
ENABLE_SIGNATURE_VERIFICATION = os.environ.get('ENABLE_SIGNATURE_VERIFICATION', 'true').lower() == 'true'

class SecurityLogger:
    """Enhanced logging for security events"""
    
    @staticmethod
    def log_security_event(event_type, severity, message, metadata=None):
        """Log security events with structured data"""
        security_data = {
            'timestamp': datetime.now(timezone.utc).isoformat(),
            'event_type': event_type,
            'severity': severity,
            'message': message,
            'source': 'webhook_receiver',
            'metadata': metadata or {}
        }
        
        logger.info(json.dumps(security_data), extra={'security_event': True})
        
        # Send to Loki
        SecurityLogger.send_to_loki(security_data)
    
    @staticmethod
    def send_to_loki(data):
        """Send security events to Loki for centralized monitoring"""
        try:
            loki_payload = {
                "streams": [
                    {
                        "stream": {
                            "job": "webhook-security",
                            "service": "webhook-receiver",
                            "event_type": data.get('event_type', 'unknown'),
                            "severity": data.get('severity', 'info')
                        },
                        "values": [
                            [str(int(datetime.now().timestamp() * 1000000000)), json.dumps(data)]
                        ]
                    }
                ]
            }
            
            response = requests.post(LOKI_URL, json=loki_payload, timeout=5)
            if response.status_code != 204:
                logger.warning(f"Failed to send to Loki: {response.status_code}")
                
        except Exception as e:
            logger.error(f"Error sending to Loki: {str(e)}")

def verify_signature(payload_body, signature_header):
    """Verify webhook signature for security"""
    if not ENABLE_SIGNATURE_VERIFICATION:
        return True
        
    if not signature_header:
        return False
    
    try:
        hash_object = hmac.new(
            SECRET_TOKEN.encode('utf-8'),
            payload_body,
            hashlib.sha256
        )
        expected_signature = f"sha256={hash_object.hexdigest()}"
        return hmac.compare_digest(expected_signature, signature_header)
    except Exception as e:
        logger.error(f"Signature verification error: {str(e)}")
        return False

def analyze_security_risk(event_data):
    """Analyze Git events for security risks"""
    risks = []
    severity = 'info'
    
    if event_data.get('event') == 'push':
        commits = event_data.get('commits', [])
        
        for commit in commits:
            message = commit.get('message', '').lower()
            added_files = commit.get('added', [])
            modified_files = commit.get('modified', [])
            removed_files = commit.get('removed', [])
            
            # Check for security-sensitive patterns in commit messages
            security_keywords = [
                'password', 'secret', 'key', 'token', 'credential',
                'api_key', 'private', 'confidential', 'auth',
                'fix security', 'vulnerability', 'exploit', 'backdoor'
            ]
            
            for keyword in security_keywords:
                if keyword in message:
                    risks.append(f"Security-sensitive keyword '{keyword}' in commit message")
                    severity = 'medium'
            
            # Check for sensitive file patterns
            sensitive_patterns = [
                '.env', '.key', '.pem', '.p12', '.jks', 'id_rsa',
                'config.json', 'secrets.yaml', 'credentials',
                'docker-compose.override.yml'
            ]
            
            all_files = added_files + modified_files
            for file_path in all_files:
                for pattern in sensitive_patterns:
                    if pattern in file_path.lower():
                        risks.append(f"Sensitive file pattern '{pattern}' in {file_path}")
                        severity = 'high'
            
            # Check for large file additions (potential data exfiltration)
            if len(added_files) > 100:
                risks.append(f"Large number of files added: {len(added_files)}")
                severity = 'medium'
                
            # Check for configuration file modifications
            config_patterns = [
                'Dockerfile', 'docker-compose', 'helm/', 'k8s/',
                '.github/workflows', 'Jenkinsfile', 'sonar-project.properties'
            ]
            
            for file_path in modified_files:
                for pattern in config_patterns:
                    if pattern in file_path:
                        risks.append(f"Critical configuration file modified: {file_path}")
                        severity = 'high'
    
    # Check for branch protection bypass
    if event_data.get('event') == 'push':
        ref = event_data.get('ref', '')
        if ref == 'refs/heads/main' or ref == 'refs/heads/master':
            pusher = event_data.get('pusher', {}).get('name', 'unknown')
            risks.append(f"Direct push to main branch by {pusher}")
            severity = 'high'
    
    return risks, severity

def analyze_user_behavior(event_data):
    """Analyze user behavior for anomalies"""
    anomalies = []
    
    if event_data.get('event') == 'push':
        commits = event_data.get('commits', [])
        
        # Check for unusual commit patterns
        if len(commits) > 20:
            anomalies.append(f"Unusually large number of commits: {len(commits)}")
        
        # Check for commits outside business hours (basic check)
        for commit in commits:
            timestamp = commit.get('timestamp')
            if timestamp:
                try:
                    commit_time = datetime.fromisoformat(timestamp.replace('Z', '+00:00'))
                    hour = commit_time.hour
                    if hour < 6 or hour > 22:  # Outside 6 AM - 10 PM
                        anomalies.append(f"Commit outside business hours: {timestamp}")
                except ValueError:
                    pass
    
    return anomalies

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({'status': 'healthy', 'service': 'webhook-security-receiver'})

@app.route('/webhook', methods=['POST'])
def handle_webhook():
    """Main webhook handler with security monitoring"""
    
    # Security logging
    client_ip = request.environ.get('HTTP_X_FORWARDED_FOR', request.remote_addr)
    user_agent = request.headers.get('User-Agent', '')
    
    SecurityLogger.log_security_event(
        'webhook_request',
        'info',
        'Webhook request received',
        {
            'client_ip': client_ip,
            'user_agent': user_agent,
            'content_length': request.content_length,
            'content_type': request.content_type
        }
    )
    
    try:
        # Verify signature
        signature = request.headers.get('X-Hub-Signature-256') or request.headers.get('X-Gitlab-Token')
        payload_body = request.get_data()
        
        if not verify_signature(payload_body, signature):
            SecurityLogger.log_security_event(
                'webhook_auth_failure',
                'high',
                'Webhook signature verification failed',
                {
                    'client_ip': client_ip,
                    'signature_provided': bool(signature),
                    'payload_size': len(payload_body)
                }
            )
            return jsonify({'error': 'Unauthorized'}), 401
        
        # Parse payload
        try:
            event_data = request.get_json()
        except Exception as e:
            SecurityLogger.log_security_event(
                'webhook_parse_error',
                'medium',
                'Failed to parse webhook payload',
                {'error': str(e), 'client_ip': client_ip}
            )
            return jsonify({'error': 'Invalid JSON payload'}), 400
        
        if not event_data:
            return jsonify({'error': 'Empty payload'}), 400
        
        # Determine event type
        event_type = (
            request.headers.get('X-GitHub-Event') or
            request.headers.get('X-GitLab-Event') or
            event_data.get('object_kind') or
            'unknown'
        )
        
        # Analyze security risks
        security_risks, risk_severity = analyze_security_risk(event_data)
        user_anomalies = analyze_user_behavior(event_data)
        
        # Extract metadata
        metadata = {
            'event_type': event_type,
            'repository': event_data.get('repository', {}).get('name', 'unknown'),
            'ref': event_data.get('ref', ''),
            'pusher': event_data.get('pusher', {}).get('name', 'unknown'),
            'commit_count': len(event_data.get('commits', [])),
            'security_risks': security_risks,
            'user_anomalies': user_anomalies,
            'client_ip': client_ip
        }
        
        # Log the processed event
        SecurityLogger.log_security_event(
            'git_event_processed',
            risk_severity,
            f'Git {event_type} event processed',
            metadata
        )
        
        # Log security risks if found
        if security_risks:
            SecurityLogger.log_security_event(
                'security_risk_detected',
                risk_severity,
                f'Security risks detected in Git event: {", ".join(security_risks)}',
                metadata
            )
        
        # Log user behavior anomalies
        if user_anomalies:
            SecurityLogger.log_security_event(
                'user_behavior_anomaly',
                'medium',
                f'User behavior anomalies detected: {", ".join(user_anomalies)}',
                metadata
            )
        
        # Process different event types
        response_data = {
            'status': 'processed',
            'event_type': event_type,
            'security_risks_count': len(security_risks),
            'anomalies_count': len(user_anomalies),
            'risk_level': risk_severity
        }
        
        return jsonify(response_data), 200
        
    except Exception as e:
        SecurityLogger.log_security_event(
            'webhook_processing_error',
            'high',
            'Error processing webhook',
            {
                'error': str(e),
                'client_ip': client_ip,
                'error_type': type(e).__name__
            }
        )
        return jsonify({'error': 'Internal server error'}), 500

@app.route('/metrics', methods=['GET'])
def metrics():
    """Metrics endpoint for monitoring"""
    # This could be extended to provide Prometheus metrics
    return jsonify({
        'service': 'webhook-security-receiver',
        'version': '1.0.0',
        'status': 'running'
    })

@app.errorhandler(404)
def not_found(error):
    SecurityLogger.log_security_event(
        'webhook_404',
        'low',
        'Webhook endpoint not found',
        {
            'path': request.path,
            'client_ip': request.environ.get('HTTP_X_FORWARDED_FOR', request.remote_addr),
            'user_agent': request.headers.get('User-Agent', '')
        }
    )
    return jsonify({'error': 'Endpoint not found'}), 404

@app.errorhandler(500)
def internal_error(error):
    SecurityLogger.log_security_event(
        'webhook_500',
        'high',
        'Internal server error in webhook receiver',
        {
            'error': str(error),
            'client_ip': request.environ.get('HTTP_X_FORWARDED_FOR', request.remote_addr)
        }
    )
    return jsonify({'error': 'Internal server error'}), 500

if __name__ == '__main__':
    # Ensure log directory exists
    os.makedirs('/var/log/webhook', exist_ok=True)
    
    SecurityLogger.log_security_event(
        'webhook_service_start',
        'info',
        'Webhook security receiver service started',
        {
            'version': '1.0.0',
            'signature_verification': ENABLE_SIGNATURE_VERIFICATION,
            'loki_url': LOKI_URL
        }
    )
    
    app.run(host='0.0.0.0', port=5000, debug=False)