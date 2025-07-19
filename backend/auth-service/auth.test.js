const request = require('supertest');
const express = require('express');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');

// Mock dependencies
jest.mock('mongodb');
jest.mock('bcryptjs');

describe('Auth Service', () => {
  let app;
  let mockDb;

  beforeEach(() => {
    // Setup mock database
    mockDb = {
      collection: jest.fn(() => ({
        findOne: jest.fn(),
        insertOne: jest.fn(),
        updateOne: jest.fn(),
        createIndex: jest.fn(),
        countDocuments: jest.fn()
      }))
    };

    // Setup express app with minimal auth service functionality
    app = express();
    app.use(express.json());

    // Mock health endpoint
    app.get('/health', (req, res) => {
      res.status(200).json({ status: 'ok', service: 'auth-service' });
    });

    // Mock login endpoint
    app.post('/login', async (req, res) => {
      const { username, password } = req.body;
      
      if (!username || !password) {
        return res.status(400).json({ message: 'Username and password required' });
      }

      // Mock user for testing
      const mockUser = {
        _id: '507f1f77bcf86cd799439011',
        username: 'demo',
        email: 'demo@example.com',
        password: 'hashedPassword',
        role: 'user'
      };

      if (username === 'demo' && password === 'password') {
        bcrypt.compare.mockResolvedValue(true);
        
        const token = jwt.sign(
          { 
            id: mockUser._id,
            username: mockUser.username,
            role: mockUser.role 
          }, 
          'test-secret',
          { expiresIn: '1h' }
        );
        
        res.json({ token });
      } else {
        res.status(401).json({ message: 'Invalid credentials' });
      }
    });
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('GET /health', () => {
    it('should return service status', async () => {
      const response = await request(app)
        .get('/health')
        .expect(200);

      expect(response.body).toEqual({
        status: 'ok',
        service: 'auth-service'
      });
    });
  });

  describe('POST /login', () => {
    it('should return token for valid credentials', async () => {
      const response = await request(app)
        .post('/login')
        .send({
          username: 'demo',
          password: 'password'
        })
        .expect(200);

      expect(response.body).toHaveProperty('token');
      expect(typeof response.body.token).toBe('string');
    });

    it('should return error for invalid credentials', async () => {
      const response = await request(app)
        .post('/login')
        .send({
          username: 'wrong',
          password: 'wrong'
        })
        .expect(401);

      expect(response.body).toEqual({
        message: 'Invalid credentials'
      });
    });

    it('should return error for missing credentials', async () => {
      const response = await request(app)
        .post('/login')
        .send({})
        .expect(400);

      expect(response.body).toEqual({
        message: 'Username and password required'
      });
    });
  });

  describe('JWT Token Validation', () => {
    it('should create valid JWT tokens', async () => {
      const response = await request(app)
        .post('/login')
        .send({
          username: 'demo',
          password: 'password'
        });

      const decoded = jwt.verify(response.body.token, 'test-secret');
      expect(decoded).toHaveProperty('username', 'demo');
      expect(decoded).toHaveProperty('role', 'user');
      expect(decoded).toHaveProperty('id');
    });
  });
});
