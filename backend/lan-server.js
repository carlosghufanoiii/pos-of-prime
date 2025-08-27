const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const sqlite3 = require('sqlite3').verbose();
const path = require('path');
const { v4: uuidv4 } = require('uuid');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const cron = require('node-cron');
const axios = require('axios');
const os = require('os');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;
const JWT_SECRET = process.env.JWT_SECRET || 'prime-pos-secret-key-change-in-production';

// Middleware
app.use(helmet());
app.use(cors());
app.use(morgan('combined'));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// SQLite Database Setup
const dbPath = path.join(__dirname, 'data', 'prime_pos_local.db');
const db = new sqlite3.Database(dbPath, (err) => {
  if (err) {
    console.error('❌ Error opening SQLite database:', err.message);
  } else {
    console.log('✅ Connected to SQLite database');
    initializeDatabase();
  }
});

// Initialize Database Tables
function initializeDatabase() {
  const tables = [
    // Users table
    `CREATE TABLE IF NOT EXISTS users (
      id TEXT PRIMARY KEY,
      email TEXT UNIQUE NOT NULL,
      name TEXT NOT NULL,
      password_hash TEXT,
      role TEXT NOT NULL CHECK (role IN ('admin', 'waiter', 'cashier', 'kitchen', 'bartender')) DEFAULT 'waiter',
      is_active BOOLEAN NOT NULL DEFAULT 1,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      last_sync DATETIME
    )`,

    // Products table
    `CREATE TABLE IF NOT EXISTS products (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      description TEXT,
      price REAL NOT NULL,
      category TEXT NOT NULL,
      is_alcoholic BOOLEAN NOT NULL DEFAULT 0,
      is_in_stock BOOLEAN NOT NULL DEFAULT 1,
      stock_quantity INTEGER DEFAULT 0,
      image_url TEXT,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      last_sync DATETIME
    )`,

    // Orders table
    `CREATE TABLE IF NOT EXISTS orders (
      id TEXT PRIMARY KEY,
      order_number TEXT UNIQUE NOT NULL,
      waiter_id TEXT NOT NULL,
      waiter_name TEXT NOT NULL,
      cashier_id TEXT,
      table_number TEXT,
      customer_name TEXT,
      status TEXT NOT NULL CHECK (status IN ('pending_approval', 'approved', 'in_prep', 'ready', 'served', 'cancelled')) DEFAULT 'pending_approval',
      subtotal REAL NOT NULL DEFAULT 0,
      tax_amount REAL NOT NULL DEFAULT 0,
      total REAL NOT NULL DEFAULT 0,
      payment_method TEXT,
      notes TEXT,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      approved_at DATETIME,
      ready_at DATETIME,
      served_at DATETIME,
      updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      last_sync DATETIME,
      FOREIGN KEY (waiter_id) REFERENCES users (id),
      FOREIGN KEY (cashier_id) REFERENCES users (id)
    )`,

    // Order Items table
    `CREATE TABLE IF NOT EXISTS order_items (
      id TEXT PRIMARY KEY,
      order_id TEXT NOT NULL,
      product_id TEXT NOT NULL,
      product_name TEXT NOT NULL,
      unit_price REAL NOT NULL,
      quantity INTEGER NOT NULL,
      total_price REAL NOT NULL,
      status TEXT NOT NULL DEFAULT 'pending',
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (order_id) REFERENCES orders (id) ON DELETE CASCADE,
      FOREIGN KEY (product_id) REFERENCES products (id)
    )`,

    // Sync Queue table for offline operations
    `CREATE TABLE IF NOT EXISTS sync_queue (
      id TEXT PRIMARY KEY,
      table_name TEXT NOT NULL,
      record_id TEXT NOT NULL,
      operation TEXT NOT NULL CHECK (operation IN ('insert', 'update', 'delete')),
      data TEXT, -- JSON string
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      synced BOOLEAN DEFAULT 0
    )`,

    // System Settings table
    `CREATE TABLE IF NOT EXISTS system_settings (
      key TEXT PRIMARY KEY,
      value TEXT NOT NULL,
      updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )`
  ];

  tables.forEach((sql, index) => {
    db.run(sql, (err) => {
      if (err) {
        console.error(`❌ Error creating table ${index + 1}:`, err.message);
      } else {
        console.log(`✅ Table ${index + 1} ready`);
      }
    });
  });

  // Create default admin user
  createDefaultAdmin();

  // Insert default settings
  insertDefaultSettings();
}

