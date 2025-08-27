const express = require('express');
const cors = require('cors');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3001;

// Middleware
app.use(cors());
app.use(express.json());

let admin, db, auth;
let isFirebaseInitialized = false;

// Try to initialize Firebase Admin SDK
try {
  admin = require('firebase-admin');
  
  // Check if we have all required environment variables
  const requiredEnvVars = [
    'FIREBASE_PROJECT_ID',
    'FIREBASE_PRIVATE_KEY_ID',
    'FIREBASE_PRIVATE_KEY',
    'FIREBASE_CLIENT_EMAIL',
    'FIREBASE_CLIENT_ID'
  ];
  
  const missingVars = requiredEnvVars.filter(envVar => !process.env[envVar]);
  
  if (missingVars.length === 0) {
    // Initialize with environment variables
    const serviceAccount = {
      type: "service_account",
      project_id: process.env.FIREBASE_PROJECT_ID,
      private_key_id: process.env.FIREBASE_PRIVATE_KEY_ID,
      private_key: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
      client_email: process.env.FIREBASE_CLIENT_EMAIL,
      client_id: process.env.FIREBASE_CLIENT_ID,
      auth_uri: "https://accounts.google.com/o/oauth2/auth",
      token_uri: "https://oauth2.googleapis.com/token",
      auth_provider_x509_cert_url: "https://www.googleapis.com/oauth2/v1/certs",
      client_x509_cert_url: `https://www.googleapis.com/robot/v1/metadata/x509/${encodeURIComponent(process.env.FIREBASE_CLIENT_EMAIL)}`
    };

    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
      databaseURL: `https://${process.env.FIREBASE_PROJECT_ID}-default-rtdb.firebaseio.com`
    });

    db = admin.firestore();
    auth = admin.auth();
    isFirebaseInitialized = true;
    
    console.log('✅ Firebase Admin SDK initialized successfully');
  } else {
    console.log('⚠️  Firebase Admin SDK not initialized - missing environment variables:', missingVars);
  }
} catch (error) {
  console.log('⚠️  Firebase Admin SDK initialization failed:', error.message);
}

// Mock database for fallback mode
const mockUsers = new Map();
mockUsers.set('admin-123', {
  id: 'admin-123',
  email: 'admin@primepos.com',
  name: 'System Admin',
  role: 'admin',
  isActive: true,
  createdAt: new Date(),
  updatedAt: new Date()
});

// Token verification middleware
const verifyToken = async (req, res, next) => {
  try {
    const token = req.headers.authorization?.split('Bearer ')[1];
    if (!token) {
      return res.status(401).json({ error: 'No token provided' });
    }

    if (isFirebaseInitialized) {
      // Use real Firebase token verification
      const decodedToken = await auth.verifyIdToken(token);
      req.user = decodedToken;
    } else {
      // Fallback mode for demo
      if (token === 'demo-token') {
        req.user = { uid: 'admin-123', email: 'admin@primepos.com' };
      } else {
        return res.status(401).json({ error: 'Invalid token' });
      }
    }
    next();
  } catch (error) {
    console.error('Token verification error:', error);
    res.status(401).json({ error: 'Invalid token' });
  }
};

// Admin verification middleware
const requireAdmin = async (req, res, next) => {
  try {
    if (isFirebaseInitialized) {
      // Use Firestore to check admin status
      const userDoc = await db.collection('users').doc(req.user.uid).get();
      if (!userDoc.exists) {
        return res.status(403).json({ error: 'User not found' });
      }
      
      const userData = userDoc.data();
      if (userData.role !== 'admin') {
        return res.status(403).json({ error: 'Admin access required' });
      }
    } else {
      // Fallback mode
      const user = mockUsers.get(req.user.uid);
      if (!user || user.role !== 'admin') {
        return res.status(403).json({ error: 'Admin access required' });
      }
    }
    
    next();
  } catch (error) {
    console.error('Admin check error:', error);
    res.status(500).json({ error: 'Failed to verify admin status' });
  }
};

// 🔧 PRODUCTION USER CREATION - Fixed Role Assignment
app.post('/api/users', verifyToken, requireAdmin, async (req, res) => {
  try {
    const { email, password, name, role } = req.body;

    if (!email || !password || !name) {
      return res.status(400).json({ 
        error: 'Email, password, and name are required' 
      });
    }

    // 🔧 FIXED: Proper role validation with default to 'waiter'
    const validRoles = ['admin', 'waiter', 'cashier', 'kitchen', 'bartender'];
    const userRole = role && validRoles.includes(role) ? role : 'waiter';

    // 🔧 FIXED: Admin role only assigned when explicitly requested
    if (role === 'admin') {
      console.log(`🔐 Admin role explicitly requested for user: ${email}`);
    } else if (!role || !validRoles.includes(role)) {
      console.log(`🛡️  No valid role provided, defaulting to 'waiter' for user: ${email}`);
    }

    if (isFirebaseInitialized) {
      // Production mode with Firebase
      const userRecord = await auth.createUser({
        email,
        password,
        displayName: name,
        emailVerified: false
      });

      // Set custom claims for role-based access
      await auth.setCustomUserClaims(userRecord.uid, { 
        role: userRole,
        createdAt: Date.now()
      });

      // Create user document in Firestore
      const userData = {
        id: userRecord.uid,
        email,
        name,
        role: userRole,
        isActive: true,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        createdBy: req.user.uid
      };

      await db.collection('users').doc(userRecord.uid).set(userData);

      console.log(`👤 [PRODUCTION] User created: ${email} with role: ${userRole}`);

      res.status(201).json({
        success: true,
        mode: 'production',
        user: {
          id: userRecord.uid,
          email,
          name,
          role: userRole,
          isActive: true
        }
      });

    } else {
      // Fallback mode (demo)
      const userId = `user-${Date.now()}`;
      const userData = {
        id: userId,
        email,
        name,
        role: userRole,
        isActive: true,
        createdAt: new Date(),
        updatedAt: new Date(),
        createdBy: req.user.uid
      };

      mockUsers.set(userId, userData);
      console.log(`👤 [DEMO] User created: ${email} with role: ${userRole}`);

      res.status(201).json({
        success: true,
        mode: 'demo',
        user: userData,
        message: `User created with role: ${userRole}`
      });
    }

  } catch (error) {
    console.error('Error creating user:', error);
    
    if (error.code === 'auth/email-already-exists') {
      return res.status(400).json({ error: 'Email already exists' });
    }
    if (error.code === 'auth/invalid-email') {
      return res.status(400).json({ error: 'Invalid email format' });
    }
    if (error.code === 'auth/weak-password') {
      return res.status(400).json({ error: 'Password is too weak' });
    }

    res.status(500).json({ error: 'Failed to create user' });
  }
});

