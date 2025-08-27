const sqlite3 = require('sqlite3').verbose();
const path = require('path');
const fs = require('fs');
const { v4: uuidv4 } = require('uuid');
const bcrypt = require('bcryptjs');

// Ensure data directory exists
const dataDir = path.join(__dirname, '..', 'data');
if (!fs.existsSync(dataDir)) {
  fs.mkdirSync(dataDir, { recursive: true });
  console.log('✅ Created data directory');
}

const dbPath = path.join(dataDir, 'prime_pos_local.db');

// Remove existing database for fresh setup
if (fs.existsSync(dbPath)) {
  fs.unlinkSync(dbPath);
  console.log('🗑️ Removed existing database');
}

const db = new sqlite3.Database(dbPath, (err) => {
  if (err) {
    console.error('❌ Error creating database:', err.message);
    process.exit(1);
  } else {
    console.log('✅ Created new SQLite database');
    setupDatabase();
  }
});

async function setupDatabase() {
  console.log('🔧 Setting up database schema...');

  const tables = [
    // Users table
    {
      name: 'users',
      sql: `CREATE TABLE users (
        id TEXT PRIMARY KEY,
        email TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        password_hash TEXT,
        role TEXT NOT NULL CHECK (role IN ('admin', 'waiter', 'cashier', 'kitchen', 'bartender')) DEFAULT 'waiter',
        is_active BOOLEAN NOT NULL DEFAULT 1,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        last_sync DATETIME
      )`
    },

    // Products table
    {
      name: 'products',
      sql: `CREATE TABLE products (
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
      )`
    },

    // Orders table
    {
      name: 'orders',
      sql: `CREATE TABLE orders (
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
      )`
    },

    // Order Items table
    {
      name: 'order_items',
      sql: `CREATE TABLE order_items (
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
      )`
    },

    // Sync Queue table
    {
      name: 'sync_queue',
      sql: `CREATE TABLE sync_queue (
        id TEXT PRIMARY KEY,
        table_name TEXT NOT NULL,
        record_id TEXT NOT NULL,
        operation TEXT NOT NULL CHECK (operation IN ('insert', 'update', 'delete')),
        data TEXT, -- JSON string
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        synced BOOLEAN DEFAULT 0
      )`
    },

    // System Settings table
    {
      name: 'system_settings',
      sql: `CREATE TABLE system_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )`
    }
  ];

  // Create tables
  for (const table of tables) {
    await new Promise((resolve, reject) => {
      db.run(table.sql, (err) => {
        if (err) {
          console.error(`❌ Error creating ${table.name} table:`, err.message);
          reject(err);
        } else {
          console.log(`✅ Created ${table.name} table`);
          resolve();
        }
      });
    });
  }

  // Insert sample data
  await insertSampleData();

  console.log('🎉 Database setup complete!');
  db.close();
}