// Create default admin user
function createDefaultAdmin() {
  const adminEmail = process.env.DEFAULT_ADMIN_EMAIL || 'admin@primepos.com';
  const adminPassword = process.env.DEFAULT_ADMIN_PASSWORD || 'admin123';

  db.get('SELECT id FROM users WHERE email = ?', [adminEmail], async (err, row) => {
    if (err) {
      console.error('❌ Error checking for admin user:', err.message);
    } else if (!row) {
      const adminId = uuidv4();
      const passwordHash = await bcrypt.hash(adminPassword, 10);

      db.run(
        'INSERT INTO users (id, email, name, password_hash, role) VALUES (?, ?, ?, ?, ?)',
        [adminId, adminEmail, 'System Administrator', passwordHash, 'admin'],
        (err) => {
          if (err) {
            console.error('❌ Error creating default admin:', err.message);
          } else {
            console.log('✅ Default admin user created:', adminEmail);
          }
        }
      );
    }
  });
}

// Insert default settings
function insertDefaultSettings() {
  const defaultSettings = [
    ['restaurant_name', 'Prime Restaurant & Bar'],
    ['currency', 'PHP'],
    ['tax_rate', '0.12'],
    ['server_version', '1.0.0'],
    ['last_cloud_sync', new Date().toISOString()]
  ];

  defaultSettings.forEach(([key, value]) => {
    db.run(
      'INSERT OR IGNORE INTO system_settings (key, value) VALUES (?, ?)',
      [key, value],
      (err) => {
        if (err) {
          console.error(`❌ Error setting ${key}:`, err.message);
        }
      }
    );
  });
}

// JWT Authentication Middleware
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ error: 'Access token required' });
  }

  jwt.verify(token, JWT_SECRET, (err, user) => {
    if (err) {
      return res.status(403).json({ error: 'Invalid or expired token' });
    }
    req.user = user;
    next();
  });
};

// Role-based middleware functions
const requireAdmin = (req, res, next) => {
  if (req.user.role !== 'admin') {
    return res.status(403).json({ 
      error: 'Admin access required',
      required_role: 'admin',
      current_role: req.user.role
    });
  }
  next();
};

const requireOperationalRole = (req, res, next) => {
  const operationalRoles = ['admin', 'waiter', 'cashier', 'bartender'];
  if (!operationalRoles.includes(req.user.role)) {
    return res.status(403).json({ 
      error: 'Operational role access required',
      required_roles: operationalRoles,
      current_role: req.user.role
    });
  }
  next();
};

const requireCashierOrAdmin = (req, res, next) => {
  const allowedRoles = ['admin', 'cashier'];
  if (!allowedRoles.includes(req.user.role)) {
    return res.status(403).json({ 
      error: 'Cashier or admin access required',
      required_roles: allowedRoles,
      current_role: req.user.role
    });
  }
  next();
};

const requireKitchenAccess = (req, res, next) => {
  const allowedRoles = ['admin', 'kitchen'];
  if (!allowedRoles.includes(req.user.role)) {
    return res.status(403).json({ 
      error: 'Kitchen access required',
      required_roles: allowedRoles,
      current_role: req.user.role
    });
  }
  next();
};

const requireBarAccess = (req, res, next) => {
  const allowedRoles = ['admin', 'bartender'];
  if (!allowedRoles.includes(req.user.role)) {
    return res.status(403).json({ 
      error: 'Bar access required',
      required_roles: allowedRoles,
      current_role: req.user.role
    });
  }
  next();
};

// Generic role checker middleware factory
const requireRoles = (...roles) => {
  return (req, res, next) => {
    if (!roles.includes(req.user.role)) {
      return res.status(403).json({ 
        error: `Access denied. Required roles: ${roles.join(', ')}`,
        required_roles: roles,
        current_role: req.user.role
      });
    }
    next();
  };
};

// Get server info and network details
app.get('/api/server/info', (req, res) => {
  const networkInterfaces = os.networkInterfaces();
  const serverIps = [];

  Object.keys(networkInterfaces).forEach(interfaceName => {
    const interfaces = networkInterfaces[interfaceName];
    interfaces.forEach(interface => {
      if (interface.family === 'IPv4' && !interface.internal) {
        serverIps.push({
          interface: interfaceName,
          ip: interface.address,
          netmask: interface.netmask
        });
      }
    });
  });

  res.json({
    server: 'Prime POS Local Backend',
    version: '1.0.0',
    timestamp: new Date().toISOString(),
    port: PORT,
    network_interfaces: serverIps,
    status: 'online'
  });
});

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.json({ 
    status: 'healthy',
    timestamp: new Date().toISOString(),
    database: 'connected',
    uptime: process.uptime()
  });
});

