const express = require('express');
const cors = require('cors');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3001;

// Middleware
app.use(cors());
app.use(express.json());

// Mock database for demo
const users = new Map();
users.set('admin-123', {
  id: 'admin-123',
  email: 'admin@primepos.com',
  name: 'System Admin',
  role: 'admin',
  isActive: true,
  createdAt: new Date(),
  updatedAt: new Date()
});

// Mock token verification for demo
const verifyToken = (req, res, next) => {
  const token = req.headers.authorization?.split('Bearer ')[1];
  if (!token || token === 'invalid') {
    return res.status(401).json({ error: 'No token provided or invalid token' });
  }
  
  // Mock user - in real implementation, this comes from Firebase
  req.user = {
    uid: 'admin-123',
    email: 'admin@primepos.com'
  };
  next();
};

// Mock admin check
const requireAdmin = (req, res, next) => {
  const user = users.get(req.user.uid);
  if (!user || user.role !== 'admin') {
    return res.status(403).json({ error: 'Admin access required' });
  }
  next();
};

// Create user endpoint (admin only) - FIXED ROLE ASSIGNMENT
app.post('/api/users', verifyToken, requireAdmin, (req, res) => {
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
      console.log(`✅ Admin role explicitly requested for user: ${email}`);
    } else if (!role || !validRoles.includes(role)) {
      console.log(`🛡️  No valid role provided, defaulting to 'waiter' for user: ${email}`);
    }

    const userId = `user-${Date.now()}`;
    const userData = {
      id: userId,
      email,
      name,
      role: userRole, // 🔧 Uses validated role
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date(),
      createdBy: req.user.uid
    };

    users.set(userId, userData);

    console.log(`👤 User created: ${email} with role: ${userRole}`);

    res.status(201).json({
      success: true,
      user: userData,
      message: `User created with role: ${userRole}`
    });

  } catch (error) {
    console.error('Error creating user:', error);
    res.status(500).json({ error: 'Failed to create user' });
  }
});

// Get all users
app.get('/api/users', verifyToken, requireAdmin, (req, res) => {
  const allUsers = Array.from(users.values());
  res.json({ users: allUsers });
});

// Get current user
app.get('/api/user/me', verifyToken, (req, res) => {
  const user = users.get(req.user.uid);
  if (!user) {
    // 🔧 FIXED: Default role for new users
    const newUser = {
      id: req.user.uid,
      email: req.user.email,
      name: req.user.email.split('@')[0],
      role: 'waiter', // 🔧 Default to waiter, not admin
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date()
    };
    users.set(req.user.uid, newUser);
    return res.json({ user: newUser });
  }
  res.json({ user });
});

// Update user
app.put('/api/users/:userId', verifyToken, requireAdmin, (req, res) => {
  try {
    const { userId } = req.params;
    const { name, role, isActive } = req.body;
    
    const user = users.get(userId);
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    // 🔧 FIXED: Proper role validation on update
    const validRoles = ['admin', 'waiter', 'cashier', 'kitchen', 'bartender'];
    
    const updates = { ...user, updatedAt: new Date(), updatedBy: req.user.uid };
    
    if (name) updates.name = name;
    if (typeof isActive === 'boolean') updates.isActive = isActive;
    
    if (role && validRoles.includes(role)) {
      if (role === 'admin' && user.role !== 'admin') {
        console.log(`🔐 Promoting user ${user.email} to admin role`);
      }
      updates.role = role;
    }

    users.set(userId, updates);
    res.json({ success: true, user: updates });

  } catch (error) {
    console.error('Error updating user:', error);
    res.status(500).json({ error: 'Failed to update user' });
  }
});

// Delete user
app.delete('/api/users/:userId', verifyToken, requireAdmin, (req, res) => {
  const { userId } = req.params;
  
  if (userId === req.user.uid) {
    return res.status(400).json({ error: 'Cannot delete your own account' });
  }

  if (users.delete(userId)) {
    res.json({ success: true, message: 'User deleted successfully' });
  } else {
    res.status(404).json({ error: 'User not found' });
  }
});

// Health check
app.get('/health', (req, res) => {
  res.json({ 
    status: 'OK', 
    message: '🚀 Prime POS Demo Backend - Role Assignment Fixed!',
    users_count: users.size,
    timestamp: new Date().toISOString()
  });
});

// Demo endpoints info
app.get('/api/demo', (req, res) => {
  res.json({
    message: '🎯 Prime POS Role Assignment Demo',
    fixed_issues: [
      '✅ Default role is now "waiter" instead of "admin"',
      '✅ Admin role only assigned when explicitly requested',
      '✅ Role validation prevents invalid roles',
      '✅ Server-side validation cannot be bypassed'
    ],
    test_scenarios: [
      {
        endpoint: 'POST /api/users',
        scenario: 'Create user without role',
        expected: 'Role defaults to "waiter"'
      },
      {
        endpoint: 'POST /api/users', 
        scenario: 'Create user with role: "admin"',
        expected: 'Role is explicitly set to "admin"'
      },
      {
        endpoint: 'POST /api/users',
        scenario: 'Create user with invalid role',
        expected: 'Role defaults to "waiter"'
      }
    ],
    demo_credentials: {
      token: 'demo-token',
      admin_user: 'admin-123'
    }
  });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({ error: 'Route not found' });
});

app.listen(PORT, () => {
  console.log('🎯 Prime POS Demo Backend - Role Assignment Fixed!');
  console.log(`📡 Server running on port ${PORT}`);
  console.log(`🌐 Health check: http://localhost:${PORT}/health`);
  console.log(`🔧 Demo info: http://localhost:${PORT}/api/demo`);
  console.log('\n🧪 Test with:');
  console.log('curl -H "Authorization: Bearer demo-token" http://localhost:3001/api/demo');
});

module.exports = app;