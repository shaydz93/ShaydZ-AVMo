const express = require('express');
const mongoose = require('mongoose');
const jwt = require('jsonwebtoken');
const morgan = require('morgan');
const cors = require('cors');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
require('dotenv').config();

// Initialize Express app
const app = express();
const PORT = process.env.PORT || 8083;

// Middleware
app.use(cors());
app.use(express.json());
app.use(morgan('combined')); // Logging

// Connect to MongoDB
mongoose.connect(process.env.DB_CONNECTION_STRING || 'mongodb://localhost:27017/apps')
  .then(() => console.log('MongoDB connected'))
  .catch(err => console.log('MongoDB connection error:', err));

// Configure multer for app package uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const uploadDir = path.join(__dirname, 'uploads');
    if (!fs.existsSync(uploadDir)) {
      fs.mkdirSync(uploadDir, { recursive: true });
    }
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    cb(null, `${Date.now()}-${file.originalname}`);
  }
});

const upload = multer({ 
  storage: storage,
  fileFilter: (req, file, cb) => {
    if (file.mimetype === 'application/vnd.android.package-archive') {
      cb(null, true);
    } else {
      cb(new Error('Only APK files are allowed'), false);
    }
  },
  limits: {
    fileSize: 100 * 1024 * 1024 // 100MB limit
  }
});

// App Schema
const appSchema = new mongoose.Schema({
  name: { type: String, required: true },
  packageName: { type: String, required: true, unique: true },
  description: { type: String, required: true },
  version: { type: String, required: true },
  versionCode: { type: Number, required: true },
  iconUrl: String,
  category: String,
  developer: String,
  size: Number,
  isSystem: { type: Boolean, default: false },
  isApproved: { type: Boolean, default: false },
  apkFilePath: String,
  uploadedBy: String,
  uploadedAt: { type: Date, default: Date.now },
  lastUpdated: { type: Date, default: Date.now }
});

const App = mongoose.model('App', appSchema);

// JWT authentication middleware
const authenticateJWT = (req, res, next) => {
  const authHeader = req.headers.authorization;

  if (authHeader) {
    const token = authHeader.split(' ')[1];

    jwt.verify(token, process.env.JWT_SECRET || 'your_jwt_secret_key_here', (err, user) => {
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

// Role-based authorization middleware
const authorizeAdmin = (req, res, next) => {
  if (req.user && req.user.role === 'admin') {
    next();
  } else {
    res.status(403).json({ message: 'Admin privileges required' });
  }
};

// Health check
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'UP', timestamp: new Date() });
});

// List all apps (with optional filtering)
app.get('/apps', authenticateJWT, async (req, res) => {
  try {
    const { category, search, isSystem, isApproved } = req.query;
    
    // Build query
    const query = {};
    
    if (category) {
      query.category = category;
    }
    
    if (search) {
      query.$or = [
        { name: { $regex: search, $options: 'i' } },
        { description: { $regex: search, $options: 'i' } }
      ];
    }
    
    if (isSystem !== undefined) {
      query.isSystem = isSystem === 'true';
    }
    
    // Non-admin users can only see approved apps
    if (req.user.role !== 'admin') {
      query.isApproved = true;
    } else if (isApproved !== undefined) {
      query.isApproved = isApproved === 'true';
    }
    
    const apps = await App.find(query).select('-apkFilePath');
    
    res.json(apps);
  } catch (error) {
    console.error('Error retrieving apps:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Get app details
app.get('/apps/:id', authenticateJWT, async (req, res) => {
  try {
    const app = await App.findById(req.params.id);
    
    if (!app) {
      return res.status(404).json({ message: 'App not found' });
    }
    
    // Non-admin users can only see approved apps
    if (!app.isApproved && req.user.role !== 'admin') {
      return res.status(403).json({ message: 'Access denied' });
    }
    
    res.json(app);
  } catch (error) {
    console.error('Error retrieving app details:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Upload new app (admin only)
app.post('/apps', authenticateJWT, authorizeAdmin, upload.single('apk'), async (req, res) => {
  try {
    const { name, packageName, description, version, versionCode, category, developer } = req.body;
    
    // Validate required fields
    if (!name || !packageName || !description || !version || !versionCode) {
      return res.status(400).json({ message: 'Missing required fields' });
    }
    
    // Check if app already exists
    const existingApp = await App.findOne({ packageName });
    if (existingApp) {
      return res.status(400).json({ message: 'App with this package name already exists' });
    }
    
    // Create new app
    const newApp = new App({
      name,
      packageName,
      description,
      version,
      versionCode: parseInt(versionCode),
      category,
      developer,
      size: req.file ? req.file.size : 0,
      apkFilePath: req.file ? req.file.path : null,
      uploadedBy: req.user.username,
      isApproved: false // Requires explicit approval
    });
    
    await newApp.save();
    
    res.status(201).json({
      message: 'App uploaded successfully',
      appId: newApp._id
    });
  } catch (error) {
    console.error('Error uploading app:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Update app (admin only)
app.put('/apps/:id', authenticateJWT, authorizeAdmin, async (req, res) => {
  try {
    const { name, description, category, isApproved } = req.body;
    
    const app = await App.findById(req.params.id);
    
    if (!app) {
      return res.status(404).json({ message: 'App not found' });
    }
    
    // Update fields
    if (name) app.name = name;
    if (description) app.description = description;
    if (category) app.category = category;
    if (isApproved !== undefined) app.isApproved = isApproved;
    
    app.lastUpdated = new Date();
    
    await app.save();
    
    res.json({ message: 'App updated successfully' });
  } catch (error) {
    console.error('Error updating app:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Delete app (admin only)
app.delete('/apps/:id', authenticateJWT, authorizeAdmin, async (req, res) => {
  try {
    const app = await App.findById(req.params.id);
    
    if (!app) {
      return res.status(404).json({ message: 'App not found' });
    }
    
    // Delete APK file if it exists
    if (app.apkFilePath && fs.existsSync(app.apkFilePath)) {
      fs.unlinkSync(app.apkFilePath);
    }
    
    await App.deleteOne({ _id: req.params.id });
    
    res.json({ message: 'App deleted successfully' });
  } catch (error) {
    console.error('Error deleting app:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Get app categories
app.get('/categories', authenticateJWT, async (req, res) => {
  try {
    const categories = await App.distinct('category');
    
    res.json(categories.filter(category => category)); // Filter out null/empty values
  } catch (error) {
    console.error('Error retrieving categories:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Error handling
app.use((err, req, res, next) => {
  console.error(err.stack);
  
  if (err instanceof multer.MulterError) {
    if (err.code === 'LIMIT_FILE_SIZE') {
      return res.status(413).json({ message: 'File size limit exceeded (100MB maximum)' });
    }
    return res.status(400).json({ message: `Upload error: ${err.message}` });
  }
  
  res.status(500).json({
    error: 'Internal Server Error',
    message: process.env.NODE_ENV === 'development' ? err.message : undefined
  });
});

// Start the server
app.listen(PORT, () => {
  console.log(`App Catalog Service running on port ${PORT}`);
});

module.exports = app;
