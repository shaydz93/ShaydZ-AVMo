from flask import Flask, request, jsonify
import os
import json
import time
import jwt
from pymongo import MongoClient
from bson.objectid import ObjectId
import uuid
from datetime import datetime, timedelta

# Initialize Flask app
app = Flask(__name__)

# MongoDB setup
mongo_uri = os.environ.get('MONGO_URI', 'mongodb://localhost:27017/vms')
mongo_client = MongoClient(mongo_uri)
db = mongo_client.get_database()

# JWT secret
jwt_secret = os.environ.get('JWT_SECRET', 'demo-jwt-secret-key-for-testing-only')

# Helper functions
def authenticate():
    """Authenticate a request using JWT"""
    auth_header = request.headers.get('Authorization')
    if not auth_header:
        return None
    
    try:
        token = auth_header.split(' ')[1]
        payload = jwt.decode(token, jwt_secret, algorithms=['HS256'])
        return payload
    except Exception as e:
        print(f"Auth error: {e}")
        return None

# Create indexes and demo data
def init_db():
    """Initialize database with indexes and demo data"""
    # Create indexes
    db.vms.create_index("userId")
    db.vms.create_index("status")
    
    # Add demo VM if none exists
    if db.vms.count_documents({}) == 0:
        demo_vms = [
            {
                "name": "Android 13 VM",
                "description": "Android 13 virtual environment",
                "status": "RUNNING",
                "os": "Android",
                "osVersion": "13",
                "created": datetime.utcnow().isoformat(),
                "lastActive": datetime.utcnow().isoformat(),
                "ipAddress": "10.0.0.5",
                "userId": "demo_user",
                "specs": {
                    "cpu": 2,
                    "memory": "4GB",
                    "storage": "16GB"
                },
                "apps": ["com.shaydz.securebrowser", "com.shaydz.securemail"]
            },
            {
                "name": "Android 12 VM",
                "description": "Android 12 virtual environment",
                "status": "STOPPED",
                "os": "Android",
                "osVersion": "12",
                "created": (datetime.utcnow() - timedelta(days=30)).isoformat(),
                "lastActive": (datetime.utcnow() - timedelta(days=5)).isoformat(),
                "ipAddress": "10.0.0.6",
                "userId": "demo_user",
                "specs": {
                    "cpu": 1,
                    "memory": "2GB",
                    "storage": "8GB"
                },
                "apps": ["com.shaydz.securebrowser"]
            }
        ]
        db.vms.insert_many(demo_vms)
        print("Created demo VMs")

# Routes
@app.route('/health', methods=['GET'])
def health():
    return jsonify({'status': 'ok', 'service': 'vm-orchestrator'})

@app.route('/vms', methods=['GET'])
def get_vms():
    user = authenticate()
    if not user:
        return jsonify({'message': 'Unauthorized'}), 401
    
    # For demo purposes, always return all VMs
    vms = list(db.vms.find({}, {'_id': False}))
    return jsonify(vms)

@app.route('/vms/<vm_id>', methods=['GET'])
def get_vm(vm_id):
    user = authenticate()
    if not user:
        return jsonify({'message': 'Unauthorized'}), 401
    
    vm = db.vms.find_one({'id': vm_id}, {'_id': False})
    if not vm:
        return jsonify({'message': 'VM not found'}), 404
    
    return jsonify(vm)

@app.route('/vms/<vm_id>/start', methods=['POST'])
def start_vm(vm_id):
    user = authenticate()
    if not user:
        return jsonify({'message': 'Unauthorized'}), 401
    
    # Simulate starting a VM with delay
    time.sleep(1)
    
    result = db.vms.update_one(
        {'id': vm_id},
        {'$set': {'status': 'STARTING'}}
    )
    
    if result.matched_count == 0:
        return jsonify({'message': 'VM not found'}), 404
    
    # Simulate VM startup process
    time.sleep(1)
    
    db.vms.update_one(
        {'id': vm_id},
        {'$set': {
            'status': 'RUNNING', 
            'lastActive': datetime.utcnow().isoformat(),
            'ipAddress': f'10.0.0.{int(time.time()) % 255}'
        }}
    )
    
    return jsonify({'message': 'VM started successfully'})

@app.route('/vms/<vm_id>/stop', methods=['POST'])
def stop_vm(vm_id):
    user = authenticate()
    if not user:
        return jsonify({'message': 'Unauthorized'}), 401
    
    # Simulate stopping a VM with delay
    time.sleep(1)
    
    result = db.vms.update_one(
        {'id': vm_id},
        {'$set': {'status': 'STOPPING'}}
    )
    
    if result.matched_count == 0:
        return jsonify({'message': 'VM not found'}), 404
    
    # Simulate VM shutdown process
    time.sleep(1)
    
    db.vms.update_one(
        {'id': vm_id},
        {'$set': {
            'status': 'STOPPED', 
            'lastActive': datetime.utcnow().isoformat()
        }}
    )
    
    return jsonify({'message': 'VM stopped successfully'})

@app.route('/vms/<vm_id>/connect', methods=['GET'])
def connect_vm(vm_id):
    user = authenticate()
    if not user:
        return jsonify({'message': 'Unauthorized'}), 401
    
    vm = db.vms.find_one({'id': vm_id}, {'_id': False})
    if not vm:
        return jsonify({'message': 'VM not found'}), 404
    
    if vm['status'] != 'RUNNING':
        return jsonify({'message': 'VM is not running'}), 400
    
    # In real implementation, this would return WebSocket connection details
    connection_info = {
        'wsEndpoint': os.environ.get('WS_ENDPOINT', 'ws://localhost:8082/ws'),
        'token': jwt.encode(
            {'vmId': vm_id, 'exp': datetime.utcnow() + timedelta(hours=1)},
            jwt_secret,
            algorithm='HS256'
        ),
        'resolution': '1080x1920'
    }
    
    return jsonify(connection_info)

@app.route('/vms', methods=['POST'])
def create_vm():
    user = authenticate()
    if not user:
        return jsonify({'message': 'Unauthorized'}), 401
    
    data = request.json
    if not data or 'name' not in data or 'os' not in data:
        return jsonify({'message': 'Missing required fields'}), 400
    
    # Create VM
    vm_id = str(uuid.uuid4())
    vm = {
        'id': vm_id,
        'name': data['name'],
        'description': data.get('description', ''),
        'status': 'CREATING',
        'os': data['os'],
        'osVersion': data.get('osVersion', 'latest'),
        'created': datetime.utcnow().isoformat(),
        'lastActive': datetime.utcnow().isoformat(),
        'userId': user['id'],
        'specs': {
            'cpu': data.get('cpu', 1),
            'memory': data.get('memory', '2GB'),
            'storage': data.get('storage', '8GB')
        },
        'apps': []
    }
    
    db.vms.insert_one(vm)
    
    # Simulate VM creation process
    time.sleep(2)
    
    # Update status
    db.vms.update_one(
        {'id': vm_id},
        {'$set': {
            'status': 'STOPPED',
            'ipAddress': f'10.0.0.{int(time.time()) % 255}'
        }}
    )
    
    # Return the created VM
    vm = db.vms.find_one({'id': vm_id}, {'_id': False})
    return jsonify(vm), 201

# Initialize database and start server
if __name__ == '__main__':
    init_db()
    port = int(os.environ.get('PORT', 8082))
    app.run(host='0.0.0.0', port=port)
