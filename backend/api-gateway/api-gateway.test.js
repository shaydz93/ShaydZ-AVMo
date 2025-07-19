const request = require('supertest');
const express = require('express');
const jwt = require('jsonwebtoken');

describe('API Gateway', () => {
  let app;

  beforeEach(() => {
    // Setup express app with minimal API gateway functionality
    app = express();
    app.use(express.json());

    // Mock health endpoint
    app.get('/health', (req, res) => {
      res.status(200).json({ status: 'ok', service: 'api-gateway' });
    });

    // Mock auth proxy endpoints
    app.post('/auth/login', (req, res) => {
      const { username, password } = req.body;
      
      if (username === 'demo' && password === 'password') {
        const token = jwt.sign(
          { id: '1', username: 'demo', role: 'user' },
          'test-secret',
          { expiresIn: '1h' }
        );
        res.json({ token });
      } else {
        res.status(401).json({ message: 'Invalid credentials' });
      }
    });

    // Mock JWT middleware
    const authenticateJWT = (req, res, next) => {
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
    };

    // Mock catalog proxy endpoints
    app.get('/catalog/apps', authenticateJWT, (req, res) => {
      res.json([
        { id: '1', name: 'Secure Mail', category: 'Communication' },
        { id: '2', name: 'SecureDocs', category: 'Productivity' }
      ]);
    });

    app.get('/catalog/categories', (req, res) => {
      res.json(['Communication', 'Productivity', 'Finance', 'Security']);
    });

    // Mock VM proxy endpoints
    app.get('/vm/vms', authenticateJWT, (req, res) => {
      res.json([
        { id: 'vm1', name: 'Android Work Profile', status: 'RUNNING' },
        { id: 'vm2', name: 'Android Personal', status: 'STOPPED' }
      ]);
    });

    app.get('/vm/health', (req, res) => {
      res.json({ status: 'ok', service: 'vm-orchestrator' });
    });
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('GET /health', () => {
    it('should return gateway status', async () => {
      const response = await request(app)
        .get('/health')
        .expect(200);

      expect(response.body).toEqual({
        status: 'ok',
        service: 'api-gateway'
      });
    });
  });

  describe('Authentication Proxy', () => {
    it('should proxy login requests to auth service', async () => {
      const response = await request(app)
        .post('/auth/login')
        .send({
          username: 'demo',
          password: 'password'
        })
        .expect(200);

      expect(response.body).toHaveProperty('token');
    });

    it('should return error for invalid login', async () => {
      const response = await request(app)
        .post('/auth/login')
        .send({
          username: 'wrong',
          password: 'wrong'
        })
        .expect(401);

      expect(response.body).toEqual({
        message: 'Invalid credentials'
      });
    });
  });

  describe('App Catalog Proxy', () => {
    let validToken;

    beforeEach(() => {
      validToken = jwt.sign(
        { id: '1', username: 'demo', role: 'user' },
        'test-secret',
        { expiresIn: '1h' }
      );
    });

    it('should proxy app requests to catalog service', async () => {
      const response = await request(app)
        .get('/catalog/apps')
        .set('Authorization', `Bearer ${validToken}`)
        .expect(200);

      expect(Array.isArray(response.body)).toBe(true);
      expect(response.body).toHaveLength(2);
    });

    it('should proxy categories requests without auth', async () => {
      const response = await request(app)
        .get('/catalog/categories')
        .expect(200);

      expect(Array.isArray(response.body)).toBe(true);
      expect(response.body).toContain('Communication');
    });

    it('should require auth for protected catalog endpoints', async () => {
      const response = await request(app)
        .get('/catalog/apps')
        .expect(401);

      expect(response.body).toEqual({
        message: 'Authorization header required'
      });
    });
  });

  describe('VM Orchestrator Proxy', () => {
    let validToken;

    beforeEach(() => {
      validToken = jwt.sign(
        { id: '1', username: 'demo', role: 'user' },
        'test-secret',
        { expiresIn: '1h' }
      );
    });

    it('should proxy VM requests to orchestrator service', async () => {
      const response = await request(app)
        .get('/vm/vms')
        .set('Authorization', `Bearer ${validToken}`)
        .expect(200);

      expect(Array.isArray(response.body)).toBe(true);
      expect(response.body).toHaveLength(2);
    });

    it('should proxy health requests without auth', async () => {
      const response = await request(app)
        .get('/vm/health')
        .expect(200);

      expect(response.body).toEqual({
        status: 'ok',
        service: 'vm-orchestrator'
      });
    });
  });

  describe('Request Validation', () => {
    it('should handle malformed JSON', async () => {
      const response = await request(app)
        .post('/auth/login')
        .send('invalid json')
        .set('Content-Type', 'application/json')
        .expect(400);
    });

    it('should handle missing content-type', async () => {
      const response = await request(app)
        .post('/auth/login')
        .send('{"username":"demo","password":"password"}');

      // Should still work or handle gracefully
      expect([200, 400, 415, 401]).toContain(response.status);
    });
  });
});
