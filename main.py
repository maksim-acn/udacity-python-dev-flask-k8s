"""
Flask JWT API - Simple JWT Authentication Service

Endpoints:
- GET /         : Health check
- POST /auth    : Generate JWT token
- GET /contents : Decode and return JWT payload (requires auth)
"""
import os
import logging
from flask import Flask, request, jsonify, abort
import jwt

# Configure logging
LOG_LEVEL = os.environ.get('LOG_LEVEL', 'INFO').upper()
logging.basicConfig(level=LOG_LEVEL)
logger = logging.getLogger(__name__)

# JWT Secret from environment variable
JWT_SECRET = os.environ.get('JWT_SECRET', 'abc123abc1234')
JWT_ALGORITHM = 'HS256'

APP = Flask(__name__)


@APP.route('/', methods=['GET'])
def health():
    """Health check endpoint."""
    return "Healthy"


@APP.route('/auth', methods=['POST'])
def auth():
    """
    Generate a JWT token for the provided email and password.
    
    Request body (JSON):
        - email: user email address
        - password: user password
    
    Returns:
        - token: JWT token containing email in payload
    """
    request_data = request.get_json()
    
    if not request_data:
        logger.warning("No request body provided")
        abort(400, description="Missing request body")
    
    email = request_data.get('email')
    password = request_data.get('password')
    
    if not email:
        logger.warning("Email field is missing")
        abort(400, description="Missing 'email' field")
    
    if not password:
        logger.warning("Password field is missing")
        abort(400, description="Missing 'password' field")
    
    logger.info(f"Generating token for user: {email}")
    
    # Create JWT token with email in payload
    payload = {'email': email}
    token = jwt.encode(payload, JWT_SECRET, algorithm=JWT_ALGORITHM)
    
    # pyjwt 1.x returns bytes, 2.x returns string
    if isinstance(token, bytes):
        token = token.decode('utf-8')
    
    return jsonify({'token': token})


@APP.route('/contents', methods=['GET'])
def contents():
    """
    Decode JWT token and return the payload.
    
    Headers:
        - Authorization: Bearer <token>
    
    Returns:
        - Decoded JWT payload (email, exp, nbf)
    """
    auth_header = request.headers.get('Authorization')
    
    if not auth_header:
        logger.warning("No Authorization header provided")
        abort(401, description="Missing Authorization header")
    
    # Extract token from "Bearer <token>" format
    parts = auth_header.split()
    
    if len(parts) != 2 or parts[0].lower() != 'bearer':
        logger.warning("Invalid Authorization header format")
        abort(401, description="Invalid Authorization header format. Expected 'Bearer <token>'")
    
    token = parts[1]
    
    try:
        payload = jwt.decode(token, JWT_SECRET, algorithms=[JWT_ALGORITHM])
        logger.info(f"Token decoded successfully for: {payload.get('email')}")
        return jsonify(payload)
    except jwt.ExpiredSignatureError:
        logger.warning("Token has expired")
        abort(401, description="Token has expired")
    except jwt.InvalidTokenError as e:
        logger.warning(f"Invalid token: {str(e)}")
        abort(401, description="Invalid token")


if __name__ == '__main__':
    # This block is only executed when running the script directly (local development)
    # properly. In production (Docker), Gunicorn is used as the entry point.
    logger.info("Starting Flask application in local development mode")
    APP.run(host='0.0.0.0', port=8080, debug=True)
