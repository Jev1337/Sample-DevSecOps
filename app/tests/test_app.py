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
