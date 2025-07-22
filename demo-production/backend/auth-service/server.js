const express = require('express');
const cors = require('cors');
const jwt = require('jsonwebtoken');
const { MongoClient, ObjectId } = require('mongodb');
const bcrypt = require('bcryptjs');

// Initialize Express app
const app = express();
const PORT = process.env.PORT || 8081;

// MongoDB setup
const mongoUri = process.env.MONGO_URI || 'mongodb://localhost:27017/auth';
let db;

// Connect to MongoDB
async function connectToMongo() {
  try {
    const client = await MongoClient.connect(mongoUri);
    db = client.db();
    console.log('Connected to MongoDB');
    
    // Create indexes
    await db.collection('users').createIndex({ username: 1 }, { unique: true });
    await db.collection('users').createIndex({ email: 1 }, { unique: true });
    
    // Create demo user if none exists
    const userCount = await db.collection('users').countDocuments();
    if (userCount === 0) {
      const hashedPassword = await bcrypt.hash('password', 10);
      await db.collection('users').insertOne({
        username: 'demo',
        email: 'demo@shaydz-avmo.io',
        password: hashedPassword,
        firstName: 'Demo',
        lastName: 'User',
        role: 'user',
        isActive: true,
        createdAt: new Date().toISOString()
      });
      console.log('Demo user created');
    }
  } catch (err) {
    console.error('Failed to connect to MongoDB', err);
    process.exit(1);
  }
}

// Middleware
app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Log all requests
app.use((req, res, next) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.path}`);
  next();
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error('Error:', err);
  res.status(500).json({ message: 'Internal server error', error: err.message });
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok', service: 'auth-service' });
});

// Login endpoint
app.post('/login', async (req, res) => {
  const { username, password } = req.body;
  
  if (!username || !password) {
    return res.status(400).json({ message: 'Username and password required' });
  }
  
  try {
    // Find user
    const user = await db.collection('users').findOne({ 
      $or: [{ username }, { email: username }] 
    });
    
    if (!user) {
      return res.status(401).json({ message: 'Invalid credentials' });
    }
    
    // Check password
    const isValid = await bcrypt.compare(password, user.password);
    if (!isValid) {
      return res.status(401).json({ message: 'Invalid credentials' });
    }
    
    // Generate JWT
    const token = jwt.sign(
      { 
        id: user._id.toString(),
        username: user.username,
        role: user.role 
      }, 
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRATION || '1h' }
    );
    
    // Update last login
    await db.collection('users').updateOne(
      { _id: user._id },
      { $set: { lastLogin: new Date().toISOString() } }
    );
    
    res.json({ token });
  } catch (err) {
    console.error('Login error:', err);
    res.status(500).json({ message: 'Internal server error' });
  }
});

// Register endpoint
app.post('/register', async (req, res) => {
  const { username, email, password, firstName, lastName } = req.body;
  
  if (!username || !email || !password) {
    return res.status(400).json({ message: 'Username, email and password required' });
  }
  
  try {
    // Check if user exists
    const existingUser = await db.collection('users').findOne({ 
      $or: [{ username }, { email }] 
    });
    
    if (existingUser) {
      return res.status(409).json({ message: 'Username or email already exists' });
    }
    
    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);
    
    // Create user
    const result = await db.collection('users').insertOne({
      username,
      email,
      password: hashedPassword,
      firstName,
      lastName,
      role: 'user',
      isActive: true,
      createdAt: new Date().toISOString()
    });
    
    res.status(201).json({ 
      id: result.insertedId,
      username,
      email
    });
  } catch (err) {
    console.error('Registration error:', err);
    res.status(500).json({ message: 'Internal server error' });
  }
});

// Get user profile endpoint
app.get('/profile', async (req, res) => {
  // Get user ID from auth token
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
    const userId = decoded.id;
    
    // Find user
    const user = await db.collection('users').findOne({ 
      _id: new ObjectId(userId) 
    });
    
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }
    
    // Return user data without password
    const { password, ...userData } = user;
    res.json({
      ...userData,
      id: userData._id.toString()
    });
  } catch (err) {
    console.error('Profile error:', err);
    res.status(500).json({ message: 'Internal server error' });
  }
});

// Start server after connecting to MongoDB
connectToMongo().then(() => {
  app.listen(PORT, () => {
    console.log(`Auth Service running on port ${PORT}`);
  });
});
