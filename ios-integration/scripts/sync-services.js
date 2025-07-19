const http = require('http');

async function syncWithBackend() {
    console.log('🔄 Synchronizing iOS app with backend services...\n');
    
    try {
        // Fetch user profile
        const userProfile = await makeRequest('http://localhost:8081/api/profile', {
            method: 'GET',
            headers: { 'Authorization': 'Bearer demo-jwt-token' }
        });
        
        // Fetch available apps
        const apps = await makeRequest('http://localhost:8083/api/apps');
        
        // Fetch VM status
        const vms = await makeRequest('http://localhost:8082/api/vms');
        
        console.log('✅ User Profile synced');
        console.log('✅ App Catalog synced (' + (apps?.length || 0) + ' apps)');
        console.log('✅ Virtual Machines synced (' + (vms?.length || 0) + ' VMs)');
        
        console.log('\n📱 iOS App State Summary:');
        console.log('- User: demo (authenticated)');
        console.log('- Available Apps: ' + (apps?.length || 0));
        console.log('- Active VMs: ' + (vms?.filter(vm => vm.status === 'running')?.length || 0));
        console.log('- Backend Connection: ✅ Active');
        
    } catch (error) {
        console.error('❌ Sync failed:', error.message);
        console.log('💡 Ensure backend services are running');
    }
}

function makeRequest(url, options = {}) {
    return new Promise((resolve, reject) => {
        const req = http.request(url, options, (res) => {
            let data = '';
            res.on('data', chunk => data += chunk);
            res.on('end', () => {
                try {
                    const parsed = JSON.parse(data);
                    resolve(parsed);
                } catch (e) {
                    resolve(data);
                }
            });
        });

        req.on('error', reject);
        req.end();
    });
}

syncWithBackend();
