const express = require('express');
const { createProxyMiddleware } = require('http-proxy-middleware');
const morgan = require('morgan');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const jwt = require('jsonwebtoken');
const cors = require('cors');
require('dotenv').config();

// Initialize Express app
const app = express();
const PORT = process.env.PORT || 8080;

// Middleware
app.use(helmet()); // Security headers
app.use(cors());
app.use(express.json());
app.use(morgan('combined')); // Logging

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100 // limit each IP to 100 requests per windowMs
});
app.use(limiter);

// Authentication middleware
const authenticateJWT = (req, res, next) => {
  const authHeader = req.headers.authorization;

  if (authHeader) {
    const token = authHeader.split(' ')[1];

    jwt.verify(token, process.env.JWT_SECRET || 'your_jwt_secret_key_here', (err, user) => {
      if (err) {
        return res.sendStatus(403);
      }

      req.user = user;
      next();
    });
  } else {
    res.sendStatus(401);
  }
};

// Public routes
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'UP', timestamp: new Date() });
});

// Auth service proxy - public endpoints
app.use('/api/auth', createProxyMiddleware({ 
  target: process.env.AUTH_SERVICE_URL || 'http://localhost:8081',
  changeOrigin: true,
  pathRewrite: {
    '^/api/auth': '/', 
  },
}));

// Protected routes below
// VM Orchestrator service proxy
app.use('/api/vm', authenticateJWT, createProxyMiddleware({ 
  target: process.env.VM_ORCHESTRATOR_URL || 'http://localhost:8082',
  changeOrigin: true,
  pathRewrite: {
    '^/api/vm': '/', 
  },
}));

// App catalog service proxy
app.use('/api/apps', authenticateJWT, createProxyMiddleware({ 
  target: process.env.APP_CATALOG_URL || 'http://localhost:8083',
  changeOrigin: true,
  pathRewrite: {
    '^/api/apps': '/', 
  },
}));

// Error handling
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({
    error: 'Internal Server Error',
    message: process.env.NODE_ENV === 'development' ? err.message : undefined
  });
});

// Start the server
app.listen(PORT, () => {
  console.log(`API Gateway running on port ${PORT}`);
});

module.exports = app;
