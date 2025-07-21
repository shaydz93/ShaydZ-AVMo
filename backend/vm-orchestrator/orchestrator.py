from flask import Flask, request, jsonify
import jwt
import os
import subprocess
import json
import threading
import time
import logging
from pymongo import MongoClient
from bson.objectid import ObjectId
import websockets
import asyncio
import psutil

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Flask app configuration
app = Flask(__name__)
app.config['SECRET_KEY'] = os.environ.get('JWT_SECRET', 'your_jwt_secret_key_here')
app.config['PORT'] = int(os.environ.get('PORT', 8084))

# MongoDB connection
mongo_uri = os.environ.get('DB_CONNECTION_STRING', 'mongodb://localhost:27017/vms')
client = MongoClient(mongo_uri)
db = client.get_database()
vms_collection = db.vms

# Handle Supabase JWT tokens
def decode_supabase_token(token):
    try:
        # Supabase tokens are JWT tokens
        # We can decode them to verify and extract user info
        return jwt.decode(
            token, 
            app.config['SECRET_KEY'], 
            algorithms=["HS256"],
            options={"verify_signature": False}  # For demo, we'll skip signature verification
        )
    except Exception as e:
        logger.error(f"Error decoding token: {e}")
        return None

# Store active VM sessions
active_vms = {}
active_websockets = {}

# JWT authentication middleware for Supabase tokens
def authenticate(f):
    def decorator(*args, **kwargs):
        token = None
        auth_header = request.headers.get('Authorization')
        
        if auth_header and auth_header.startswith('Bearer '):
            token = auth_header.split(' ')[1]
            
        if not token:
            return jsonify({'message': 'Authentication token is missing'}), 401
            
        try:
            # Use our Supabase token decoder
            decoded_token = decode_supabase_token(token)
            
            if not decoded_token or 'sub' not in decoded_token:
                raise ValueError("Invalid token structure")
                
            # In Supabase, the user ID is in the 'sub' claim
            current_user = {
                'id': decoded_token.get('sub'),
                'email': decoded_token.get('email', ''),
                'role': decoded_token.get('role', 'user')
            }
        except Exception as e:
            logger.error(f"Token validation error: {e}")
            return jsonify({'message': 'Invalid authentication token'}), 401
            
        return f(current_user, *args, **kwargs)
    decorator.__name__ = f.__name__
    return decorator

# Root endpoint
@app.route('/', methods=['GET'])
def root():
    return jsonify({
        'service': 'VM Orchestrator',
        'status': 'UP',
        'version': '1.0.0'
    })

# Health check endpoint
@app.route('/health', methods=['GET'])
def health_check():
    return jsonify({
        'status': 'UP',
        'timestamp': time.time(),
        'services': {
            'database': 'UP' if check_db_connection() else 'DOWN',
            'emulator': 'UP' if check_emulator_status() else 'DOWN'
        }
    })

def check_db_connection():
    try:
        client.admin.command('ping')
        return True
    except Exception:
        return False

def check_emulator_status():
    try:
        # Check if Android emulator processes are running
        for proc in psutil.process_iter(['name']):
            if 'emulator' in proc.info['name'] or 'qemu' in proc.info['name']:
                return True
        return False
    except Exception:
        return False

# Launch a new VM instance
@app.route('/launch', methods=['POST'])
@authenticate
def launch_vm(current_user):
    try:
        user_id = current_user['id']
        request_data = request.get_json()
        
        # Check if user already has an active VM
        existing_vm = vms_collection.find_one({'user_id': user_id, 'status': 'running'})
        if existing_vm:
            vm_id = str(existing_vm['_id'])
            return jsonify({
                'message': 'VM already running',
                'vm_id': vm_id,
                'connection_info': existing_vm['connection_info']
            })
        
        # VM configuration
        vm_config = {
            'android_version': request_data.get('android_version', '11.0'),
            'ram': request_data.get('ram', '2048M'),
            'resolution': request_data.get('resolution', '1080x1920'),
            'cpu_cores': request_data.get('cpu_cores', 2),
        }
        
        # Create VM document in MongoDB
        vm_doc = {
            'user_id': user_id,
            'config': vm_config,
            'status': 'starting',
            'created_at': time.time(),
            'connection_info': None
        }
        
        result = vms_collection.insert_one(vm_doc)
        vm_id = str(result.inserted_id)
        
        # Start VM in a separate thread
        threading.Thread(target=start_vm_process, args=(vm_id, vm_config)).start()
        
        return jsonify({
            'message': 'VM is starting',
            'vm_id': vm_id,
            'status': 'starting'
        })
        
    except Exception as e:
        logger.error(f"Error launching VM: {e}")
        return jsonify({'message': 'Error launching VM'}), 500

