const express = require('express');
const cors = require('cors');
const jwt = require('jsonwebtoken');
const { MongoClient, ObjectId } = require('mongodb');
const { v4: uuidv4 } = require('uuid');

// Initialize Express app
const app = express();
const PORT = process.env.PORT || 8083;

// MongoDB setup
const mongoUri = process.env.MONGO_URI || 'mongodb://localhost:27017/apps';
let db;

// Connect to MongoDB
async function connectToMongo() {
  try {
    const client = await MongoClient.connect(mongoUri);
    db = client.db();
    console.log('Connected to MongoDB');
    
    // Create indexes
    await db.collection('apps').createIndex({ name: 1 });
    await db.collection('apps').createIndex({ category: 1 });
    
    // Create demo apps if none exist
    const appCount = await db.collection('apps').countDocuments();
    if (appCount === 0) {
      const demoApps = [
        {
          id: uuidv4(),
          name: "Secure Mail",
          packageName: "com.shaydz.avmo.securemail",
          description: "Enterprise email client with encryption",
          version: "1.2.1",
          versionCode: 121,
          iconUrl: "https://example.com/icons/secure-mail.png",
          category: "Communication",
          developer: "ShaydZ Inc.",
          size: 15000000, // 15MB
          isSystem: false,
          isApproved: true,
          uploadedAt: new Date().toISOString(),
          lastUpdated: new Date().toISOString()
        },
        {
          id: uuidv4(),
          name: "SecureDocs",
          packageName: "com.shaydz.avmo.securedocs",
          description: "Document editor with DRM protection",
          version: "2.0.0",
          versionCode: 200,
          iconUrl: "https://example.com/icons/secure-docs.png",
          category: "Productivity",
          developer: "ShaydZ Inc.",
          size: 25000000, // 25MB
          isSystem: false,
          isApproved: true,
          uploadedAt: new Date().toISOString(),
          lastUpdated: new Date().toISOString()
        },
        {
          id: uuidv4(),
          name: "Cloud Files",
          packageName: "com.shaydz.avmo.cloudfiles",
          description: "Access corporate files securely",
          version: "1.5.0",
          versionCode: 150,
          iconUrl: "https://example.com/icons/cloud-files.png",
          category: "Productivity",
          developer: "ShaydZ Inc.",
          size: 18000000, // 18MB
          isSystem: false,
          isApproved: true,
          uploadedAt: new Date().toISOString(),
          lastUpdated: new Date().toISOString()
        },
        {
          id: uuidv4(),
          name: "Secure Browser",
          packageName: "com.shaydz.avmo.securebrowser",
          description: "Protected web browsing with policy enforcement",
          version: "3.1.2",
          versionCode: 312,
          iconUrl: "https://example.com/icons/secure-browser.png",
          category: "Communication",
          developer: "ShaydZ Inc.",
          size: 30000000, // 30MB
          isSystem: false,
          isApproved: true,
          uploadedAt: new Date().toISOString(),
          lastUpdated: new Date().toISOString()
        },
        {
          id: uuidv4(),
          name: "Work Chat",
          packageName: "com.shaydz.avmo.workchat",
          description: "Encrypted team messaging platform",
          version: "2.2.0",
          versionCode: 220,
          iconUrl: "https://example.com/icons/work-chat.png",
          category: "Communication",
          developer: "ShaydZ Inc.",
          size: 22000000, // 22MB
          isSystem: false,
          isApproved: true,
          uploadedAt: new Date().toISOString(),
          lastUpdated: new Date().toISOString()
        },
        {
          id: uuidv4(),
          name: "HR Portal",
          packageName: "com.shaydz.avmo.hrportal",
          description: "Access company HR resources",
          version: "1.0.5",
          versionCode: 105,
          iconUrl: "https://example.com/icons/hr-portal.png",
          category: "Human Resources",
          developer: "ShaydZ Inc.",
          size: 12000000, // 12MB
          isSystem: false,
          isApproved: true,
          uploadedAt: new Date().toISOString(),
          lastUpdated: new Date().toISOString()
        },
        {
          id: uuidv4(),
          name: "Expense Report",
          packageName: "com.shaydz.avmo.expense",
          description: "Submit and track expenses",
          version: "1.3.2",
          versionCode: 132,
          iconUrl: "https://example.com/icons/expense-report.png",
          category: "Finance",
          developer: "ShaydZ Inc.",
          size: 16000000, // 16MB
          isSystem: false,
          isApproved: true,
          uploadedAt: new Date().toISOString(),
          lastUpdated: new Date().toISOString()
        },
        {
          id: uuidv4(),
          name: "VPN Client",
          packageName: "com.shaydz.avmo.vpnclient",
          description: "Connect to corporate network",
          version: "2.4.0",
          versionCode: 240,
          iconUrl: "https://example.com/icons/vpn-client.png",
          category: "Security",
          developer: "ShaydZ Inc.",
          size: 8000000, // 8MB
          isSystem: false,
          isApproved: true,
          uploadedAt: new Date().toISOString(),
          lastUpdated: new Date().toISOString()
        },
        {
          id: uuidv4(),
          name: "Calendar",
          packageName: "com.shaydz.avmo.calendar",
          description: "Secure scheduling application",
          version: "1.1.1",
          versionCode: 111,
          iconUrl: "https://example.com/icons/calendar.png",
          category: "Productivity",
          developer: "ShaydZ Inc.",
          size: 14000000, // 14MB
          isSystem: false,
          isApproved: true,
          uploadedAt: new Date().toISOString(),
          lastUpdated: new Date().toISOString()
        },
        {
          id: uuidv4(),
          name: "CRM",
          packageName: "com.shaydz.avmo.crm",
          description: "Customer relationship management",
          version: "3.0.0",
          versionCode: 300,
          iconUrl: "https://example.com/icons/crm.png",
          category: "Finance",
          developer: "ShaydZ Inc.",
          size: 35000000, // 35MB
          isSystem: false,
          isApproved: true,
          uploadedAt: new Date().toISOString(),
          lastUpdated: new Date().toISOString()
        },
        {
          id: uuidv4(),
          name: "Analytics Dashboard",
          packageName: "com.shaydz.avmo.analytics",
          description: "Business intelligence reports",
          version: "2.1.0",
          versionCode: 210,
          iconUrl: "https://example.com/icons/analytics.png",
          category: "Finance",
          developer: "ShaydZ Inc.",
          size: 28000000, // 28MB
          isSystem: false,
          isApproved: true,
          uploadedAt: new Date().toISOString(),
          lastUpdated: new Date().toISOString()
        },
        {
          id: uuidv4(),
          name: "Project Management",
          packageName: "com.shaydz.avmo.projectmanagement",
          description: "Track projects and tasks",
          version: "1.4.2",
          versionCode: 142,
          iconUrl: "https://example.com/icons/project-management.png",
          category: "Productivity",
          developer: "ShaydZ Inc.",
          size: 20000000, // 20MB
          isSystem: false,
          isApproved: true,
          uploadedAt: new Date().toISOString(),
          lastUpdated: new Date().toISOString()
        }
      ];
      
      await db.collection('apps').insertMany(demoApps);
      console.log('Demo apps created');
    }
  } catch (err) {
    console.error('Failed to connect to MongoDB', err);
    process.exit(1);
  }
}

