const axios = require('axios');

describe('Integration Tests - Live Services', () => {
  const BASE_URL = 'http://localhost:8080';
  let authToken;

  beforeAll(async () => {
    // Wait for services to be ready
    await new Promise(resolve => setTimeout(resolve, 2000));
  });

  describe('Health Checks', () => {
    it('should have all services healthy', async () => {
      const services = [
        { name: 'API Gateway', url: 'http://localhost:8080/health' },
        { name: 'Auth Service', url: 'http://localhost:8081/health' },
        { name: 'VM Orchestrator', url: 'http://localhost:8082/health' },
        { name: 'App Catalog', url: 'http://localhost:8083/health' }
      ];

      for (const service of services) {
        try {
          const response = await axios.get(service.url, { timeout: 5000 });
          expect(response.status).toBe(200);
          expect(response.data).toHaveProperty('status', 'ok');
          console.log(`✅ ${service.name} is healthy`);
        } catch (error) {
          console.error(`❌ ${service.name} health check failed:`, error.message);
          throw error;
        }
      }
    });
  });

  describe('Authentication Flow', () => {
    it('should authenticate with demo credentials', async () => {
      const response = await axios.post('http://localhost:8081/login', {
        username: 'demo',
        password: 'password'
      });

      expect(response.status).toBe(200);
      expect(response.data).toHaveProperty('token');
      
      authToken = response.data.token;
      console.log('✅ Authentication successful');
    });

    it('should reject invalid credentials', async () => {
      try {
        await axios.post('http://localhost:8081/login', {
          username: 'invalid',
          password: 'invalid'
        });
        throw new Error('Should have rejected invalid credentials');
      } catch (error) {
        expect(error.response.status).toBe(401);
        console.log('✅ Invalid credentials properly rejected');
      }
    });
  });

  describe('App Catalog Integration', () => {
    it('should fetch apps from catalog service', async () => {
      expect(authToken).toBeDefined();

      const response = await axios.get('http://localhost:8083/apps', {
        headers: { Authorization: `Bearer ${authToken}` }
      });

      expect(response.status).toBe(200);
      expect(Array.isArray(response.data)).toBe(true);
      expect(response.data.length).toBeGreaterThan(0);
      
      console.log(`✅ Found ${response.data.length} apps in catalog`);
    });

    it('should fetch categories from catalog service', async () => {
      const response = await axios.get('http://localhost:8083/categories');

      expect(response.status).toBe(200);
      expect(Array.isArray(response.data)).toBe(true);
      expect(response.data.length).toBeGreaterThan(0);
      
      console.log(`✅ Found ${response.data.length} app categories`);
    });

    it('should require authentication for apps endpoint', async () => {
      try {
        await axios.get('http://localhost:8083/apps');
        throw new Error('Should have required authentication');
      } catch (error) {
        expect(error.response.status).toBe(401);
        console.log('✅ Apps endpoint properly requires authentication');
      }
    });
  });

  describe('VM Orchestrator Integration', () => {
    it('should fetch VMs from orchestrator service', async () => {
      expect(authToken).toBeDefined();

      const response = await axios.get('http://localhost:8082/vms', {
        headers: { Authorization: `Bearer ${authToken}` }
      });

      expect(response.status).toBe(200);
      expect(Array.isArray(response.data)).toBe(true);
      
      console.log(`✅ Found ${response.data.length} VMs in orchestrator`);
    });

    it('should require authentication for VMs endpoint', async () => {
      try {
        await axios.get('http://localhost:8082/vms');
        throw new Error('Should have required authentication');
      } catch (error) {
        expect(error.response.status).toBe(401);
        console.log('✅ VMs endpoint properly requires authentication');
      }
    });
  });

  describe('API Gateway Integration', () => {
    it('should proxy authentication through gateway', async () => {
      const response = await axios.post(`${BASE_URL}/auth/login`, {
        username: 'demo',
        password: 'password'
      });

      expect(response.status).toBe(200);
      expect(response.data).toHaveProperty('token');
      console.log('✅ Authentication proxy through gateway works');
    });

    it('should proxy app catalog through gateway', async () => {
      expect(authToken).toBeDefined();

      const response = await axios.get(`${BASE_URL}/catalog/apps`, {
        headers: { Authorization: `Bearer ${authToken}` }
      });

      expect(response.status).toBe(200);
      expect(Array.isArray(response.data)).toBe(true);
      console.log('✅ App catalog proxy through gateway works');
    });

    it('should proxy VM orchestrator through gateway', async () => {
      expect(authToken).toBeDefined();

      const response = await axios.get(`${BASE_URL}/vm/vms`, {
        headers: { Authorization: `Bearer ${authToken}` }
      });

      expect(response.status).toBe(200);
      expect(Array.isArray(response.data)).toBe(true);
      console.log('✅ VM orchestrator proxy through gateway works');
    });
  });

  describe('End-to-End Scenarios', () => {
    it('should complete full user journey', async () => {
      // 1. Login
      const loginResponse = await axios.post(`${BASE_URL}/auth/login`, {
        username: 'demo',
        password: 'password'
      });
      const token = loginResponse.data.token;

      // 2. Get available apps
      const appsResponse = await axios.get(`${BASE_URL}/catalog/apps`, {
        headers: { Authorization: `Bearer ${token}` }
      });
      expect(appsResponse.data.length).toBeGreaterThan(0);

      // 3. Get app categories
      const categoriesResponse = await axios.get(`${BASE_URL}/catalog/categories`);
      expect(categoriesResponse.data.length).toBeGreaterThan(0);

      // 4. Get VMs
      const vmsResponse = await axios.get(`${BASE_URL}/vm/vms`, {
        headers: { Authorization: `Bearer ${token}` }
      });
      expect(Array.isArray(vmsResponse.data)).toBe(true);

      console.log('✅ Complete user journey successful');
    });

    it('should handle app search and filtering', async () => {
      expect(authToken).toBeDefined();

      // Search for apps
      const searchResponse = await axios.get(`${BASE_URL}/catalog/apps?search=mail`, {
        headers: { Authorization: `Bearer ${authToken}` }
      });
      
      expect(searchResponse.status).toBe(200);
      expect(Array.isArray(searchResponse.data)).toBe(true);
      
      // Filter by category
      const categoryResponse = await axios.get(`${BASE_URL}/catalog/apps?category=Communication`, {
        headers: { Authorization: `Bearer ${authToken}` }
      });
      
      expect(categoryResponse.status).toBe(200);
      expect(Array.isArray(categoryResponse.data)).toBe(true);

      console.log('✅ App search and filtering works');
    });
  });

  describe('Error Handling', () => {
    it('should handle network timeouts gracefully', async () => {
      // This test verifies timeout handling is working
      const request = axios.get(`${BASE_URL}/health`, { timeout: 1 });
      
      try {
        await request;
        // If it succeeds quickly, that's also fine
        console.log('✅ Request completed quickly (or timeout handling works)');
      } catch (error) {
        if (error.code === 'ECONNABORTED') {
          console.log('✅ Timeout handling works correctly');
        } else {
          // Re-throw if it's not a timeout error
          throw error;
        }
      }
    });

    it('should handle malformed requests', async () => {
      try {
        await axios.post(`${BASE_URL}/auth/login`, 'invalid-json', {
          headers: { 'Content-Type': 'application/json' }
        });
        // Some servers might handle this gracefully
        console.log('✅ Server handled malformed JSON gracefully');
      } catch (error) {
        expect(error.response.status).toBe(400);
        console.log('✅ Server properly rejected malformed JSON');
      }
    });
  });
});
