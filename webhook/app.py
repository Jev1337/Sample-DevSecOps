from flask import Flask, request, jsonify
import json
import logging
import requests
from datetime import datetime, timezone
import os

app = Flask(__name__)

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Loki endpoint configuration
LOKI_URL = os.getenv('LOKI_URL', 'http://loki.monitoring.svc.cluster.local:3100/loki/api/v1/push')

def send_to_loki(log_entry, labels):
    """Send log entry to Loki"""
    try:
        timestamp_ns = str(int(datetime.now(timezone.utc).timestamp() * 1000000000))
        
        loki_payload = {
            "streams": [
                {
                    "stream": labels,
                    "values": [
                        [timestamp_ns, json.dumps(log_entry)]
                    ]
                }
            ]
        }
        
        response = requests.post(LOKI_URL, json=loki_payload, timeout=5)
        response.raise_for_status()
        logger.info(f"Successfully sent log to Loki: {response.status_code}")
        
    except Exception as e:
        logger.error(f"Failed to send log to Loki: {e}")

@app.route('/webhook', methods=['POST'])
def git_webhook():
    """Handle Git webhook events"""
    try:
        payload = request.get_json()
        headers = dict(request.headers)
        
        # Extract common webhook information
        event_type = headers.get('X-GitHub-Event', headers.get('X-GitLab-Event', 'unknown'))
        source_ip = request.environ.get('HTTP_X_FORWARDED_FOR', request.environ.get('REMOTE_ADDR'))
        
        # Base log entry
        log_entry = {
            'timestamp': datetime.now(timezone.utc).isoformat(),
            'event_type': event_type,
            'source_ip': source_ip,
            'source': 'unknown',
            'level': 'info',
            'message': f"Git webhook received: {event_type}"
        }
        
        # Extract GitHub-specific data
        if 'github.com' in str(payload) or event_type in ['push', 'pull_request', 'issues', 'create', 'delete']:
            log_entry['source'] = 'github'
            
            # Extract repository information
            if payload.get('repository'):
                repo = payload['repository']
                log_entry['repository'] = repo.get('full_name', 'unknown')
                log_entry['repository_url'] = repo.get('html_url', '')
                log_entry['repository_private'] = repo.get('private', False)
            
            # Extract user/actor information
            if payload.get('sender'):
                sender = payload['sender']
                log_entry['actor'] = sender.get('login', 'unknown')
                log_entry['actor_id'] = sender.get('id', 0)
                log_entry['actor_type'] = sender.get('type', 'User')
            
            # Extract specific event details
            if event_type == 'push':
                log_entry['ref'] = payload.get('ref', '')
                log_entry['commits_count'] = len(payload.get('commits', []))
                if payload.get('commits'):
                    log_entry['commit_messages'] = [commit.get('message', '') for commit in payload['commits'][:3]]
                log_entry['forced'] = payload.get('forced', False)
                
            elif event_type == 'pull_request':
                pr = payload.get('pull_request', {})
                log_entry['pr_action'] = payload.get('action', '')
                log_entry['pr_number'] = pr.get('number', 0)
                log_entry['pr_title'] = pr.get('title', '')
                log_entry['pr_state'] = pr.get('state', '')
                log_entry['pr_mergeable'] = pr.get('mergeable', None)
                
            elif event_type == 'issues':
                issue = payload.get('issue', {})
                log_entry['issue_action'] = payload.get('action', '')
                log_entry['issue_number'] = issue.get('number', 0)
                log_entry['issue_title'] = issue.get('title', '')
                log_entry['issue_state'] = issue.get('state', '')
                
            elif event_type == 'create':
                log_entry['ref_type'] = payload.get('ref_type', '')
                log_entry['ref'] = payload.get('ref', '')
                
            elif event_type == 'delete':
                log_entry['ref_type'] = payload.get('ref_type', '')
                log_entry['ref'] = payload.get('ref', '')
                
            elif event_type == 'release':
                release = payload.get('release', {})
                log_entry['release_action'] = payload.get('action', '')
                log_entry['release_tag'] = release.get('tag_name', '')
                log_entry['release_name'] = release.get('name', '')
                log_entry['release_prerelease'] = release.get('prerelease', False)
                
            elif event_type == 'workflow_run':
                workflow_run = payload.get('workflow_run', {})
                log_entry['workflow_action'] = payload.get('action', '')
                log_entry['workflow_name'] = workflow_run.get('name', '')
                log_entry['workflow_status'] = workflow_run.get('status', '')
                log_entry['workflow_conclusion'] = workflow_run.get('conclusion', '')
                log_entry['workflow_branch'] = workflow_run.get('head_branch', '')
                
        elif 'gitlab' in str(payload):
            log_entry['source'] = 'gitlab'
            if payload.get('project'):
                log_entry['repository'] = payload['project'].get('path_with_namespace')
            if payload.get('user_name'):
                log_entry['actor'] = payload.get('user_name')
        else:
            log_entry['source'] = 'unknown'
            log_entry['raw_payload_keys'] = list(payload.keys()) if payload else []
        
        # Determine security level
        if event_type in ['delete', 'force_push'] or log_entry.get('forced', False):
            log_entry['level'] = 'warning'
        elif event_type in ['workflow_run'] and log_entry.get('workflow_conclusion') == 'failure':
            log_entry['level'] = 'warning'
        
        # Define Loki labels
        labels = {
            'job': 'webhook-receiver',
            'event_type': event_type,
            'source': log_entry.get('source', 'unknown'),
            'level': log_entry.get('level', 'info')
        }
        
        # Add additional labels for filtering
        if log_entry.get('repository'):
            labels['repository'] = log_entry['repository']
        if log_entry.get('actor'):
            labels['actor'] = log_entry['actor']
        
        # Send to Loki
        send_to_loki(log_entry, labels)
        
        logger.info(f"Processed {event_type} webhook from {log_entry.get('source')} - Repository: {log_entry.get('repository', 'N/A')}, Actor: {log_entry.get('actor', 'N/A')}")
        return jsonify({'status': 'success', 'message': 'Webhook processed'}), 200
        
    except Exception as e:
        error_log = {
            'timestamp': datetime.now(timezone.utc).isoformat(),
            'level': 'error',
            'message': f"Error processing webhook: {str(e)}",
            'source_ip': request.environ.get('HTTP_X_FORWARDED_FOR', request.environ.get('REMOTE_ADDR'))
        }
        
        labels = {
            'job': 'webhook-receiver',
            'level': 'error'
        }
        
        send_to_loki(error_log, labels)
        logger.error(f"Webhook processing error: {e}")
        return jsonify({'status': 'error', 'message': str(e)}), 500

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({'status': 'healthy'}), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=False)
