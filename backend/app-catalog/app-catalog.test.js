const request = require('supertest');
const express = require('express');
const jwt = require('jsonwebtoken');

// Mock dependencies
jest.mock('mongodb');

describe('App Catalog Service', () => {
  let app;
  let mockDb;

  beforeEach(() => {
    // Setup mock database
    mockDb = {
      collection: jest.fn(() => ({
        find: jest.fn(() => ({
          sort: jest.fn(() => ({
            toArray: jest.fn()
          }))
        })),
        findOne: jest.fn(),
        insertOne: jest.fn(),
        insertMany: jest.fn(),
        updateOne: jest.fn(),
        deleteOne: jest.fn(),
        distinct: jest.fn(),
        createIndex: jest.fn(),
        countDocuments: jest.fn()
      }))
    };

    // Setup express app with minimal app catalog functionality
    app = express();
    app.use(express.json());

    // Mock auth middleware
    app.use((req, res, next) => {
      if (req.path === '/health' || req.path === '/categories') {
        return next();
      }
      
      const authHeader = req.headers.authorization;
      if (!authHeader) {
        return res.status(401).json({ message: 'Authorization header required' });
      }
      
      const token = authHeader.split(' ')[1];
      try {
        const decoded = jwt.verify(token, 'test-secret');
        req.user = decoded;
        next();
      } catch (err) {
        return res.status(403).json({ message: 'Invalid or expired token' });
      }
    });

    // Mock health endpoint
    app.get('/health', (req, res) => {
      res.status(200).json({ status: 'ok', service: 'app-catalog' });
    });

    // Mock apps endpoint
    app.get('/apps', async (req, res) => {
      const mockApps = [
        {
          id: '1',
          name: 'Secure Mail',
          packageName: 'com.shaydz.avmo.securemail',
          description: 'Enterprise email client with encryption',
          version: '1.2.1',
          category: 'Communication',
          developer: 'ShaydZ Inc.',
          size: 15000000,
          isApproved: true
        },
        {
          id: '2',
          name: 'SecureDocs',
          packageName: 'com.shaydz.avmo.securedocs',
          description: 'Document editor with DRM protection',
          version: '2.0.0',
          category: 'Productivity',
          developer: 'ShaydZ Inc.',
          size: 25000000,
          isApproved: true
        }
      ];

      const { category, search } = req.query;
      let filteredApps = mockApps;

      if (category) {
        filteredApps = filteredApps.filter(app => app.category === category);
      }

      if (search) {
        filteredApps = filteredApps.filter(app => 
          app.name.toLowerCase().includes(search.toLowerCase()) ||
          app.description.toLowerCase().includes(search.toLowerCase())
        );
      }

      res.json(filteredApps);
    });

    // Mock app by ID endpoint
    app.get('/apps/:id', async (req, res) => {
      const { id } = req.params;
      
      if (id === '1') {
        res.json({
          id: '1',
          name: 'Secure Mail',
          packageName: 'com.shaydz.avmo.securemail',
          description: 'Enterprise email client with encryption',
          version: '1.2.1',
          category: 'Communication',
          developer: 'ShaydZ Inc.',
          size: 15000000,
          isApproved: true
        });
      } else {
        res.status(404).json({ message: 'App not found' });
      }
    });

    // Mock categories endpoint
    app.get('/categories', async (req, res) => {
      const mockCategories = ['Communication', 'Productivity', 'Finance', 'Security'];
      res.json(mockCategories);
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
        service: 'app-catalog'
      });
    });
  });

  describe('GET /apps', () => {
    const validToken = jwt.sign(
      { id: '1', username: 'demo', role: 'user' },
      'test-secret',
      { expiresIn: '1h' }
    );

    it('should return apps list for authenticated user', async () => {
      const response = await request(app)
        .get('/apps')
        .set('Authorization', `Bearer ${validToken}`)
        .expect(200);

      expect(Array.isArray(response.body)).toBe(true);
      expect(response.body).toHaveLength(2);
      expect(response.body[0]).toHaveProperty('name', 'Secure Mail');
    });

    it('should filter apps by category', async () => {
      const response = await request(app)
        .get('/apps?category=Communication')
        .set('Authorization', `Bearer ${validToken}`)
        .expect(200);

      expect(response.body).toHaveLength(1);
      expect(response.body[0]).toHaveProperty('category', 'Communication');
    });

    it('should filter apps by search term', async () => {
      const response = await request(app)
        .get('/apps?search=mail')
        .set('Authorization', `Bearer ${validToken}`)
        .expect(200);

      expect(response.body).toHaveLength(1);
      expect(response.body[0]).toHaveProperty('name', 'Secure Mail');
    });

    it('should require authentication', async () => {
      const response = await request(app)
        .get('/apps')
        .expect(401);

      expect(response.body).toEqual({
        message: 'Authorization header required'
      });
    });
  });

  describe('GET /apps/:id', () => {
    const validToken = jwt.sign(
      { id: '1', username: 'demo', role: 'user' },
      'test-secret',
      { expiresIn: '1h' }
    );

    it('should return specific app by ID', async () => {
      const response = await request(app)
        .get('/apps/1')
        .set('Authorization', `Bearer ${validToken}`)
        .expect(200);

      expect(response.body).toHaveProperty('id', '1');
      expect(response.body).toHaveProperty('name', 'Secure Mail');
    });

    it('should return 404 for non-existent app', async () => {
      const response = await request(app)
        .get('/apps/999')
        .set('Authorization', `Bearer ${validToken}`)
        .expect(404);

      expect(response.body).toEqual({
        message: 'App not found'
      });
    });
  });

  describe('GET /categories', () => {
    it('should return app categories without authentication', async () => {
      const response = await request(app)
        .get('/categories')
        .expect(200);

      expect(Array.isArray(response.body)).toBe(true);
      expect(response.body).toContain('Communication');
      expect(response.body).toContain('Productivity');
    });
  });
});
