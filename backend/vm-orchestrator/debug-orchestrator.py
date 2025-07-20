from flask import Flask, jsonify, request
import json
import time
import random

app = Flask(__name__)

# Mock VM data
mock_vms = {
    'vm-1': {
        'id': 'vm-1',
        'name': 'Android Enterprise',
        'status': 'running',
        'architecture': 'arm64',
        'cpu_cores': 4,
        'memory_mb': 4096,
        'disk_gb': 32,
        'ip_address': '192.168.100.10',
        'vnc_port': 5900,
        'created_at': '2025-07-19T10:30:00Z',
        'performance': {
            'cpu_usage': random.randint(20, 80),
            'memory_usage': random.randint(40, 90),
            'network_rx': random.randint(100, 1000),
            'network_tx': random.randint(50, 500)
        }
    }
}

@app.route('/health', methods=['GET'])
def health():
    return jsonify({
        'status': 'OK',
        'service': 'vm-orchestrator-debug',
        'timestamp': time.strftime('%Y-%m-%dT%H:%M:%SZ'),
        'qemu_available': True,
        'utm_features': True
    })

@app.route('/api/vm/list', methods=['GET'])
def list_vms():
    print('DEBUG: VM list request')
    return jsonify({
        'success': True,
        'vms': list(mock_vms.values()),
        'total': len(mock_vms)
    })

@app.route('/api/vm/create', methods=['POST'])
def create_vm():
    data = request.get_json()
    vm_id = f"vm-{int(time.time())}"
    
    new_vm = {
        'id': vm_id,
        'name': data.get('name', 'New Android VM'),
        'status': 'creating',
        'architecture': data.get('architecture', 'arm64'),
        'cpu_cores': data.get('cpu_cores', 4),
        'memory_mb': data.get('memory_mb', 4096),
        'disk_gb': data.get('disk_gb', 32),
        'created_at': time.strftime('%Y-%m-%dT%H:%M:%SZ'),
        'performance': {
            'cpu_usage': 0,
            'memory_usage': 0,
            'network_rx': 0,
            'network_tx': 0
        }
    }
    
    mock_vms[vm_id] = new_vm
    print(f'DEBUG: Created VM {vm_id}')
    
    return jsonify({
        'success': True,
        'vm': new_vm,
        'message': 'VM creation started'
    })

@app.route('/api/vm/<vm_id>/start', methods=['POST'])
def start_vm(vm_id):
    if vm_id in mock_vms:
        mock_vms[vm_id]['status'] = 'running'
        mock_vms[vm_id]['ip_address'] = f"192.168.100.{random.randint(10, 50)}"
        mock_vms[vm_id]['vnc_port'] = 5900 + random.randint(0, 99)
        
        print(f'DEBUG: Started VM {vm_id}')
        return jsonify({
            'success': True,
            'vm': mock_vms[vm_id],
            'message': 'VM started successfully'
        })
    else:
        return jsonify({'success': False, 'error': 'VM not found'}), 404

@app.route('/api/vm/<vm_id>/stop', methods=['POST'])
def stop_vm(vm_id):
    if vm_id in mock_vms:
        mock_vms[vm_id]['status'] = 'stopped'
        print(f'DEBUG: Stopped VM {vm_id}')
        return jsonify({
            'success': True,
            'vm': mock_vms[vm_id],
            'message': 'VM stopped successfully'
        })
    else:
        return jsonify({'success': False, 'error': 'VM not found'}), 404

@app.route('/api/vm/<vm_id>/status', methods=['GET'])
def vm_status(vm_id):
    if vm_id in mock_vms:
        # Update performance metrics
        vm = mock_vms[vm_id]
        if vm['status'] == 'running':
            vm['performance'] = {
                'cpu_usage': random.randint(20, 80),
                'memory_usage': random.randint(40, 90),
                'network_rx': random.randint(100, 1000),
                'network_tx': random.randint(50, 500)
            }
        
        return jsonify({
            'success': True,
            'vm': vm
        })
    else:
        return jsonify({'success': False, 'error': 'VM not found'}), 404

@app.route('/api/vm/templates', methods=['GET'])
def vm_templates():
    templates = [
        {
            'id': 'android-enterprise',
            'name': 'Android Enterprise',
            'description': 'Secure Android environment for business apps',
            'architecture': 'arm64',
            'cpu_cores': 4,
            'memory_mb': 4096,
            'disk_gb': 32,
            'features': ['TPM 2.0', 'Secure Boot', 'Disk Encryption']
        },
        {
            'id': 'android-standard',
            'name': 'Android Standard',
            'description': 'Standard Android environment',
            'architecture': 'arm64',
            'cpu_cores': 2,
            'memory_mb': 2048,
            'disk_gb': 16,
            'features': ['Basic Security', 'App Isolation']
        }
    ]
    
    return jsonify({
        'success': True,
        'templates': templates
    })

if __name__ == '__main__':
    print('🚀 VM Orchestrator Debug Service starting...')
    print('✅ UTM-Enhanced QEMU VM management (debug mode)')
    print('✅ Mock VMs with performance monitoring')
    app.run(host='0.0.0.0', port=5000, debug=True)
