from flask import Flask, jsonify, request, render_template_string
import logging
import json
import os
import time
from datetime import datetime
import uuid
from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST
from werkzeug.exceptions import HTTPException

app = Flask(__name__)

logging.basicConfig(
    level=logging.INFO,
    format='%(message)s'
)

logger = logging.getLogger(__name__)

REQUEST_COUNT = Counter('flask_requests_total', 'Total Flask requests', ['method', 'endpoint', 'status'])
REQUEST_LATENCY = Histogram('flask_request_duration_seconds', 'Flask request latency', ['method', 'endpoint'])

users_db = [
    {"id": 1, "name": "Alice Johnson", "email": "alice@example.com", "role": "admin"},
    {"id": 2, "name": "Bob Smith", "email": "bob@example.com", "role": "user"},
    {"id": 3, "name": "Charlie Brown", "email": "charlie@example.com", "role": "user"}
]

def log_structured(level, message, **kwargs):
    log_entry = {
        "timestamp": datetime.utcnow().isoformat(),
        "level": level,
        "message": message,
        "request_id": getattr(request, 'request_id', str(uuid.uuid4())),
        "service": "flask-app",
        "version": "1.0.0",
        **kwargs
    }
    logger.info(json.dumps(log_entry))

@app.before_request
def before_request():
    request.start_time = time.time()
    request.request_id = str(uuid.uuid4())
    log_structured("INFO", "Request started", 
                   method=request.method, 
                   path=request.path, 
                   user_agent=request.headers.get('User-Agent'))

@app.after_request
def after_request(response):
    request_latency = time.time() - request.start_time
    REQUEST_COUNT.labels(method=request.method, endpoint=request.endpoint, status=response.status_code).inc()
    REQUEST_LATENCY.labels(method=request.method, endpoint=request.endpoint).observe(request_latency)
    
    log_structured("INFO", "Request completed",
                   method=request.method,
                   path=request.path,
                   status_code=response.status_code,
                   response_time=round(request_latency * 1000, 2))
    return response

@app.errorhandler(Exception)
def handle_exception(e):
    if isinstance(e, HTTPException):
        log_structured("WARNING", "HTTP error", 
                       error_code=e.code, 
                       error_message=str(e))
        return jsonify({"error": str(e), "code": e.code}), e.code
    
    log_structured("ERROR", "Unexpected error", 
                   error_type=type(e).__name__, 
                   error_message=str(e))
    return jsonify({"error": "Internal server error", "code": 500}), 500

@app.route('/')
def home():
    log_structured("INFO", "Home page accessed")
    return render_template_string('''
    <!DOCTYPE html>
    <html>
    <head>
        <title>Flask K8s DevSecOps Demo</title>
        <style>
            body { font-family: Arial, sans-serif; margin: 40px; background-color: #f5f5f5; }
            .container { max-width: 800px; margin: 0 auto; background: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
            h1 { color: #333; text-align: center; }
            .api-section { margin: 20px 0; padding: 20px; background-color: #f8f9fa; border-radius: 5px; }
            .endpoint { margin: 10px 0; padding: 10px; background-color: #e9ecef; border-radius: 3px; }
            .method { font-weight: bold; color: #007bff; }
            ul { margin: 10px 0; }
            li { margin: 5px 0; }
            .status { color: #28a745; font-weight: bold; }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>🚀 Flask K8s DevSecOps Demo</h1>
            <h2> Version 1.0.1</h2>
            <p class="status">✅ Application is running successfully!</p>
            
            <div class="api-section">
                <h2>📡 Available API Endpoints</h2>
                
                <div class="endpoint">
                    <span class="method">GET</span> <code>/health</code>
                    <p>Health check endpoint for Kubernetes probes</p>
                </div>
                
                <div class="endpoint">
                    <span class="method">GET</span> <code>/api/users</code>
                    <p>Get all users</p>
                </div>
                
                <div class="endpoint">
                    <span class="method">GET</span> <code>/api/users/{id}</code>
                    <p>Get user by ID</p>
                </div>
                
                <div class="endpoint">
                    <span class="method">POST</span> <code>/api/users</code>
                    <p>Create a new user</p>
                </div>
                
                <div class="endpoint">
                    <span class="method">GET</span> <code>/metrics</code>
                    <p>Prometheus metrics endpoint</p>
                </div>
                                  
                <div class="endpoint">
                    <span class="method">GET</span> <code>/api/unauthorized</code>
                    <p>Simulate unauthorized access</p>
                </div>
            </div>
            
            <div class="api-section">
                <h2>🔧 Technical Features</h2>
                <ul>
                    <li>Structured JSON logging</li>
                    <li>Prometheus metrics integration</li>
                    <li>Kubernetes health checks</li>
                    <li>Request tracing with unique IDs</li>
                    <li>Error handling and monitoring</li>
                    <li>Security headers</li>
                </ul>
            </div>
        </div>
    </body>
    </html>
    ''')

@app.route('/health')
def health():
    health_status = {
        "status": "healthy",
        "timestamp": datetime.utcnow().isoformat(),
        "version": "1.0.0",
        "service": "flask-app"
    }
    log_structured("INFO", "Health check performed", status="healthy")
    return jsonify(health_status)

@app.route('/api/users', methods=['GET'])
def get_users():
    log_structured("INFO", "Users list requested", count=len(users_db))
    return jsonify({"users": users_db, "count": len(users_db)})

@app.route('/api/users/<int:user_id>', methods=['GET'])
def get_user(user_id):
    user = next((u for u in users_db if u["id"] == user_id), None)
    if user:
        log_structured("INFO", "User retrieved", user_id=user_id)
        return jsonify(user)
    else:
        log_structured("WARNING", "User not found", user_id=user_id)
        return jsonify({"error": "User not found"}), 404

@app.route('/api/users', methods=['POST'])
def create_user():
    data = request.get_json()
    if not data or not all(key in data for key in ['name', 'email']):
        log_structured("WARNING", "Invalid user data", data=data)
        return jsonify({"error": "Missing required fields: name, email"}), 400
    
    new_user = {
        "id": len(users_db) + 1,
        "name": data["name"],
        "email": data["email"],
        "role": data.get("role", "user")
    }
    users_db.append(new_user)
    log_structured("INFO", "User created", user_id=new_user["id"], email=new_user["email"])
    return jsonify(new_user), 201

@app.route('/metrics')
def metrics():
    return generate_latest(), 200, {'Content-Type': CONTENT_TYPE_LATEST}

@app.route('/api/simulate-error')
def simulate_error():
    log_structured("WARNING", "Simulated error endpoint accessed")
    return jsonify({"error": "This is a simulated error for testing"}), 500

@app.route('/api/simulate-slow')
def simulate_slow():
    time.sleep(2)
    log_structured("INFO", "Slow endpoint accessed", duration=2)
    return jsonify({"message": "This endpoint simulates slow response"})

@app.route('/api/unauthorized')
def unauthorized_access():
    log_structured("WARNING", "Unauthorized access attempt")
    return jsonify({"error": "Unauthorized access"}), 401

if __name__ == '__main__':
    log_structured("INFO", "Flask application starting", 
                   port=int(os.environ.get('PORT', 5000)))
    app.run(host='0.0.0.0', port=int(os.environ.get('PORT', 5000)), debug=False)
