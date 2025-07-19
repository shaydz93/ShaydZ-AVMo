#!/usr/bin/env node

const axios = require('axios');
const chalk = require('chalk');

class IOSIntegrationTester {
  constructor() {
    this.baseUrl = 'http://localhost:8080';
    this.authToken = null;
  }

  async testAuthentication() {
    console.log(chalk.blue('🔐 Testing Authentication...'));
    
    try {
      const response = await axios.post('http://localhost:8081/login', {
        username: 'demo',
        password: 'password'
      });
      
      this.authToken = response.data.token;
      console.log(chalk.green('✅ Authentication successful'));
      return true;
    } catch (error) {
      console.log(chalk.red('❌ Authentication failed:', error.message));
      return false;
    }
  }

  async testAppCatalog() {
    console.log(chalk.blue('📱 Testing App Catalog API...'));
    
    try {
      const response = await axios.get('http://localhost:8083/apps', {
        headers: { Authorization: `Bearer ${this.authToken}` }
      });
      
      console.log(chalk.green(`✅ Found ${response.data.length} apps in catalog`));
      
      // Test specific iOS-relevant apps
      const iosApps = response.data.filter(app => 
        app.name.toLowerCase().includes('mail') ||
        app.name.toLowerCase().includes('secure') ||
        app.category === 'Communication'
      );
      
      console.log(chalk.cyan(`📲 iOS-relevant apps: ${iosApps.length}`));
      iosApps.forEach(app => {
        console.log(chalk.gray(`   - ${app.name} (${app.category})`));
      });
      
      return response.data;
    } catch (error) {
      console.log(chalk.red('❌ App Catalog test failed:', error.message));
      return null;
    }
  }

  async testVMOrchestrator() {
    console.log(chalk.blue('🖥️  Testing VM Orchestrator API...'));
    
    try {
      const response = await axios.get('http://localhost:8082/vms', {
        headers: { Authorization: `Bearer ${this.authToken}` }
      });
      
      console.log(chalk.green(`✅ Found ${response.data.length} VMs available`));
      
      response.data.forEach(vm => {
        console.log(chalk.gray(`   - ${vm.name} (${vm.status})`));
      });
      
      return response.data;
    } catch (error) {
      console.log(chalk.red('❌ VM Orchestrator test failed:', error.message));
      return null;
    }
  }

  async testAPILatency() {
    console.log(chalk.blue('⚡ Testing API Response Times...'));
    
    const endpoints = [
      { name: 'Health Check', url: 'http://localhost:8081/health' },
      { name: 'Apps Catalog', url: 'http://localhost:8083/apps', requiresAuth: true },
      { name: 'VMs List', url: 'http://localhost:8082/vms', requiresAuth: true }
    ];
    
    for (const endpoint of endpoints) {
      try {
        const start = Date.now();
        const config = endpoint.requiresAuth ? 
          { headers: { Authorization: `Bearer ${this.authToken}` } } : {};
        
        await axios.get(endpoint.url, config);
        const duration = Date.now() - start;
        
        const status = duration < 100 ? '🟢' : duration < 500 ? '🟡' : '🔴';
        console.log(chalk.gray(`   ${status} ${endpoint.name}: ${duration}ms`));
      } catch (error) {
        console.log(chalk.red(`   ❌ ${endpoint.name}: Failed`));
      }
    }
  }

  async generateIOSConfig() {
    console.log(chalk.blue('📋 Generating iOS Configuration...'));
    
    const config = {
      apiEndpoints: {
        baseUrl: 'http://localhost:8080',
        authService: 'http://localhost:8081',
        appCatalog: 'http://localhost:8083',
        vmOrchestrator: 'http://localhost:8082'
      },
      authentication: {
        tokenEndpoint: '/login',
        profileEndpoint: '/profile',
        tokenValidityPeriod: '1h'
      },
      features: {
        appCatalogEnabled: true,
        vmManagementEnabled: true,
        offlineMode: false
      },
      networking: {
        timeoutMs: 30000,
        retryAttempts: 3,
        connectionPoolSize: 10
      }
    };
    
    console.log(chalk.green('✅ iOS Configuration generated'));
    console.log(chalk.gray(JSON.stringify(config, null, 2)));
    
    return config;
  }

  async runFullTest() {
    console.log(chalk.yellow('🚀 Running Full iOS Integration Test Suite\n'));
    
    const results = {
      authentication: await this.testAuthentication(),
      appCatalog: null,
      vmOrchestrator: null,
      config: null
    };
    
    if (results.authentication) {
      results.appCatalog = await this.testAppCatalog();
      results.vmOrchestrator = await this.testVMOrchestrator();
      await this.testAPILatency();
      results.config = await this.generateIOSConfig();
    }
    
    console.log(chalk.yellow('\n📊 Test Summary:'));
    console.log(chalk.gray('─'.repeat(50)));
    console.log(`Authentication: ${results.authentication ? chalk.green('✅ PASS') : chalk.red('❌ FAIL')}`);
    console.log(`App Catalog: ${results.appCatalog ? chalk.green('✅ PASS') : chalk.red('❌ FAIL')}`);
    console.log(`VM Orchestrator: ${results.vmOrchestrator ? chalk.green('✅ PASS') : chalk.red('❌ FAIL')}`);
    console.log(`Configuration: ${results.config ? chalk.green('✅ GENERATED') : chalk.red('❌ FAIL')}`);
    
    const allPassed = results.authentication && results.appCatalog && results.vmOrchestrator && results.config;
    console.log(chalk.gray('─'.repeat(50)));
    console.log(`Overall Status: ${allPassed ? chalk.green('🎉 READY FOR iOS INTEGRATION') : chalk.red('⚠️  NEEDS ATTENTION')}`);
    
    return results;
  }
}

// Run the test if called directly
if (require.main === module) {
  const tester = new IOSIntegrationTester();
  tester.runFullTest().catch(console.error);
}

module.exports = IOSIntegrationTester;