async function insertSampleData() {
  console.log('📊 Inserting sample data...');

  // Create admin user
  const adminId = uuidv4();
  const adminPassword = await bcrypt.hash('admin123', 10);
  
  await new Promise((resolve, reject) => {
    db.run(
      'INSERT INTO users (id, email, name, password_hash, role) VALUES (?, ?, ?, ?, ?)',
      [adminId, 'admin@primepos.com', 'System Administrator', adminPassword, 'admin'],
      (err) => {
        if (err) reject(err);
        else {
          console.log('✅ Created admin user: admin@primepos.com');
          resolve();
        }
      }
    );
  });

  // Create sample staff users
  const sampleUsers = [
    { email: 'waiter1@primepos.com', name: 'John Waiter', role: 'waiter' },
    { email: 'cashier1@primepos.com', name: 'Jane Cashier', role: 'cashier' },
    { email: 'kitchen1@primepos.com', name: 'Chef Mike', role: 'kitchen' },
    { email: 'bartender1@primepos.com', name: 'Alex Bartender', role: 'bartender' }
  ];

  for (const user of sampleUsers) {
    const userId = uuidv4();
    const password = await bcrypt.hash('password123', 10);
    
    await new Promise((resolve, reject) => {
      db.run(
        'INSERT INTO users (id, email, name, password_hash, role) VALUES (?, ?, ?, ?, ?)',
        [userId, user.email, user.name, password, user.role],
        (err) => {
          if (err) reject(err);
          else {
            console.log(`✅ Created ${user.role}: ${user.email}`);
            resolve();
          }
        }
      );
    });
  }

  // Sample products
  const sampleProducts = [
    // Food items
    { name: 'Grilled Chicken', description: 'Tender grilled chicken breast', price: 350.00, category: 'Main Course', isAlcoholic: false, stock: 50 },
    { name: 'Beef Steak', description: 'Premium beef steak cooked to perfection', price: 650.00, category: 'Main Course', isAlcoholic: false, stock: 30 },
    { name: 'Fish & Chips', description: 'Crispy battered fish with fries', price: 280.00, category: 'Main Course', isAlcoholic: false, stock: 40 },
    { name: 'Caesar Salad', description: 'Fresh romaine lettuce with Caesar dressing', price: 180.00, category: 'Appetizer', isAlcoholic: false, stock: 60 },
    { name: 'Chicken Wings', description: 'Spicy buffalo chicken wings', price: 220.00, category: 'Appetizer', isAlcoholic: false, stock: 80 },
    
    // Beverages - Non-alcoholic
    { name: 'Fresh Orange Juice', description: '100% fresh orange juice', price: 120.00, category: 'Beverages', isAlcoholic: false, stock: 100 },
    { name: 'Iced Coffee', description: 'Cold brew coffee with ice', price: 150.00, category: 'Beverages', isAlcoholic: false, stock: 100 },
    { name: 'Soft Drinks', description: 'Assorted soft drinks', price: 80.00, category: 'Beverages', isAlcoholic: false, stock: 200 },
    
    // Alcoholic beverages
    { name: 'San Miguel Beer', description: 'Premium Filipino beer', price: 100.00, category: 'Beer', isAlcoholic: true, stock: 150 },
    { name: 'Red Horse Beer', description: 'Strong Filipino beer', price: 110.00, category: 'Beer', isAlcoholic: true, stock: 120 },
    { name: 'House Wine Red', description: 'House special red wine', price: 200.00, category: 'Wine', isAlcoholic: true, stock: 50 },
    { name: 'House Wine White', description: 'House special white wine', price: 200.00, category: 'Wine', isAlcoholic: true, stock: 50 },
    { name: 'Rum Coke', description: 'Classic rum and coke cocktail', price: 180.00, category: 'Cocktails', isAlcoholic: true, stock: 80 },
    { name: 'Mojito', description: 'Fresh mint mojito', price: 200.00, category: 'Cocktails', isAlcoholic: true, stock: 60 },
    { name: 'Whiskey Sour', description: 'Classic whiskey sour cocktail', price: 250.00, category: 'Cocktails', isAlcoholic: true, stock: 40 }
  ];

  for (const product of sampleProducts) {
    const productId = uuidv4();
    
    await new Promise((resolve, reject) => {
      db.run(
        'INSERT INTO products (id, name, description, price, category, is_alcoholic, stock_quantity, is_in_stock) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
        [productId, product.name, product.description, product.price, product.category, product.isAlcoholic, product.stock, product.stock > 0],
        (err) => {
          if (err) reject(err);
          else {
            console.log(`✅ Created product: ${product.name}`);
            resolve();
          }
        }
      );
    });
  }

  // System settings
  const settings = [
    ['restaurant_name', 'Prime Restaurant & Bar'],
    ['currency', 'PHP'],
    ['tax_rate', '0.12'],
    ['server_version', '1.0.0'],
    ['last_cloud_sync', new Date().toISOString()],
    ['wifi_ssid', ''],
    ['lan_server_ip', '']
  ];

  for (const [key, value] of settings) {
    await new Promise((resolve, reject) => {
      db.run(
        'INSERT INTO system_settings (key, value) VALUES (?, ?)',
        [key, value],
        (err) => {
          if (err) reject(err);
          else resolve();
        }
      );
    });
  }

  console.log('✅ Sample data inserted successfully');
  console.log('\n📋 Sample User Accounts:');
  console.log('  Admin: admin@primepos.com / admin123');
  console.log('  Waiter: waiter1@primepos.com / password123');
  console.log('  Cashier: cashier1@primepos.com / password123');
  console.log('  Kitchen: kitchen1@primepos.com / password123');
  console.log('  Bartender: bartender1@primepos.com / password123');
}

// Handle errors
process.on('uncaughtException', (err) => {
  console.error('❌ Uncaught Exception:', err);
  process.exit(1);
});

process.on('unhandledRejection', (reason, promise) => {
  console.error('❌ Unhandled Rejection at:', promise, 'reason:', reason);
  process.exit(1);
});