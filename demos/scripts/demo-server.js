#!/usr/bin/env node

const express = require('express');
const path = require('path');
const chalk = require('chalk');
const { createProxyMiddleware } = require('http-proxy-middleware');

class DemoWebServer {
  constructor() {
    this.app = express();
    this.port = 3000;
    this.demoPath = path.join(__dirname, '..', 'demo');
  }

  setupMiddleware() {
    // Serve static files
    this.app.use(express.static(this.demoPath));
    
    // CORS headers for API calls
    this.app.use((req, res, next) => {
      res.header('Access-Control-Allow-Origin', '*');
      res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
      res.header('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept, Authorization');
      if (req.method === 'OPTIONS') {
        res.sendStatus(200);
      } else {
        next();
      }
    });

    // Proxy API calls to backend services
    const apiProxy = createProxyMiddleware({
      target: 'http://localhost:8081',
      changeOrigin: true,
      router: (req) => {
        if (req.path.includes('/apps')) return 'http://localhost:8083';
        if (req.path.includes('/vms')) return 'http://localhost:8082';
        if (req.path.includes('/login') || req.path.includes('/health') || req.path.includes('/profile')) return 'http://localhost:8081';
        return 'http://localhost:8080';
      },
      onError: (err, req, res) => {
        console.log(chalk.red(`Proxy error: ${err.message}`));
        res.status(500).json({ error: 'Backend service unavailable' });
      }
    });

    this.app.use('/api', apiProxy);
    
    // Direct proxy routes for backend services
    this.app.use('/login', createProxyMiddleware({ target: 'http://localhost:8081', changeOrigin: true }));
    this.app.use('/apps', createProxyMiddleware({ target: 'http://localhost:8083', changeOrigin: true }));
    this.app.use('/vms', createProxyMiddleware({ target: 'http://localhost:8082', changeOrigin: true }));
    this.app.use('/health', createProxyMiddleware({ target: 'http://localhost:8081', changeOrigin: true }));

    // Main routes
    this.app.get('/', (req, res) => {
      res.sendFile(path.join(this.demoPath, 'app-demo.html'));
    });

    this.app.get('/app', (req, res) => {
      res.sendFile(path.join(this.demoPath, 'app-demo.html'));
    });

    this.app.get('/backend', (req, res) => {
      res.sendFile(path.join(this.demoPath, 'live-backend-demo.html'));
    });

    this.app.get('/live', (req, res) => {
      res.sendFile(path.join(this.demoPath, 'live-backend-demo.html'));
    });
  }

  async start() {
    this.setupMiddleware();

    return new Promise((resolve) => {
      this.server = this.app.listen(this.port, () => {
        console.log(chalk.green.bold('🚀 ShaydZ AVMo Demo Server Started!\n'));
        
        console.log(chalk.blue('📱 iOS App Demo:'));
        console.log(chalk.cyan(`   http://localhost:${this.port}/app`));
        console.log(chalk.gray('   Interactive iOS app simulator\n'));
        
        console.log(chalk.blue('🔗 Live Backend Demo:'));
        console.log(chalk.cyan(`   http://localhost:${this.port}/backend`));
        console.log(chalk.gray('   Real-time backend integration\n'));
        
        console.log(chalk.blue('🏠 Main Dashboard:'));
        console.log(chalk.cyan(`   http://localhost:${this.port}/`));
        console.log(chalk.gray('   Combined demo interface\n'));
        
        console.log(chalk.yellow('💡 Features:'));
        console.log(chalk.gray('   • CORS enabled for API calls'));
        console.log(chalk.gray('   • Proxy to backend services'));
        console.log(chalk.gray('   • Static file serving'));
        console.log(chalk.gray('   • Multiple demo interfaces\n'));
        
        resolve();
      });
    });
  }

  stop() {
    if (this.server) {
      this.server.close();
      console.log(chalk.yellow('Demo server stopped'));
    }
  }
}

// Run if called directly
if (require.main === module) {
  const server = new DemoWebServer();
  server.start().catch(console.error);
  
  // Graceful shutdown
  process.on('SIGINT', () => {
    console.log(chalk.yellow('\nShutting down demo server...'));
    server.stop();
    process.exit(0);
  });
}

module.exports = DemoWebServer;
