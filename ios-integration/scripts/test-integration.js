const http = require('http');

async function testIntegration() {
    console.log('🧪 Testing iOS-Backend Integration...\n');
    
    const tests = [
        {
            name: 'Authentication Flow',
            test: () => testAuth()
        },
        {
            name: 'App Catalog Access',
            test: () => testAppCatalog()
        },
        {
            name: 'VM Management',
            test: () => testVMOperations()
        },
        {
            name: 'Real-time Updates',
            test: () => testRealtimeUpdates()
        }
    ];
    
    let passed = 0;
    let failed = 0;
    
    for (const test of tests) {
        try {
            console.log(`🔍 Testing ${test.name}...`);
            await test.test();
            console.log(`✅ ${test.name} - PASSED\n`);
            passed++;
        } catch (error) {
            console.log(`❌ ${test.name} - FAILED: ${error.message}\n`);
            failed++;
        }
    }
    
    console.log('='.repeat(50));
    console.log(`📊 Integration Test Results:`);
    console.log(`✅ Passed: ${passed}`);
    console.log(`❌ Failed: ${failed}`);
    console.log(`📈 Success Rate: ${Math.round((passed / (passed + failed)) * 100)}%`);
    console.log('='.repeat(50));
    
    if (failed === 0) {
        console.log('🎉 All integration tests passed!');
        console.log('🚀 iOS app is ready for backend integration');
    } else {
        console.log('⚠️  Some tests failed - check backend services');
    }
}

async function testAuth() {
    const response = await makeRequest('http://localhost:8081/api/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ username: 'demo', password: 'password' })
    });
    
    if (!response.token) {
        throw new Error('No authentication token received');
    }
}

async function testAppCatalog() {
    const apps = await makeRequest('http://localhost:8083/api/apps');
    
    if (!Array.isArray(apps) || apps.length === 0) {
        throw new Error('No apps found in catalog');
    }
    
    if (!apps[0].name || !apps[0].id) {
        throw new Error('App structure invalid');
    }
}

async function testVMOperations() {
    const vms = await makeRequest('http://localhost:8082/api/vms');
    
    if (!Array.isArray(vms)) {
        throw new Error('VM list not accessible');
    }
    
    // Test VM creation endpoint exists
    try {
        await makeRequest('http://localhost:8082/api/vms/create', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ appId: 'test' })
        });
    } catch (error) {
        // Expected to fail with validation, but endpoint should exist
        if (!error.message.includes('400') && !error.message.includes('validation')) {
            throw new Error('VM creation endpoint not accessible');
        }
    }
}

async function testRealtimeUpdates() {
    // Test multiple rapid requests to simulate real-time updates
    const promises = [
        makeRequest('http://localhost:8083/api/apps'),
        makeRequest('http://localhost:8082/api/vms'),
        makeRequest('http://localhost:8080/health')
    ];
    
    const results = await Promise.all(promises);
    
    if (results.some(result => !result)) {
        throw new Error('Real-time data access failed');
    }
}

function makeRequest(url, options = {}) {
    return new Promise((resolve, reject) => {
        const body = options.body;
        delete options.body;
        
        const req = http.request(url, options, (res) => {
            let data = '';
            res.on('data', chunk => data += chunk);
            res.on('end', () => {
                if (res.statusCode >= 400) {
                    reject(new Error(`HTTP ${res.statusCode}: ${data}`));
                    return;
                }
                
                try {
                    const parsed = JSON.parse(data);
                    resolve(parsed);
                } catch (e) {
                    resolve(data);
                }
            });
        });

        req.on('error', reject);
        
        if (body) {
            req.write(body);
        }
        
        req.end();
    });
}

testIntegration();
