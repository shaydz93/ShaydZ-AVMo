const express = require('express');
const cors = require('cors');
const { createProxyMiddleware } = require('http-proxy-middleware');
const jwt = require('jsonwebtoken');
const morgan = require('morgan');

// Initialize Express app
const app = express();
const PORT = process.env.PORT || 8080;

// Enable request logging
app.use(morgan('combined'));

// Middleware
app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok', service: 'api-gateway' });
});

// API version info
app.get('/version', (req, res) => {
  res.status(200).json({ 
    version: '1.0.0', 
    name: 'ShaydZ AVMo API Gateway',
    environment: process.env.NODE_ENV || 'development'
  });
});

// Authentication middleware
const authenticateJWT = (req, res, next) => {
  // Skip auth for health, version, login and register endpoints
  if (req.path === '/health' || req.path === '/version') {
    return next();
  }
  
  // Skip auth for login and register routes
  if (req.originalUrl.includes('/auth/login') || req.originalUrl.includes('/auth/register')) {
    console.log('Skipping auth for:', req.originalUrl);
    return next();
  }

  const authHeader = req.headers.authorization;
  if (!authHeader) {
    return res.status(401).json({ message: 'Authorization header required' });
  }

  const token = authHeader.split(' ')[1];
  if (!token) {
    return res.status(401).json({ message: 'Bearer token required' });
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.user = decoded;
    next();
  } catch (err) {
    return res.status(403).json({ message: 'Invalid or expired token' });
  }
};

// Apply auth middleware
app.use(authenticateJWT);

// Auth service proxy
app.use('/auth', (req, res, next) => {
  console.log(`Auth service proxy - Request: ${req.method} ${req.originalUrl}`);
  next();
}, createProxyMiddleware({
  target: process.env.AUTH_SERVICE_URL || 'http://localhost:8081',
  changeOrigin: true,
  pathRewrite: {
    '^/auth': '/'
  },
  logLevel: 'debug',
  onProxyReq: (proxyReq, req, res) => {
    console.log(`Proxying ${req.method} ${req.originalUrl} to auth service`);
    if (req.body) {
      console.log('Request body:', req.body);
    }
  },
  onProxyRes: (proxyRes, req, res) => {
    console.log(`Received response from auth service for ${req.method} ${req.originalUrl} with status ${proxyRes.statusCode}`);
  },
  onError: (err, req, res) => {
    console.error('Proxy error:', err);
    res.status(500).json({ message: 'Auth service error', error: err.message });
  }
}));

// VM orchestrator service proxy
app.use('/vm', createProxyMiddleware({
  target: process.env.VM_ORCHESTRATOR_URL || 'http://localhost:8082',
  changeOrigin: true,
  pathRewrite: {
    '^/vm': '/'
  }
}));

// App catalog service proxy
app.use('/catalog', createProxyMiddleware({
  target: process.env.APP_CATALOG_URL || 'http://localhost:8083',
  changeOrigin: true,
  pathRewrite: {
    '^/catalog': '/'
  }
}));

// Start server
app.listen(PORT, () => {
  console.log(`API Gateway running on port ${PORT}`);
});