// Get all users
app.get('/api/users', verifyToken, requireAdmin, async (req, res) => {
  try {
    if (isFirebaseInitialized) {
      const snapshot = await db.collection('users').orderBy('createdAt', 'desc').get();
      const users = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data(),
        createdAt: doc.data().createdAt?.toDate(),
        updatedAt: doc.data().updatedAt?.toDate()
      }));
      res.json({ users, mode: 'production' });
    } else {
      const users = Array.from(mockUsers.values());
      res.json({ users, mode: 'demo' });
    }
  } catch (error) {
    console.error('Error fetching users:', error);
    res.status(500).json({ error: 'Failed to fetch users' });
  }
});

// Get current user
app.get('/api/user/me', verifyToken, async (req, res) => {
  try {
    if (isFirebaseInitialized) {
      const userDoc = await db.collection('users').doc(req.user.uid).get();
      if (!userDoc.exists) {
        // Create user profile if it doesn't exist
        const userData = {
          id: req.user.uid,
          email: req.user.email,
          name: req.user.name || req.user.email.split('@')[0],
          role: 'waiter', // 🔧 FIXED: Default role
          isActive: true,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
        };

        await db.collection('users').doc(req.user.uid).set(userData);
        await auth.setCustomUserClaims(req.user.uid, { role: 'waiter', createdAt: Date.now() });

        return res.json({ user: userData, mode: 'production' });
      }

      const userData = userDoc.data();
      res.json({ 
        user: {
          ...userData,
          createdAt: userData.createdAt?.toDate(),
          updatedAt: userData.updatedAt?.toDate()
        },
        mode: 'production'
      });
    } else {
      const user = mockUsers.get(req.user.uid);
      if (!user) {
        const newUser = {
          id: req.user.uid,
          email: req.user.email,
          name: req.user.email.split('@')[0],
          role: 'waiter', // 🔧 FIXED: Default role
          isActive: true,
          createdAt: new Date(),
          updatedAt: new Date()
        };
        mockUsers.set(req.user.uid, newUser);
        return res.json({ user: newUser, mode: 'demo' });
      }
      res.json({ user, mode: 'demo' });
    }
  } catch (error) {
    console.error('Error fetching user profile:', error);
    res.status(500).json({ error: 'Failed to fetch user profile' });
  }
});

// Health check
app.get('/health', (req, res) => {
  res.json({ 
    status: 'OK',
    mode: isFirebaseInitialized ? 'production' : 'demo',
    firebase_initialized: isFirebaseInitialized,
    message: isFirebaseInitialized ? '🚀 Production Backend Ready!' : '🎯 Demo Mode - Configure Firebase for Production',
    timestamp: new Date().toISOString()
  });
});

// System status
app.get('/api/status', (req, res) => {
  res.json({
    mode: isFirebaseInitialized ? 'production' : 'demo',
    firebase_admin_sdk: isFirebaseInitialized ? 'initialized' : 'not configured',
    features: {
      user_creation: '✅ Fixed role assignment',
      role_validation: '✅ Server-side validation', 
      admin_protection: '✅ Admin-only operations',
      security: '✅ Token verification'
    },
    endpoints: [
      'POST /api/users - Create user with proper role assignment',
      'GET /api/users - List all users (admin only)',
      'GET /api/user/me - Get current user profile',
      'GET /health - System health check'
    ]
  });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({ error: 'Route not found' });
});

// Error handling
app.use((err, req, res, next) => {
  console.error('Unhandled error:', err);
  res.status(500).json({ error: 'Internal server error' });
});

app.listen(PORT, () => {
  console.log('🚀 Prime POS Production Backend');
  console.log(`📡 Server running on port ${PORT}`);
  console.log(`🔧 Mode: ${isFirebaseInitialized ? 'PRODUCTION' : 'DEMO'}`);
  console.log(`🌐 Health check: http://localhost:${PORT}/health`);
  console.log(`📊 Status: http://localhost:${PORT}/api/status`);
  
  if (!isFirebaseInitialized) {
    console.log('\n⚠️  Running in DEMO mode');
    console.log('   To enable production mode:');
    console.log('   1. Get Firebase Admin SDK service account key');
    console.log('   2. Run: node setup-firebase-admin.js /path/to/service-account.json');
    console.log('   3. Restart server');
  } else {
    console.log('\n✅ Running in PRODUCTION mode with Firebase Admin SDK');
  }
});

module.exports = app;