def start_vm_process(vm_id, config):
    try:
        # Simulate starting the Android VM
        # In a real implementation, this would use QEMU/KVM or Android emulator
        logger.info(f"Starting VM {vm_id} with config: {config}")
        time.sleep(10)  # Simulate startup time
        
        # Generate connection info
        connection_info = {
            'ip': '10.0.0.' + str(int(time.time()) % 255),
            'port': 5555,
            'websocket_url': f"ws://localhost:8084/vm/{vm_id}/stream",
            'rtc_url': f"wss://rtc.avmo.local/vm/{vm_id}"
        }
        
        # Update VM status in database
        vms_collection.update_one(
            {'_id': ObjectId(vm_id)},
            {'$set': {
                'status': 'running',
                'connection_info': connection_info,
                'started_at': time.time()
            }}
        )
        
        # Add to active VMs
        active_vms[vm_id] = {
            'process': None,  # Would be the actual process in real implementation
            'config': config,
            'connection_info': connection_info
        }
        
        logger.info(f"VM {vm_id} started successfully")
        
    except Exception as e:
        logger.error(f"Error starting VM {vm_id}: {e}")
        vms_collection.update_one(
            {'_id': ObjectId(vm_id)},
            {'$set': {'status': 'error', 'error': str(e)}}
        )

# Get VM status
@app.route('/vm/<vm_id>', methods=['GET'])
@authenticate
def get_vm_status(current_user, vm_id):
    try:
        vm = vms_collection.find_one({'_id': ObjectId(vm_id)})
        
        if not vm:
            return jsonify({'message': 'VM not found'}), 404
            
        # Check if user has access to this VM
        if vm['user_id'] != current_user['id'] and current_user['role'] != 'admin':
            return jsonify({'message': 'Access denied'}), 403
            
        return jsonify({
            'vm_id': vm_id,
            'status': vm['status'],
            'config': vm['config'],
            'connection_info': vm['connection_info'] if vm['status'] == 'running' else None
        })
        
    except Exception as e:
        logger.error(f"Error getting VM status: {e}")
        return jsonify({'message': 'Error retrieving VM status'}), 500

# Stop VM
@app.route('/vm/<vm_id>/stop', methods=['POST'])
@authenticate
def stop_vm(current_user, vm_id):
    try:
        vm = vms_collection.find_one({'_id': ObjectId(vm_id)})
        
        if not vm:
            return jsonify({'message': 'VM not found'}), 404
            
        # Check if user has access to this VM
        if vm['user_id'] != current_user['id'] and current_user['role'] != 'admin':
            return jsonify({'message': 'Access denied'}), 403
            
        if vm['status'] != 'running':
            return jsonify({'message': f"VM is not running (current status: {vm['status']})"}), 400
        
        # Stop VM process
        if vm_id in active_vms:
            # Terminate the process (in real implementation)
            # if active_vms[vm_id]['process']:
            #     active_vms[vm_id]['process'].terminate()
            
            del active_vms[vm_id]
            
        # Update VM status in database
        vms_collection.update_one(
            {'_id': ObjectId(vm_id)},
            {'$set': {
                'status': 'stopped',
                'stopped_at': time.time()
            }}
        )
        
        return jsonify({'message': 'VM stopped successfully'})
        
    except Exception as e:
        logger.error(f"Error stopping VM: {e}")
        return jsonify({'message': 'Error stopping VM'}), 500

# List user's VMs
@app.route('/vms', methods=['GET'])
@authenticate
def list_user_vms(current_user):
    try:
        user_id = current_user['id']
        status_filter = request.args.get('status')
        
        query = {'user_id': user_id}
        if status_filter:
            query['status'] = status_filter
            
        vms = list(vms_collection.find(query))
        
        # Convert ObjectId to string for JSON serialization
        for vm in vms:
            vm['_id'] = str(vm['_id'])
            
        return jsonify({'vms': vms})
        
    except Exception as e:
        logger.error(f"Error listing VMs: {e}")
        return jsonify({'message': 'Error retrieving VMs'}), 500

# WebSocket streaming endpoint (would be implemented with asyncio in production)
@app.route('/vm/<vm_id>/stream', methods=['GET'])
def vm_stream_info(vm_id):
    vm = vms_collection.find_one({'_id': ObjectId(vm_id)})
    
    if not vm or vm['status'] != 'running':
        return jsonify({'message': 'VM not running'}), 404
        
    return jsonify({
        'websocket_url': f"ws://localhost:8084/stream/{vm_id}",
        'status': 'available'
    })

# Run the Flask application
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=app.config['PORT'])
