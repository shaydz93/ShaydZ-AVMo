const express = require('express');
const cors = require('cors');
const app = express();

app.use(cors());
app.use(express.json());

// Health check endpoint
app.get('/health', (req, res) => {
    res.json({ status: 'OK', service: 'app-catalog-debug', timestamp: new Date().toISOString() });
});

// Mock app catalog
const mockApps = [
    {
        id: 'app-1',
        name: 'Microsoft Teams',
        description: 'Enterprise communication platform',
        icon: 'https://example.com/teams.png',
        category: 'Communication',
        version: '1.0.0',
        size: '150MB',
        androidPackage: 'com.microsoft.teams'
    },
    {
        id: 'app-2',
        name: 'Salesforce',
        description: 'Customer relationship management',
        icon: 'https://example.com/salesforce.png',
        category: 'Business',
        version: '2.1.0',
        size: '200MB',
        androidPackage: 'com.salesforce.androidsdk'
    },
    {
        id: 'app-3',
        name: 'Adobe Acrobat',
        description: 'PDF viewer and editor',
        icon: 'https://example.com/acrobat.png',
        category: 'Productivity',
        version: '1.5.0',
        size: '120MB',
        androidPackage: 'com.adobe.reader'
    }
];

// App catalog endpoints
app.get('/api/apps', (req, res) => {
    console.log('DEBUG: App catalog request');
    res.json({
        success: true,
        apps: mockApps,
        total: mockApps.length
    });
});

app.get('/api/apps/:id', (req, res) => {
    const app = mockApps.find(a => a.id === req.params.id);
    if (app) {
        res.json({ success: true, app });
    } else {
        res.status(404).json({ success: false, error: 'App not found' });
    }
});

app.post('/api/apps/:id/install', (req, res) => {
    const app = mockApps.find(a => a.id === req.params.id);
    console.log(`DEBUG: Installing app ${req.params.id}`);
    res.json({
        success: true,
        message: `Installing ${app ? app.name : 'Unknown App'}`,
        installId: `install-${Date.now()}`
    });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, '0.0.0.0', () => {
    console.log(`🚀 App Catalog Debug Service running on port ${PORT}`);
    console.log('✅ Mock app catalog with sample enterprise apps');
});
