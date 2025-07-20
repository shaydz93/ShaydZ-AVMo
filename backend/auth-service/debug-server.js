const express = require('express');
const cors = require('cors');
const app = express();

app.use(cors());
app.use(express.json());

// Health check endpoint
app.get('/health', (req, res) => {
    res.json({ status: 'OK', service: 'auth-debug', timestamp: new Date().toISOString() });
});

// Debug auth endpoints (no real authentication)
app.post('/api/auth/login', (req, res) => {
    console.log('DEBUG: Login request received');
    res.json({
        success: true,
        user: {
            id: 'debug-user-123',
            username: 'debug_user',
            email: 'debug@shaydz.com',
            role: 'admin'
        },
        token: 'debug-jwt-token-123'
    });
});

app.get('/api/auth/me', (req, res) => {
    console.log('DEBUG: User profile request');
    res.json({
        id: 'debug-user-123',
        username: 'debug_user',
        email: 'debug@shaydz.com',
        firstName: 'Debug',
        lastName: 'User',
        role: 'admin',
        isActive: true
    });
});

app.post('/api/auth/logout', (req, res) => {
    console.log('DEBUG: Logout request');
    res.json({ success: true, message: 'Logged out successfully' });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, '0.0.0.0', () => {
    console.log(`🚀 Auth Debug Service running on port ${PORT}`);
    console.log('✅ No authentication required - all requests accepted');
});
