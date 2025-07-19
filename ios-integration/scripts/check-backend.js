const http = require('http');

// Backend service endpoints
const services = [
    { name: 'API Gateway', url: 'http://localhost:8080/health', port: 8080 },
    { name: 'Auth Service', url: 'http://localhost:8081/health', port: 8081 },
    { name: 'VM Orchestrator', url: 'http://localhost:8082/health', port: 8082 },
    { name: 'App Catalog', url: 'http://localhost:8083/health', port: 8083 }
];

function checkService(service) {
    return new Promise((resolve) => {
        const req = http.request(service.url, { method: 'GET', timeout: 3000 }, (res) => {
            let data = '';
            res.on('data', chunk => data += chunk);
            res.on('end', () => {
                resolve({
                    name: service.name,
                    status: res.statusCode === 200 ? 'healthy' : 'unhealthy',
                    statusCode: res.statusCode,
                    response: data
                });
            });
        });

        req.on('error', (error) => {
            resolve({
                name: service.name,
                status: 'unreachable',
                error: error.message
            });
        });

        req.on('timeout', () => {
            req.destroy();
            resolve({
                name: service.name,
                status: 'timeout',
                error: 'Request timeout'
            });
        });

        req.end();
    });
}

async function checkAllServices() {
    console.log('🔍 Checking ShaydZ AVMo Backend Services...\n');
    
    const results = await Promise.all(services.map(checkService));
    
    let allHealthy = true;
    results.forEach(result => {
        const statusIcon = result.status === 'healthy' ? '✅' : '❌';
        console.log(`${statusIcon} ${result.name}: ${result.status}`);
        if (result.status !== 'healthy') {
            allHealthy = false;
            if (result.error) {
                console.log(`   Error: ${result.error}`);
            }
        }
    });
    
    console.log('\n' + '='.repeat(50));
    if (allHealthy) {
        console.log('🎉 All backend services are running and healthy!');
        console.log('✨ iOS app integration ready');
    } else {
        console.log('⚠️  Some services are not responding');
        console.log('💡 Make sure Docker containers are running:');
        console.log('   cd demo-production && docker-compose up -d');
    }
    console.log('='.repeat(50));
}

// Run the check
checkAllServices().catch(console.error);
