import pytest
import json
from app import app

@pytest.fixture
def client():
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client

def test_home_page(client):
    response = client.get('/')
    assert response.status_code == 200
    assert b'Flask K8s DevSecOps Demo' in response.data

def test_health_endpoint(client):
    response = client.get('/health')
    assert response.status_code == 200
    
    data = json.loads(response.data)
    assert data['status'] == 'healthy'
    assert 'timestamp' in data
    assert data['service'] == 'flask-app'

def test_get_users(client):
    response = client.get('/api/users')
    assert response.status_code == 200
    
    data = json.loads(response.data)
    assert 'users' in data
    assert 'count' in data
    assert data['count'] == 3

def test_get_user_by_id(client):
    response = client.get('/api/users/1')
    assert response.status_code == 200
    
    data = json.loads(response.data)
    assert data['id'] == 1
    assert data['name'] == 'Alice Johnson'

def test_get_user_not_found(client):
    response = client.get('/api/users/999')
    assert response.status_code == 404
    
    data = json.loads(response.data)
    assert data['error'] == 'User not found'

def test_create_user(client):
    new_user = {
        'name': 'Test User',
        'email': 'test@example.com',
        'role': 'user'
    }
    
    response = client.post('/api/users', 
                          data=json.dumps(new_user),
                          content_type='application/json')
    assert response.status_code == 201
    
    data = json.loads(response.data)
    assert data['name'] == 'Test User'
    assert data['email'] == 'test@example.com'
    assert 'id' in data

def test_create_user_missing_fields(client):
    invalid_user = {'name': 'Test User'}
    
    response = client.post('/api/users',
                          data=json.dumps(invalid_user),
                          content_type='application/json')
    assert response.status_code == 400
    
    data = json.loads(response.data)
    assert 'error' in data

def test_metrics_endpoint(client):
    response = client.get('/metrics')
    assert response.status_code == 200
    assert b'flask_requests_total' in response.data

def test_simulate_error(client):
    response = client.get('/api/simulate-error')
    assert response.status_code == 500
    
    data = json.loads(response.data)
    assert 'error' in data

def test_simulate_slow(client):
    response = client.get('/api/simulate-slow')
    assert response.status_code == 200
    
    data = json.loads(response.data)
    assert 'message' in data

def test_build_info_endpoint(client):
    response = client.get('/build-info')
    assert response.status_code == 200
    
    data = json.loads(response.data)
    assert data['service'] == 'flask-app'
    assert 'timestamp' in data
    assert 'build_info' in data
    assert 'environment' in data
    assert 'hostname' in data['environment']
    assert 'build_number' in data['environment']
    assert 'git_commit' in data['environment']

def test_unauthorized_endpoint(client):
    response = client.get('/api/unauthorized')
    assert response.status_code == 401
    
    data = json.loads(response.data)
    assert data['error'] == 'Unauthorized access'

def test_nonexistent_endpoint(client):
    response = client.get('/api/nonexistent')
    assert response.status_code == 404

def test_create_user_invalid_json(client):
    response = client.post('/api/users',
                          data='invalid json',
                          content_type='application/json')
    assert response.status_code == 400

def test_create_user_no_content_type(client):
    new_user = {
        'name': 'Test User',
        'email': 'test@example.com'
    }
    
    response = client.post('/api/users', 
                          data=json.dumps(new_user))
    # Should still work but might behave differently
    assert response.status_code in [400, 201]

def test_create_user_with_optional_role(client):
    new_user = {
        'name': 'Admin User',
        'email': 'admin@example.com',
        'role': 'admin'
    }
    
    response = client.post('/api/users', 
                          data=json.dumps(new_user),
                          content_type='application/json')
    assert response.status_code == 201
    
    data = json.loads(response.data)
    assert data['name'] == 'Admin User'
    assert data['email'] == 'admin@example.com'
    assert data['role'] == 'admin'
    assert 'id' in data

def test_metrics_content_type(client):
    response = client.get('/metrics')
    assert response.status_code == 200
    assert 'text/plain' in response.content_type
    # Check for Prometheus metrics format
    assert b'flask_requests_total' in response.data
    assert b'flask_request_duration_seconds' in response.data

def test_error_handler_with_http_exception(client):
    # Test error handling by triggering a method not allowed error
    response = client.post('/health')  # POST to GET-only endpoint
    assert response.status_code == 405
    
    data = json.loads(response.data)
    assert 'error' in data
    assert 'code' in data
    assert data['code'] == 405

def test_request_logging_and_metrics(client):
    # Make multiple requests to test logging and metrics
    for _ in range(3):
        response = client.get('/health')
        assert response.status_code == 200
    
    # Check metrics endpoint includes our requests
    response = client.get('/metrics')
    assert response.status_code == 200
    metrics_data = response.data.decode('utf-8')
    
    # Should contain metrics about our health check requests
    assert 'flask_requests_total' in metrics_data
    assert 'method="GET"' in metrics_data
    assert 'status="200"' in metrics_data

def test_home_page_content(client):
    response = client.get('/')
    assert response.status_code == 200
    
    # Check for specific content in the home page
    assert b'Flask K8s DevSecOps Demo' in response.data
    assert b'Available API Endpoints' in response.data
    assert b'/health' in response.data
    assert b'/api/users' in response.data
    assert b'/metrics' in response.data
    assert b'/build-info' in response.data
    assert b'Technical Features' in response.data

def test_structured_logging_functionality(client):
    # Test that endpoints that should log structured data work
    response = client.get('/health')
    assert response.status_code == 200
    
    response = client.get('/api/users')
    assert response.status_code == 200
    
    response = client.get('/api/simulate-error')
    assert response.status_code == 500

def test_user_creation_increments_id(client):
    # Get initial user count
    response = client.get('/api/users')
    initial_data = json.loads(response.data)
    initial_count = initial_data['count']
    
    # Create a new user
    new_user = {
        'name': 'Test User',
        'email': 'test@example.com'
    }
    
    response = client.post('/api/users', 
                          data=json.dumps(new_user),
                          content_type='application/json')
    assert response.status_code == 201
    
    created_user = json.loads(response.data)
    expected_id = initial_count + 1
    assert created_user['id'] == expected_id
    
    # Verify the user count increased
    response = client.get('/api/users')
    updated_data = json.loads(response.data)
    assert updated_data['count'] == initial_count + 1

def test_multiple_user_creation(client):
    # Test creating multiple users to ensure ID increments correctly
    users_to_create = [
        {'name': 'User 1', 'email': 'user1@example.com'},
        {'name': 'User 2', 'email': 'user2@example.com'},
        {'name': 'User 3', 'email': 'user3@example.com'}
    ]
    
    created_ids = []
    for user_data in users_to_create:
        response = client.post('/api/users', 
                              data=json.dumps(user_data),
                              content_type='application/json')
        assert response.status_code == 201
        
        user = json.loads(response.data)
        created_ids.append(user['id'])
        assert user['name'] == user_data['name']
        assert user['email'] == user_data['email']
        assert user['role'] == 'user'  # default role
    
    # Ensure IDs are sequential
    for i in range(1, len(created_ids)):
        assert created_ids[i] == created_ids[i-1] + 1
