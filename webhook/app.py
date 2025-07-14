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
        
        log_entry = {
            'timestamp': datetime.now(timezone.utc).isoformat(),
            'event_type': event_type,
            'source_ip': source_ip,
            'payload': payload,
            'headers': {k: v for k, v in headers.items() if not k.startswith('X-') or k in ['X-GitHub-Event', 'X-GitLab-Event']},
            'message': f"Git webhook received: {event_type}"
        }
        
        # Determine webhook source and extract relevant data
        if 'github.com' in str(payload):
            log_entry['source'] = 'github'
            if payload.get('repository'):
                log_entry['repository'] = payload['repository'].get('full_name')
            if payload.get('pusher'):
                log_entry['user'] = payload['pusher'].get('name')
        elif 'gitlab' in str(payload):
            log_entry['source'] = 'gitlab'
            if payload.get('project'):
                log_entry['repository'] = payload['project'].get('path_with_namespace')
            if payload.get('user_name'):
                log_entry['user'] = payload.get('user_name')
        else:
            log_entry['source'] = 'unknown'
        
        # Define Loki labels
        labels = {
            'job': 'webhook-receiver',
            'event_type': event_type,
            'source': log_entry.get('source', 'unknown'),
            'level': 'info'
        }
        
        # Send to Loki
        send_to_loki(log_entry, labels)
        
        logger.info(f"Processed webhook: {event_type} from {source_ip}")
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
