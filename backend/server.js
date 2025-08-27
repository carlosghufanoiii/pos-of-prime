const express = require('express');
const admin = require('firebase-admin');
const cors = require('cors');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// Initialize Firebase Admin SDK
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

const db = admin.firestore();
const auth = admin.auth();

// Middleware to verify Firebase token and extract user info
const verifyToken = async (req, res, next) => {
  try {
    const token = req.headers.authorization?.split('Bearer ')[1];
    if (!token) {
      return res.status(401).json({ error: 'No token provided' });
    }

    const decodedToken = await auth.verifyIdToken(token);
    req.user = decodedToken;
    next();
  } catch (error) {
    console.error('Token verification error:', error);
    res.status(401).json({ error: 'Invalid token' });
  }
};

// Middleware to check if user has admin role
const requireAdmin = async (req, res, next) => {
  try {
    const userDoc = await db.collection('users').doc(req.user.uid).get();
    if (!userDoc.exists) {
      return res.status(403).json({ error: 'User not found' });
    }
    
    const userData = userDoc.data();
    if (userData.role !== 'admin') {
      return res.status(403).json({ error: 'Admin access required' });
    }
    
    next();
  } catch (error) {
    console.error('Admin check error:', error);
    res.status(500).json({ error: 'Failed to verify admin status' });
  }
};

// Create user endpoint (admin only)
app.post('/api/users', verifyToken, requireAdmin, async (req, res) => {
  try {
    const { email, password, name, role } = req.body;

    // Validate required fields
    if (!email || !password || !name) {
      return res.status(400).json({ 
        error: 'Email, password, and name are required' 
      });
    }

    // Validate role - default to 'waiter' if not provided or invalid
    const validRoles = ['admin', 'waiter', 'cashier', 'kitchen', 'bartender'];
    const userRole = role && validRoles.includes(role) ? role : 'waiter';

    // Only allow admin creation if explicitly requested and current user is admin
    if (role === 'admin') {
      console.log('Admin role explicitly requested for user:', email);
    }

    // Create user with Firebase Auth
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

    console.log(`User created successfully: ${email} with role: ${userRole}`);

    res.status(201).json({
      success: true,
      user: {
        id: userRecord.uid,
        email,
        name,
        role: userRole,
        isActive: true
      }
    });

  } catch (error) {
    console.error('Error creating user:', error);
    
    // Handle specific Firebase errors
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

// Update user endpoint (admin only)
app.put('/api/users/:userId', verifyToken, requireAdmin, async (req, res) => {
  try {
    const { userId } = req.params;
    const { name, role, isActive } = req.body;

    // Validate role
    const validRoles = ['admin', 'waiter', 'cashier', 'kitchen', 'bartender'];
    if (role && !validRoles.includes(role)) {
      return res.status(400).json({ error: 'Invalid role' });
    }

    // Get current user data
    const userDoc = await db.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      return res.status(404).json({ error: 'User not found' });
    }

    const updates = {
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedBy: req.user.uid
    };

    // Update display name in Firebase Auth if provided
    if (name) {
      await auth.updateUser(userId, { displayName: name });
      updates.name = name;
    }

    // Update role and custom claims if provided
    if (role) {
      const currentData = userDoc.data();
      
      // Log role changes for admin assignments
      if (role === 'admin' && currentData.role !== 'admin') {
        console.log(`Promoting user ${currentData.email} to admin role`);
      }
      
      await auth.setCustomUserClaims(userId, { 
        role,
        updatedAt: Date.now()
      });
      updates.role = role;
    }

    // Update active status if provided
    if (typeof isActive === 'boolean') {
      updates.isActive = isActive;
      
      // Disable user in Firebase Auth if being deactivated
      if (!isActive) {
        await auth.updateUser(userId, { disabled: true });
      } else {
        await auth.updateUser(userId, { disabled: false });
      }
    }

    // Update user document in Firestore
    await db.collection('users').doc(userId).update(updates);

    const updatedDoc = await db.collection('users').doc(userId).get();
    const updatedUser = updatedDoc.data();

    res.json({
      success: true,
      user: updatedUser
    });

  } catch (error) {
    console.error('Error updating user:', error);
    res.status(500).json({ error: 'Failed to update user' });
  }
});

// Get all users endpoint (admin only)
app.get('/api/users', verifyToken, requireAdmin, async (req, res) => {
  try {
    const snapshot = await db.collection('users').orderBy('createdAt', 'desc').get();
    const users = snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
      createdAt: doc.data().createdAt?.toDate(),
      updatedAt: doc.data().updatedAt?.toDate()
    }));

    res.json({ users });
  } catch (error) {
    console.error('Error fetching users:', error);
    res.status(500).json({ error: 'Failed to fetch users' });
  }
});

// Get current user info endpoint
app.get('/api/user/me', verifyToken, async (req, res) => {
  try {
    const userDoc = await db.collection('users').doc(req.user.uid).get();
    if (!userDoc.exists) {
      // Create user profile if it doesn't exist (for Google Sign-In users)
      const userData = {
        id: req.user.uid,
        email: req.user.email,
        name: req.user.name || req.user.email.split('@')[0],
        role: 'waiter', // Default role
        isActive: true,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      };

      await db.collection('users').doc(req.user.uid).set(userData);
      
      // Set custom claims
      await auth.setCustomUserClaims(req.user.uid, { 
        role: 'waiter',
        createdAt: Date.now()
      });

      return res.json({ user: userData });
    }

    const userData = userDoc.data();
    res.json({ 
      user: {
        ...userData,
        createdAt: userData.createdAt?.toDate(),
        updatedAt: userData.updatedAt?.toDate()
      }
    });
  } catch (error) {
    console.error('Error fetching user profile:', error);
    res.status(500).json({ error: 'Failed to fetch user profile' });
  }
});

// Delete user endpoint (admin only)
app.delete('/api/users/:userId', verifyToken, requireAdmin, async (req, res) => {
  try {
    const { userId } = req.params;

    // Don't allow deleting self
    if (userId === req.user.uid) {
      return res.status(400).json({ error: 'Cannot delete your own account' });
    }

    // Delete user from Firebase Auth
    await auth.deleteUser(userId);

    // Delete user document from Firestore
    await db.collection('users').doc(userId).delete();

    res.json({ success: true, message: 'User deleted successfully' });
  } catch (error) {
    console.error('Error deleting user:', error);
    res.status(500).json({ error: 'Failed to delete user' });
  }
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'OK', timestamp: new Date().toISOString() });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error('Unhandled error:', err);
  res.status(500).json({ error: 'Internal server error' });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({ error: 'Route not found' });
});

app.listen(PORT, () => {
  console.log(`🚀 Prime POS Backend server running on port ${PORT}`);
  console.log(`📊 Health check: http://localhost:${PORT}/health`);
});

module.exports = app;