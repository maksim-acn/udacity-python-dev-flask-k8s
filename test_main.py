"""
Unit tests for Flask JWT API

Run with: python -m pytest test_main.py -v
"""
import os
import json
import pytest

# Set JWT_SECRET before importing APP
os.environ['JWT_SECRET'] = 'test-secret-key'

from main import APP


@pytest.fixture
def client():
    """Create a test client for the Flask app."""
    APP.config['TESTING'] = True
    with APP.test_client() as client:
        yield client


class TestHealthEndpoint:
    """Tests for GET / endpoint."""
    
    def test_health_returns_healthy(self, client):
        """Test that health endpoint returns 'Healthy'."""
        response = client.get('/')
        assert response.status_code == 200
        assert response.data.decode('utf-8') == 'Healthy'


class TestAuthEndpoint:
    """Tests for POST /auth endpoint."""
    
    def test_auth_returns_token(self, client):
        """Test that auth endpoint returns a JWT token."""
        response = client.post(
            '/auth',
            data=json.dumps({'email': 'test@example.com', 'password': 'testpass'}),
            content_type='application/json'
        )
        assert response.status_code == 200
        data = json.loads(response.data)
        assert 'token' in data
        assert len(data['token']) > 0
    
    def test_auth_missing_body(self, client):
        """Test that auth returns 400 when body is missing."""
        response = client.post('/auth', content_type='application/json')
        assert response.status_code == 400
    
    def test_auth_missing_email(self, client):
        """Test that auth returns 400 when email is missing."""
        response = client.post(
            '/auth',
            data=json.dumps({'password': 'testpass'}),
            content_type='application/json'
        )
        assert response.status_code == 400
    
    def test_auth_missing_password(self, client):
        """Test that auth returns 400 when password is missing."""
        response = client.post(
            '/auth',
            data=json.dumps({'email': 'test@example.com'}),
            content_type='application/json'
        )
        assert response.status_code == 400


class TestContentsEndpoint:
    """Tests for GET /contents endpoint."""
    
    def test_contents_returns_payload(self, client):
        """Test that contents endpoint returns decoded JWT payload."""
        # First get a token
        auth_response = client.post(
            '/auth',
            data=json.dumps({'email': 'test@example.com', 'password': 'testpass'}),
            content_type='application/json'
        )
        token = json.loads(auth_response.data)['token']
        
        # Then use it to get contents
        response = client.get(
            '/contents',
            headers={'Authorization': f'Bearer {token}'}
        )
        assert response.status_code == 200
        data = json.loads(response.data)
        assert data['email'] == 'test@example.com'
    
    def test_contents_missing_auth_header(self, client):
        """Test that contents returns 401 when Authorization header is missing."""
        response = client.get('/contents')
        assert response.status_code == 401
    
    def test_contents_invalid_token(self, client):
        """Test that contents returns 401 with an invalid token."""
        response = client.get(
            '/contents',
            headers={'Authorization': 'Bearer invalid-token'}
        )
        assert response.status_code == 401
    
    def test_contents_malformed_auth_header(self, client):
        """Test that contents returns 401 with malformed Authorization header."""
        response = client.get(
            '/contents',
            headers={'Authorization': 'InvalidFormat token123'}
        )
        assert response.status_code == 401