// Authentication endpoints
app.post('/api/auth/login', (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({ error: 'Email and password required' });
  }

  db.get('SELECT * FROM users WHERE email = ? AND is_active = 1', [email], async (err, user) => {
    if (err) {
      console.error('Database error:', err.message);
      return res.status(500).json({ error: 'Internal server error' });
    }

    if (!user) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    try {
      const isValidPassword = await bcrypt.compare(password, user.password_hash);
      if (!isValidPassword) {
        return res.status(401).json({ error: 'Invalid credentials' });
      }

      const token = jwt.sign(
        { 
          id: user.id, 
          email: user.email, 
          role: user.role 
        },
        JWT_SECRET,
        { expiresIn: '24h' }
      );

      res.json({
        token,
        user: {
          id: user.id,
          email: user.email,
          name: user.name,
          role: user.role,
          isActive: user.is_active
        }
      });
    } catch (error) {
      console.error('Password comparison error:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  });
});

// Get current user info
app.get('/api/auth/me', authenticateToken, (req, res) => {
  const { id } = req.user;
  
  db.get('SELECT id, email, name, role, is_active, created_at, updated_at FROM users WHERE id = ? AND is_active = 1', [id], (err, user) => {
    if (err) {
      console.error('Database error:', err.message);
      return res.status(500).json({ error: 'Internal server error' });
    }

    if (!user) {
      return res.status(404).json({ error: 'User not found or inactive' });
    }

    res.json({
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        role: user.role,
        isActive: user.is_active,
        createdAt: user.created_at,
        updatedAt: user.updated_at
      }
    });
  });
});

// User management endpoints
app.get('/api/users', authenticateToken, requireAdmin, (req, res) => {
  db.all('SELECT id, email, name, role, is_active, created_at FROM users ORDER BY created_at DESC', (err, users) => {
    if (err) {
      console.error('Error fetching users:', err.message);
      return res.status(500).json({ error: 'Failed to fetch users' });
    }
    res.json({ users });
  });
});

app.post('/api/users', authenticateToken, requireAdmin, async (req, res) => {
  const { email, name, password, role = 'waiter' } = req.body;

  if (!email || !name || !password) {
    return res.status(400).json({ error: 'Email, name, and password are required' });
  }

  const validRoles = ['admin', 'waiter', 'cashier', 'kitchen', 'bartender'];
  if (!validRoles.includes(role)) {
    return res.status(400).json({ error: 'Invalid role' });
  }

  try {
    const userId = uuidv4();
    const passwordHash = await bcrypt.hash(password, 10);

    db.run(
      'INSERT INTO users (id, email, name, password_hash, role) VALUES (?, ?, ?, ?, ?)',
      [userId, email, name, passwordHash, role],
      function(err) {
        if (err) {
          if (err.message.includes('UNIQUE constraint failed')) {
            return res.status(400).json({ error: 'Email already exists' });
          }
          console.error('Error creating user:', err.message);
          return res.status(500).json({ error: 'Failed to create user' });
        }

        res.status(201).json({
          success: true,
          user: { id: userId, email, name, role, isActive: true }
        });
      }
    );
  } catch (error) {
    console.error('Error hashing password:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Product endpoints
app.get('/api/products', authenticateToken, (req, res) => {
  db.all('SELECT * FROM products ORDER BY category, name', (err, products) => {
    if (err) {
      console.error('Error fetching products:', err.message);
      return res.status(500).json({ error: 'Failed to fetch products' });
    }
    res.json({ products });
  });
});

app.post('/api/products', authenticateToken, requireAdmin, (req, res) => {
  const { name, description, price, category, isAlcoholic = false, stockQuantity = 0, imageUrl } = req.body;

  if (!name || !price || !category) {
    return res.status(400).json({ error: 'Name, price, and category are required' });
  }

  const productId = uuidv4();
  db.run(
    'INSERT INTO products (id, name, description, price, category, is_alcoholic, stock_quantity, image_url) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
    [productId, name, description, price, category, isAlcoholic, stockQuantity, imageUrl],
    function(err) {
      if (err) {
        console.error('Error creating product:', err.message);
        return res.status(500).json({ error: 'Failed to create product' });
      }

      res.status(201).json({
        success: true,
        product: { id: productId, name, description, price, category, isAlcoholic, stockQuantity, imageUrl }
      });
    }
  );
});

// Order endpoints
app.get('/api/orders', authenticateToken, (req, res) => {
  const { status, waiter_id } = req.query;
  let sql = `
    SELECT o.*, 
           GROUP_CONCAT(
             oi.id || '|' || 
             oi.product_name || '|' || 
             oi.unit_price || '|' || 
             oi.quantity || '|' || 
             oi.total_price || '|' ||
             COALESCE(p.is_alcoholic, 0), '###'
           ) as items_data
    FROM orders o
    LEFT JOIN order_items oi ON o.id = oi.order_id
    LEFT JOIN products p ON oi.product_id = p.id
  `;
  
  const params = [];
  const conditions = [];

  if (status) {
    conditions.push('o.status = ?');
    params.push(status);
  }

  if (waiter_id) {
    conditions.push('o.waiter_id = ?');
    params.push(waiter_id);
  }

  if (conditions.length > 0) {
    sql += ' WHERE ' + conditions.join(' AND ');
  }

  sql += ' GROUP BY o.id ORDER BY o.created_at DESC';

  db.all(sql, params, (err, orders) => {
    if (err) {
      console.error('Error fetching orders:', err.message);
      return res.status(500).json({ error: 'Failed to fetch orders' });
    }

    // Process order items
    const processedOrders = orders.map(order => {
      const items = [];
      if (order.items_data) {
        const itemsArray = order.items_data.split('###').filter(item => item.trim());
        itemsArray.forEach(itemData => {
          const parts = itemData.split('|');
          if (parts.length === 6) {
            items.push({
              id: parts[0],
              productName: parts[1],
              unitPrice: parseFloat(parts[2]),
              quantity: parseInt(parts[3]),
              totalPrice: parseFloat(parts[4]),
              isAlcoholic: parseInt(parts[5]) === 1
            });
          }
        });
      }

      return {
        ...order,
        items,
        items_data: undefined // Remove the concatenated string
      };
    });

    res.json({ orders: processedOrders });
  });
});

app.post('/api/orders', authenticateToken, (req, res) => {
  const { tableNumber, customerName, items, notes } = req.body;

  if (!items || items.length === 0) {
    return res.status(400).json({ error: 'Order items are required' });
  }

  const orderId = uuidv4();
  const orderNumber = `ORD-${Date.now()}`;
  const subtotal = items.reduce((sum, item) => sum + (item.unitPrice * item.quantity), 0);
  const taxAmount = subtotal * 0.12; // 12% VAT
  const total = subtotal + taxAmount;

  db.serialize(() => {
    db.run('BEGIN TRANSACTION');

    // Insert order
    db.run(
      `INSERT INTO orders (id, order_number, waiter_id, waiter_name, table_number, customer_name, 
       subtotal, tax_amount, total, notes) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [orderId, orderNumber, req.user.id, req.user.name || req.user.email, tableNumber, customerName, 
       subtotal, taxAmount, total, notes],
      function(err) {
        if (err) {
          db.run('ROLLBACK');
          console.error('Error creating order:', err.message);
          return res.status(500).json({ error: 'Failed to create order' });
        }

        // Insert order items
        const itemInserts = items.map(item => {
          return new Promise((resolve, reject) => {
            const itemId = uuidv4();
            const totalPrice = item.unitPrice * item.quantity;
            
            db.run(
              'INSERT INTO order_items (id, order_id, product_id, product_name, unit_price, quantity, total_price) VALUES (?, ?, ?, ?, ?, ?, ?)',
              [itemId, orderId, item.productId, item.productName, item.unitPrice, item.quantity, totalPrice],
              (err) => {
                if (err) reject(err);
                else resolve();
              }
            );
          });
        });

        Promise.all(itemInserts)
          .then(() => {
            db.run('COMMIT');
            res.status(201).json({
              success: true,
              order: {
                id: orderId,
                orderNumber,
                waiterId: req.user.id,
                waiterName: req.user.name || req.user.email,
                tableNumber,
                customerName,
                status: 'pending_approval',
                subtotal,
                taxAmount,
                total,
                notes,
                items
              }
            });
          })
          .catch(err => {
            db.run('ROLLBACK');
            console.error('Error inserting order items:', err.message);
            res.status(500).json({ error: 'Failed to create order items' });
          });
      }
    );
  });
});

// Update order status
app.put('/api/orders/:orderId/status', authenticateToken, (req, res) => {
  const { orderId } = req.params;
  const { status, userId } = req.body;

  const validStatuses = ['pending_approval', 'approved', 'in_prep', 'ready', 'served', 'cancelled'];
  if (!validStatuses.includes(status)) {
    return res.status(400).json({ error: 'Invalid status' });
  }

  let updateFields = ['status = ?', 'updated_at = CURRENT_TIMESTAMP'];
  let params = [status];

  // Add status-specific fields
  switch (status) {
    case 'approved':
      updateFields.push('cashier_id = ?', 'approved_at = CURRENT_TIMESTAMP');
      params.push(userId);
      break;
    case 'ready':
      updateFields.push('ready_at = CURRENT_TIMESTAMP');
      break;
    case 'served':
      updateFields.push('served_at = CURRENT_TIMESTAMP');
      break;
  }

  params.push(orderId);

  db.run(
    `UPDATE orders SET ${updateFields.join(', ')} WHERE id = ?`,
    params,
    function(err) {
      if (err) {
        console.error('Error updating order status:', err.message);
        return res.status(500).json({ error: 'Failed to update order status' });
      }

      if (this.changes === 0) {
        return res.status(404).json({ error: 'Order not found' });
      }

      res.json({ success: true, message: `Order status updated to ${status}` });
    }
  );
});

// Get system statistics
app.get('/api/stats', authenticateToken, (req, res) => {
  const stats = {};

  db.serialize(() => {
    // Total orders today
    db.get(
      "SELECT COUNT(*) as count FROM orders WHERE DATE(created_at) = DATE('now')",
      (err, result) => {
        if (!err) stats.ordersToday = result.count;
      }
    );

    // Revenue today
    db.get(
      "SELECT SUM(total) as revenue FROM orders WHERE DATE(created_at) = DATE('now') AND status != 'cancelled'",
      (err, result) => {
        if (!err) stats.revenueToday = result.revenue || 0;
      }
    );

    // Orders by status
    db.all(
      'SELECT status, COUNT(*) as count FROM orders GROUP BY status',
      (err, results) => {
        if (!err) {
          stats.ordersByStatus = {};
          results.forEach(row => {
            stats.ordersByStatus[row.status] = row.count;
          });
        }
        
        // Send response after all queries complete
        res.json({ stats });
      }
    );
  });
});

// Cloud sync endpoint (for future Firebase integration)
app.post('/api/sync/cloud', authenticateToken, requireAdmin, async (req, res) => {
  try {
    // This would implement sync with Firebase
    // For now, just return success
    res.json({ 
      success: true, 
      message: 'Cloud sync initiated (implementation pending)',
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Cloud sync error:', error);
    res.status(500).json({ error: 'Cloud sync failed' });
  }
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error('Unhandled error:', err);
  res.status(500).json({ error: 'Internal server error' });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({ error: 'Endpoint not found' });
});

// Graceful shutdown
process.on('SIGINT', () => {
  console.log('\n🛑 Shutting down gracefully...');
  db.close((err) => {
    if (err) {
      console.error('❌ Error closing database:', err.message);
    } else {
      console.log('✅ Database connection closed');
    }
    process.exit(0);
  });
});

// Start server
app.listen(PORT, '0.0.0.0', () => {
  const networkInterfaces = os.networkInterfaces();
  console.log('\n🚀 Prime POS Local Backend Server Started!');
  console.log(`📡 Port: ${PORT}`);
  console.log(`🏠 Local: http://localhost:${PORT}`);
  
  // Show all network interfaces
  Object.keys(networkInterfaces).forEach(interfaceName => {
    const interfaces = networkInterfaces[interfaceName];
    interfaces.forEach(interface => {
      if (interface.family === 'IPv4' && !interface.internal) {
        console.log(`🌐 LAN (${interfaceName}): http://${interface.address}:${PORT}`);
      }
    });
  });
  
  console.log(`🔍 Health Check: http://localhost:${PORT}/api/health`);
  console.log(`📊 Server Info: http://localhost:${PORT}/api/server/info`);
  console.log('\n✅ Server ready for LAN connections!');
});

module.exports = app;