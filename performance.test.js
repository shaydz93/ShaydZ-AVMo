const axios = require('axios');

describe('Performance Tests', () => {
  let authToken;

  beforeAll(async () => {
    // Get auth token
    const response = await axios.post('http://localhost:8081/login', {
      username: 'demo',
      password: 'password'
    });
    authToken = response.data.token;
  });

  describe('Response Time Tests', () => {
    it('should respond to health checks quickly', async () => {
      const start = Date.now();
      await axios.get('http://localhost:8081/health');
      const duration = Date.now() - start;
      
      expect(duration).toBeLessThan(1000); // Less than 1 second
      console.log(`✅ Health check responded in ${duration}ms`);
    });

    it('should authenticate quickly', async () => {
      const start = Date.now();
      await axios.post('http://localhost:8081/login', {
        username: 'demo',
        password: 'password'
      });
      const duration = Date.now() - start;
      
      expect(duration).toBeLessThan(2000); // Less than 2 seconds
      console.log(`✅ Authentication completed in ${duration}ms`);
    });

    it('should fetch apps quickly', async () => {
      const start = Date.now();
      await axios.get('http://localhost:8083/apps', {
        headers: { Authorization: `Bearer ${authToken}` }
      });
      const duration = Date.now() - start;
      
      expect(duration).toBeLessThan(1500); // Less than 1.5 seconds
      console.log(`✅ Apps fetch completed in ${duration}ms`);
    });
  });

  describe('Load Tests', () => {
    it('should handle multiple concurrent requests', async () => {
      const concurrentRequests = 5;
      const requests = Array(concurrentRequests).fill().map(() =>
        axios.get('http://localhost:8083/health')
      );

      const start = Date.now();
      const responses = await Promise.all(requests);
      const duration = Date.now() - start;

      responses.forEach(response => {
        expect(response.status).toBe(200);
      });

      console.log(`✅ ${concurrentRequests} concurrent requests completed in ${duration}ms`);
    });

    it('should handle multiple auth requests', async () => {
      const concurrentAuths = 3;
      const requests = Array(concurrentAuths).fill().map(() =>
        axios.post('http://localhost:8081/login', {
          username: 'demo',
          password: 'password'
        })
      );

      const start = Date.now();
      const responses = await Promise.all(requests);
      const duration = Date.now() - start;

      responses.forEach(response => {
        expect(response.status).toBe(200);
        expect(response.data).toHaveProperty('token');
      });

      console.log(`✅ ${concurrentAuths} concurrent authentications completed in ${duration}ms`);
    });
  });

  describe('Data Consistency Tests', () => {
    it('should return consistent app data', async () => {
      const response1 = await axios.get('http://localhost:8083/apps', {
        headers: { Authorization: `Bearer ${authToken}` }
      });
      
      const response2 = await axios.get('http://localhost:8083/apps', {
        headers: { Authorization: `Bearer ${authToken}` }
      });

      expect(response1.data).toEqual(response2.data);
      console.log('✅ App data is consistent across requests');
    });

    it('should return consistent VM data', async () => {
      const response1 = await axios.get('http://localhost:8082/vms', {
        headers: { Authorization: `Bearer ${authToken}` }
      });
      
      const response2 = await axios.get('http://localhost:8082/vms', {
        headers: { Authorization: `Bearer ${authToken}` }
      });

      expect(response1.data).toEqual(response2.data);
      console.log('✅ VM data is consistent across requests');
    });
  });
});