// Authenticate middleware
const authenticate = (req, res, next) => {
  // Skip auth for health endpoint
  if (req.path === '/health' || req.path === '/categories') {
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

// Middleware
app.use(cors());
app.use(express.json());
app.use(authenticate);

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok', service: 'app-catalog' });
});

// Get all apps endpoint
app.get('/apps', async (req, res) => {
  try {
    const { category, search } = req.query;
    const query = {};
    
    // Apply filters
    if (category) {
      query.category = category;
    }
    
    if (search) {
      query.$or = [
        { name: { $regex: search, $options: 'i' } },
        { description: { $regex: search, $options: 'i' } }
      ];
    }
    
    // Get apps from DB
    const apps = await db.collection('apps')
      .find(query)
      .sort({ name: 1 })
      .toArray();
    
    res.json(apps);
  } catch (err) {
    console.error('Error getting apps:', err);
    res.status(500).json({ message: 'Internal server error' });
  }
});

// Get specific app endpoint
app.get('/apps/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    // Get app from DB
    const app = await db.collection('apps').findOne({ id });
    
    if (!app) {
      return res.status(404).json({ message: 'App not found' });
    }
    
    res.json(app);
  } catch (err) {
    console.error('Error getting app:', err);
    res.status(500).json({ message: 'Internal server error' });
  }
});

// Get app categories endpoint
app.get('/categories', async (req, res) => {
  try {
    // Get distinct categories
    const categories = await db.collection('apps').distinct('category');
    res.json(categories);
  } catch (err) {
    console.error('Error getting categories:', err);
    res.status(500).json({ message: 'Internal server error' });
  }
});

// Launch app endpoint
app.post('/apps/:id/launch', async (req, res) => {
  try {
    const { id } = req.params;
    
    // Check if app exists
    const app = await db.collection('apps').findOne({ id });
    
    if (!app) {
      return res.status(404).json({ message: 'App not found' });
    }
    
    // In a real implementation, this would communicate with the VM service
    // to launch the app in the virtual environment
    
    res.json({ success: true });
  } catch (err) {
    console.error('Error launching app:', err);
    res.status(500).json({ message: 'Internal server error' });
  }
});

// Start server after connecting to MongoDB
connectToMongo().then(() => {
  app.listen(PORT, () => {
    console.log(`App Catalog Service running on port ${PORT}`);
  });
});
