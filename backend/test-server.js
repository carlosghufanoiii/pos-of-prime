const express = require('express');
const cors = require('cors');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3001;

// Middleware
app.use(cors());
app.use(express.json());

// Health check endpoint
app.get('/health', (req, res) => {
  const config = {
    port: PORT,
    env: process.env.NODE_ENV || 'development',
    firebase_project: process.env.FIREBASE_PROJECT_ID || 'Not configured',
    firebase_email: process.env.FIREBASE_CLIENT_EMAIL ? 'Configured' : 'Not configured',
    timestamp: new Date().toISOString()
  };
  
  res.json({ 
    status: 'OK',
    message: '🚀 Prime POS Backend Test Server',
    config
  });
});

// Simple test endpoint
app.get('/api/test', (req, res) => {
  res.json({
    message: '✅ Backend API is working!',
    endpoints: {
      health: '/health',
      users: '/api/users (requires Firebase Admin SDK)',
      me: '/api/user/me (requires Firebase Admin SDK)'
    }
  });
});

// Info endpoint about Firebase setup
app.get('/api/firebase-status', (req, res) => {
  const requiredEnvVars = [
    'FIREBASE_PROJECT_ID',
    'FIREBASE_PRIVATE_KEY_ID', 
    'FIREBASE_PRIVATE_KEY',
    'FIREBASE_CLIENT_EMAIL',
    'FIREBASE_CLIENT_ID'
  ];
  
  const status = {};
  let allConfigured = true;
  
  requiredEnvVars.forEach(envVar => {
    status[envVar] = process.env[envVar] ? 'Configured' : 'Missing';
    if (!process.env[envVar]) allConfigured = false;
  });
  
  res.json({
    firebase_admin_ready: allConfigured,
    required_env_vars: status,
    instructions: allConfigured ? 
      'Firebase Admin SDK is ready! You can now use the full server.' :
      'Please configure Firebase Admin SDK credentials in .env file'
  });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({ 
    error: 'Route not found',
    available_routes: ['/health', '/api/test', '/api/firebase-status']
  });
});

app.listen(PORT, () => {
  console.log('🚀 Prime POS Backend Test Server');
  console.log(`📡 Server running on port ${PORT}`);
  console.log(`🌐 Health check: http://localhost:${PORT}/health`);
  console.log(`⚡ Test API: http://localhost:${PORT}/api/test`);
  console.log(`🔧 Firebase status: http://localhost:${PORT}/api/firebase-status`);
});

module.exports = app;