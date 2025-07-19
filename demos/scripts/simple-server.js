#!/usr/bin/env node

const express = require('express');
const path = require('path');
const chalk = require('chalk');

class SimpleServer {
  constructor() {
    this.app = express();
    this.port = 3000;
    this.demoPath = path.join(__dirname, '..', 'web-demos');
  }

  setupMiddleware() {
    // Serve static files
    this.app.use(express.static(this.demoPath));
    
    // CORS headers
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

    // Health check
    this.app.get('/health', (req, res) => {
      res.json({ status: 'ok', timestamp: new Date().toISOString() });
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
        
        console.log(chalk.blue('🔗 Backend Demo:'));
        console.log(chalk.cyan(`   http://localhost:${this.port}/backend`));
        console.log(chalk.gray('   Live backend integration\n'));
        
        console.log(chalk.blue('🏠 Main Demo:'));
        console.log(chalk.cyan(`   http://localhost:${this.port}/`));
        console.log(chalk.gray('   iOS app simulator\n'));
        
        console.log(chalk.yellow('Server running on port 3000'));
        console.log(chalk.gray('Press Ctrl+C to stop\n'));
        
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
  const server = new SimpleServer();
  server.start().catch(console.error);
  
  // Graceful shutdown
  process.on('SIGINT', () => {
    console.log(chalk.yellow('\nShutting down demo server...'));
    server.stop();
    process.exit(0);
  });
}

module.exports = SimpleServer;
