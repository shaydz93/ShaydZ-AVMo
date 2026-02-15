const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');
const jwt = require('jsonwebtoken');
const { MongoClient } = require('mongodb');
require('dotenv').config();

// Import routes
const recommendationsRouter = require('./routes/recommendations');
const chatRouter = require('./routes/chat');
const analyticsRouter = require('./routes/analytics');
const optimizationRouter = require('./routes/optimization');

// Initialize Express app
const app = express();
const PORT = process.env.PORT || 8085;

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json());
app.use(morgan('combined'));

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100 // limit each IP to 100 requests per windowMs
});
app.use(limiter);

// SECURITY: JWT_SECRET must be set via environment variable - no hardcoded defaults
if (!process.env.JWT_SECRET) {
  throw new Error('JWT_SECRET environment variable is required. Set a strong secret key.');
}

// Authentication middleware - validates JWT tokens
const authenticateJWT = (req, res, next) => {
  const authHeader = req.headers.authorization;

  if (authHeader) {
    const token = authHeader.split(' ')[1];

    jwt.verify(token, process.env.JWT_SECRET, (err, user) => {
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

// Optional auth middleware for public endpoints
const optionalAuth = (req, res, next) => {
  const authHeader = req.headers.authorization;

  if (authHeader) {
    const token = authHeader.split(' ')[1];
    jwt.verify(token, process.env.JWT_SECRET, (err, user) => {
      if (!err) {
        req.user = user;
      }
    });
  }
  next();
};

// SECURITY: DB_CONNECTION_STRING must be set via environment variable - no hardcoded defaults
if (!process.env.DB_CONNECTION_STRING) {
  throw new Error('DB_CONNECTION_STRING environment variable is required. Example: mongodb://mongo:27017/ai_service');
}

// MongoDB connection
let db;
MongoClient.connect(process.env.DB_CONNECTION_STRING)
  .then(client => {
    console.log('Connected to MongoDB');
    db = client.db();
    app.locals.db = db;
  })
  .catch(error => {
    console.error('MongoDB connection error:', error);
    process.exit(1);
  });

// Public routes
app.get('/health', (req, res) => {
  res.status(200).json({ 
    status: 'UP', 
    service: 'AI Service',
    timestamp: new Date(),
    version: '1.0.0'
  });
});

// AI Service routes
app.use('/recommendations', optionalAuth, recommendationsRouter);
app.use('/chat', authenticateJWT, chatRouter);
app.use('/analytics', authenticateJWT, analyticsRouter);
app.use('/optimization', authenticateJWT, optimizationRouter);

// Error handling
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({
    error: 'Internal Server Error',
    message: process.env.NODE_ENV === 'development' ? err.message : undefined
  });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({
    error: 'Not Found',
    message: 'AI Service endpoint not found'
  });
});

// Start the server
app.listen(PORT, () => {
  console.log(`AI Service running on port ${PORT}`);
});

module.exports = app;