#!/usr/bin/env node

const { Client, Databases, Users, ID, Permission, Role } = require('node-appwrite');
const fs = require('fs');
const path = require('path');

// Load environment variables from .env file
function loadEnv() {
    const envPath = path.join(__dirname, '..', '.env');
    
    if (!fs.existsSync(envPath)) {
        console.error('❌ .env file not found. Please create one based on .env.example');
        process.exit(1);
    }

    const envContent = fs.readFileSync(envPath, 'utf8');
    const envVars = {};
    
    envContent.split('\n').forEach(line => {
        const [key, value] = line.split('=');
        if (key && value) {
            envVars[key.trim()] = value.trim();
        }
    });
    
    return envVars;
}

// Load configuration from .env
const env = loadEnv();
const PROJECT_ID = env.APPWRITE_PROJECT_ID;
const DATABASE_ID = env.APPWRITE_DATABASE_ID;
const ENDPOINT = env.APPWRITE_ENDPOINT;
const API_KEY = env.APPWRITE_API_KEY;

// Validate configuration
if (!PROJECT_ID || !DATABASE_ID || !ENDPOINT || !API_KEY) {
    console.error('❌ Missing required environment variables in .env file:');
    console.error('   APPWRITE_PROJECT_ID, APPWRITE_DATABASE_ID, APPWRITE_ENDPOINT, APPWRITE_API_KEY');
    process.exit(1);
}

// Initialize Appwrite client
const client = new Client()
    .setEndpoint(ENDPOINT)
    .setProject(PROJECT_ID)
    .setKey(API_KEY);

const databases = new Databases(client);
const users = new Users(client);

// Collection configurations
const collections = {
    users: {
        id: 'users',
        name: 'Users',
        permissions: [
            Permission.read(Role.users()),
            Permission.create(Role.users()),
            Permission.update(Role.users()),
            Permission.delete(Role.users())
        ],
        attributes: [
            { type: 'string', key: 'email', size: 255, required: true },
            { type: 'string', key: 'displayName', size: 255, required: true },
            { type: 'string', key: 'role', size: 50, required: true },
            { type: 'boolean', key: 'isActive', required: true },
            { type: 'string', key: 'authUserId', size: 50, required: false }
        ]
    },
    products: {
        id: 'products',
        name: 'Products',
        permissions: [
            Permission.read(Role.any()),
            Permission.create(Role.users()),
            Permission.update(Role.users()),
            Permission.delete(Role.users())
        ],
        attributes: [
            { type: 'string', key: 'name', size: 255, required: true },
            { type: 'string', key: 'sku', size: 100, required: true },
            { type: 'float', key: 'price', required: true },
            { type: 'string', key: 'category', size: 100, required: true },
            { type: 'boolean', key: 'isAlcoholic', required: true },
            { type: 'boolean', key: 'isActive', required: true },
            { type: 'string', key: 'description', size: 1000, required: false },
            { type: 'integer', key: 'stockQuantity', required: true },
            { type: 'string', key: 'preparationArea', size: 50, required: true }
        ]
    },
    orders: {
        id: 'orders',
        name: 'Orders',
        permissions: [
            Permission.read(Role.users()),
            Permission.create(Role.users()),
            Permission.update(Role.users()),
            Permission.delete(Role.users())
        ],
        attributes: [
            { type: 'string', key: 'orderNumber', size: 50, required: true },
            { type: 'string', key: 'waiterId', size: 50, required: true },
            { type: 'string', key: 'waiterName', size: 255, required: true },
            { type: 'string', key: 'tableNumber', size: 50, required: false },
            { type: 'string', key: 'customerName', size: 255, required: false },
            { type: 'string', key: 'status', size: 50, required: true },
            { type: 'float', key: 'subtotal', required: true },
            { type: 'float', key: 'taxAmount', required: true },
            { type: 'float', key: 'discount', required: false },
            { type: 'float', key: 'total', required: true },
            { type: 'string', key: 'paymentMethod', size: 50, required: false },
            { type: 'string', key: 'cashierId', size: 50, required: false },
            { type: 'string', key: 'cashierName', size: 255, required: false },
            { type: 'string', key: 'notes', size: 1000, required: false },
            { type: 'string', key: 'items', size: 10000, required: true }
        ]
    }
};

// Sample data with auth accounts
const sampleData = {
    users: [
        {
            email: 'admin@primepos.com',
            displayName: 'Administrator',
            role: 'admin',
            isActive: true,
            password: '123123123'
        },
        {
            email: 'waiter@primepos.com',
            displayName: 'John Smith',
            role: 'waiter',
            isActive: true,
            password: '123123123'
        },
        {
            email: 'cashier@primepos.com',
            displayName: 'Sarah Johnson',
            role: 'cashier',
            isActive: true,
            password: '123123123'
        },
        {
            email: 'kitchen@primepos.com',
            displayName: 'Mike Chen',
            role: 'kitchen',
            isActive: true,
            password: '123123123'
        },
    ],
    products: [
        {
            name: 'Classic Beef Burger',
            sku: 'BURGER-001',
            price: 12.99,
            category: 'Main Course',
            isAlcoholic: false,
            isActive: true,
            description: 'Juicy beef patty with lettuce, tomato, and special sauce',
            stockQuantity: 50,
            preparationArea: 'kitchen',
        },
        {
            name: 'Margherita Pizza',
            sku: 'PIZZA-001',
            price: 14.99,
            category: 'Main Course',
            isAlcoholic: false,
            isActive: true,
            description: 'Fresh mozzarella, tomato sauce, and basil',
            stockQuantity: 30,
            preparationArea: 'kitchen',
        },
        {
            name: 'Local Draft Beer',
            sku: 'BEER-001',
            price: 5.99,
            category: 'Beverages',
            isAlcoholic: true,
            isActive: true,
            description: 'Fresh local beer on tap',
            stockQuantity: 100,
            preparationArea: 'bar',
        },
        {
            name: 'Mojito',
            sku: 'COCKTAIL-001',
            price: 8.99,
            category: 'Beverages',
            isAlcoholic: true,
            isActive: true,
            description: 'Classic Cuban cocktail with mint and lime',
            stockQuantity: 50,
            preparationArea: 'bar',
        },
        {
            name: 'Espresso',
            sku: 'COFFEE-001',
            price: 3.99,
            category: 'Beverages',
            isAlcoholic: false,
            isActive: true,
            description: 'Strong Italian coffee',
            stockQuantity: 200,
            preparationArea: 'bar',
        },
    ],
    orders: [
        {
            orderNumber: 'ORD-001',
            waiterId: 'waiter_001',
            waiterName: 'John Smith',
            tableNumber: 'T-05',
            customerName: 'Customer A',
            status: 'approved',
            subtotal: 18.98,
            taxAmount: 1.90,
            discount: 0,
            total: 20.88,
            paymentMethod: null,
            cashierId: null,
            cashierName: null,
            notes: 'Customer prefers extra ice',
            items: JSON.stringify([
                {
                    productId: 'beer_001',
                    product: {
                        id: 'beer_001',
                        name: 'Local Draft Beer',
                        price: 5.99,
                        preparationArea: 'bar',
                        isAlcoholic: true
                    },
                    quantity: 2,
                    unitPrice: 5.99,
                    totalPrice: 11.98
                },
                {
                    productId: 'coffee_001',
                    product: {
                        id: 'coffee_001',
                        name: 'Espresso',
                        price: 3.99,
                        preparationArea: 'bar',
                        isAlcoholic: false
                    },
                    quantity: 1,
                    unitPrice: 3.99,
                    totalPrice: 3.99
                },
                {
                    productId: 'espresso_002',
                    product: {
                        id: 'espresso_002',
                        name: 'Espresso',
                        price: 3.99,
                        preparationArea: 'bar',
                        isAlcoholic: false
                    },
                    quantity: 1,
                    unitPrice: 3.99,
                    totalPrice: 3.99
                }
            ])
        },
        {
            orderNumber: 'ORD-002',
            waiterId: 'waiter_001',
            waiterName: 'John Smith',
            tableNumber: 'T-03',
            customerName: 'Customer B',
            status: 'inPrep',
            subtotal: 8.99,
            taxAmount: 0.90,
            discount: 0,
            total: 9.89,
            paymentMethod: null,
            cashierId: null,
            cashierName: null,
            notes: 'Extra mint please',
            items: JSON.stringify([
                {
                    productId: 'cocktail_001',
                    product: {
                        id: 'cocktail_001',
                        name: 'Mojito',
                        price: 8.99,
                        preparationArea: 'bar',
                        isAlcoholic: true
                    },
                    quantity: 1,
                    unitPrice: 8.99,
                    totalPrice: 8.99
                }
            ])
        },
        {
            orderNumber: 'ORD-003',
            waiterId: 'waiter_001',
            waiterName: 'John Smith',
            tableNumber: 'T-02',
            customerName: 'Customer C',
            status: 'pendingApproval',
            subtotal: 12.99,
            taxAmount: 1.30,
            discount: 0,
            total: 14.29,
            paymentMethod: null,
            cashierId: null,
            cashierName: null,
            notes: 'Waiting for cashier approval',
            items: JSON.stringify([
                {
                    productId: 'burger_001',
                    product: {
                        id: 'burger_001',
                        name: 'Classic Beef Burger',
                        price: 12.99,
                        preparationArea: 'kitchen',
                        isAlcoholic: false
                    },
                    quantity: 1,
                    unitPrice: 12.99,
                    totalPrice: 12.99
                }
            ])
        },
        {
            orderNumber: 'ORD-004',
            waiterId: 'waiter_001',
            waiterName: 'John Smith',
            tableNumber: 'T-08',
            customerName: 'Customer D',
            status: 'ready',
            subtotal: 27.97,
            taxAmount: 2.80,
            discount: 0,
            total: 30.77,
            paymentMethod: null,
            cashierId: null,
            cashierName: null,
            notes: 'Table for anniversary dinner',
            items: JSON.stringify([
                {
                    productId: 'burger_001',
                    product: {
                        id: 'burger_001',
                        name: 'Classic Beef Burger',
                        price: 12.99,
                        preparationArea: 'kitchen',
                        isAlcoholic: false
                    },
                    quantity: 1,
                    unitPrice: 12.99,
                    totalPrice: 12.99
                },
                {
                    productId: 'pizza_001',
                    product: {
                        id: 'pizza_001',
                        name: 'Margherita Pizza',
                        price: 14.99,
                        preparationArea: 'kitchen',
                        isAlcoholic: false
                    },
                    quantity: 1,
                    unitPrice: 14.99,
                    totalPrice: 14.99
                }
            ])
        },
        {
            orderNumber: 'ORD-004',
            waiterId: 'waiter_001',
            waiterName: 'John Smith',
            tableNumber: 'T-12',
            customerName: 'Customer D',
            status: 'served',
            subtotal: 14.98,
            taxAmount: 1.50,
            discount: 0,
            total: 16.48,
            paymentMethod: 'card',
            cashierId: 'cashier_001',
            cashierName: 'Sarah Johnson',
            notes: 'Customer paid with credit card',
            items: JSON.stringify([
                {
                    productId: 'beer_001',
                    product: {
                        id: 'beer_001',
                        name: 'Local Draft Beer',
                        price: 5.99,
                        preparationArea: 'bar',
                        isAlcoholic: true
                    },
                    quantity: 1,
                    unitPrice: 5.99,
                    totalPrice: 5.99
                },
                {
                    productId: 'cocktail_001',
                    product: {
                        id: 'cocktail_001',
                        name: 'Mojito',
                        price: 8.99,
                        preparationArea: 'bar',
                        isAlcoholic: true
                    },
                    quantity: 1,
                    unitPrice: 8.99,
                    totalPrice: 8.99
                }
            ])
        }
    ]
};

// Helper functions
async function checkDatabaseExists() {
    try {
        await databases.get(DATABASE_ID);
        return true;
    } catch (error) {
        return false;
    }
}

async function checkCollectionExists(collectionId) {
    try {
        await databases.getCollection(DATABASE_ID, collectionId);
        return true;
    } catch (error) {
        return false;
    }
}

async function createCollection(collectionConfig) {
    const { id, name, permissions } = collectionConfig;
    
    console.log(`📝 Creating collection: ${name}`);
    
    try {
        await databases.createCollection(
            DATABASE_ID,
            id,
            name,
            permissions
        );
        console.log(`✅ Collection '${name}' created successfully`);
        return true;
    } catch (error) {
        console.error(`❌ Failed to create collection '${name}':`, error.message);
        return false;
    }
}

async function createAttribute(collectionId, attribute) {
    const { type, key, required } = attribute;
    
    try {
        switch (type) {
            case 'string':
                await databases.createStringAttribute(
                    DATABASE_ID,
                    collectionId,
                    key,
                    attribute.size,
                    required,
                    attribute.defaultValue,
                    attribute.array || false
                );
                break;
            case 'integer':
                await databases.createIntegerAttribute(
                    DATABASE_ID,
                    collectionId,
                    key,
                    required,
                    attribute.min,
                    attribute.max,
                    attribute.defaultValue,
                    attribute.array || false
                );
                break;
            case 'float':
                await databases.createFloatAttribute(
                    DATABASE_ID,
                    collectionId,
                    key,
                    required,
                    attribute.min,
                    attribute.max,
                    attribute.defaultValue,
                    attribute.array || false
                );
                break;
            case 'boolean':
                await databases.createBooleanAttribute(
                    DATABASE_ID,
                    collectionId,
                    key,
                    required,
                    attribute.defaultValue,
                    attribute.array || false
                );
                break;
            default:
                throw new Error(`Unsupported attribute type: ${type}`);
        }
        
        console.log(`  ✅ Created ${type} attribute: ${key}`);
        return true;
    } catch (error) {
        console.error(`  ❌ Failed to create attribute '${key}':`, error.message);
        return false;
    }
}

async function createAuthUser(userData) {
    const { email, password, displayName } = userData;
    
    try {
        // Check if user already exists
        try {
            const existingUsers = await users.list([`email="${email}"`]);
            if (existingUsers.users.length > 0) {
                console.log(`  ⚠️  Auth user ${email} already exists, skipping auth creation`);
                return existingUsers.users[0].$id;
            }
        } catch (error) {
            // User doesn't exist, continue with creation
        }
        
        // Create auth account
        const authUser = await users.create(
            ID.unique(),
            email,
            undefined, // phone (optional)
            password,
            displayName
        );
        
        console.log(`  ✅ Created auth account: ${email}`);
        return authUser.$id;
        
    } catch (error) {
        console.error(`  ❌ Failed to create auth account for ${email}:`, error.message);
        return null;
    }
}

async function seedCollection(collectionId, data) {
    console.log(`🌱 Seeding collection: ${collectionId}`);
    
    let successCount = 0;
    
    for (const item of data) {
        try {
            let documentData = { ...item };
            
            // For users collection, create auth account first
            if (collectionId === 'users' && item.password) {
                console.log(`👤 Creating auth account for: ${item.displayName}`);
                const authUserId = await createAuthUser(item);
                
                if (authUserId) {
                    // Remove password from document data and add auth user ID
                    const { password, ...userDocData } = documentData;
                    documentData = {
                        ...userDocData,
                        authUserId: authUserId
                    };
                } else {
                    // Skip creating document if auth creation failed
                    continue;
                }
            }
            
            // Create the document
            await databases.createDocument(
                DATABASE_ID,
                collectionId,
                ID.unique(),
                documentData
            );
            successCount++;
            console.log(`  ✅ Created document: ${item.name || item.displayName || item.orderNumber || 'Document'}`);
        } catch (error) {
            console.error(`  ❌ Failed to create document:`, error.message);
        }
    }
    
    console.log(`📊 Successfully seeded ${successCount}/${data.length} documents in ${collectionId}`);
    return successCount;
}

async function runMigration() {
    console.log('🚀 Starting Prime POS Migration...\n');
    
    // Configuration summary
    console.log('📋 Configuration:');
    console.log(`   Project ID: ${PROJECT_ID}`);
    console.log(`   Database ID: ${DATABASE_ID}`);
    console.log(`   Endpoint: ${ENDPOINT}`);
    console.log(`   API Key: ${API_KEY.substring(0, 20)}...`);
    console.log('');

    try {
        // Check if database exists
        console.log('🔍 Checking database...');
        const dbExists = await checkDatabaseExists();
        
        if (!dbExists) {
            console.error(`❌ Database '${DATABASE_ID}' not found. Please create it in Appwrite Console first.`);
            process.exit(1);
        }
        
        console.log(`✅ Database '${DATABASE_ID}' found\n`);

        // Process each collection
        for (const [collectionKey, collectionConfig] of Object.entries(collections)) {
            console.log(`\n🔧 Processing collection: ${collectionConfig.name}`);
            
            // Check if collection exists
            const collectionExists = await checkCollectionExists(collectionConfig.id);
            
            if (collectionExists) {
                console.log(`⚠️  Collection '${collectionConfig.name}' already exists, skipping creation`);
                
                // Collection exists, check if authUserId attribute exists for users collection
                if (collectionConfig.id === 'users') {
                    try {
                        const collection = await databases.getCollection(DATABASE_ID, collectionConfig.id);
                        const hasAuthUserIdAttribute = collection.attributes.some(attr => attr.key === 'authUserId');
                        
                        if (!hasAuthUserIdAttribute) {
                            console.log(`🔧 Adding missing authUserId attribute to users collection...`);
                            await createAttribute(collectionConfig.id, { 
                                type: 'string', 
                                key: 'authUserId', 
                                size: 50, 
                                required: false  // Make it optional to avoid conflicts
                            });
                            await new Promise(resolve => setTimeout(resolve, 2000));
                        }
                    } catch (error) {
                        console.error(`⚠️  Could not check attributes for ${collectionConfig.name}:`, error.message);
                    }
                }
            } else {
                // Create collection
                const created = await createCollection(collectionConfig);
                if (!created) continue;
                
                // Wait a moment for collection to be ready
                await new Promise(resolve => setTimeout(resolve, 1000));
                
                // Create attributes
                console.log(`🏗️  Creating attributes for ${collectionConfig.name}:`);
                for (const attribute of collectionConfig.attributes) {
                    await createAttribute(collectionConfig.id, attribute);
                    // Small delay between attribute creation
                    await new Promise(resolve => setTimeout(resolve, 200));
                }
                
                // Wait for attributes to be ready
                await new Promise(resolve => setTimeout(resolve, 2000));
            }
            
            // Check if collection has data
            try {
                const existingDocs = await databases.listDocuments(DATABASE_ID, collectionConfig.id);
                if (existingDocs.documents.length > 0) {
                    console.log(`📊 Collection '${collectionConfig.name}' already has ${existingDocs.documents.length} documents, skipping seeding`);
                } else {
                    // Seed data if available
                    if (sampleData[collectionKey]) {
                        await seedCollection(collectionConfig.id, sampleData[collectionKey]);
                    }
                }
            } catch (error) {
                console.error(`⚠️  Could not check existing data for '${collectionConfig.name}':`, error.message);
                // Try to seed anyway
                if (sampleData[collectionKey]) {
                    await seedCollection(collectionConfig.id, sampleData[collectionKey]);
                }
            }
        }

        console.log('\n🎉 Migration completed successfully!');
        console.log('\n👥 Auth Accounts Created:');
        console.log('   📧 admin@primepos.com    🔐 123123123  (Administrator)');
        console.log('   📧 waiter@primepos.com   🔐 123123123  (John Smith - Waiter)');
        console.log('   📧 cashier@primepos.com  🔐 123123123  (Sarah Johnson - Cashier)');
        console.log('   📧 kitchen@primepos.com  🔐 123123123  (Mike Chen - Kitchen)');
        console.log('\n📋 Next steps:');
        console.log('1. Open Appwrite Console: http://localhost');
        console.log('2. Add Flutter platform (Web: localhost)');
        console.log('3. Run: flutter run -d chrome');
        console.log('4. Login with any of the accounts above (password: 123123123)');
        console.log('5. Test the POS system with real-time updates\n');
        
    } catch (error) {
        console.error('❌ Migration failed:', error);
        process.exit(1);
    }
}

// Handle command line arguments
const args = process.argv.slice(2);
const command = args[0];

if (command === '--help' || command === '-h') {
    console.log(`
Prime POS Migration Script

Usage:
  node migrate.js [command]

Commands:
  (no command)  Run full migration (create collections + seed data)
  --help, -h    Show this help message

Environment:
  Reads configuration from .env file in project root.
  Required variables:
    - APPWRITE_PROJECT_ID
    - APPWRITE_DATABASE_ID  
    - APPWRITE_ENDPOINT
    - APPWRITE_API_KEY

Examples:
  node migrate.js           # Run full migration
  npm run migrate           # Run via package.json script
    `);
    process.exit(0);
}

// Run migration
if (require.main === module) {
    runMigration();
}

module.exports = { runMigration, loadEnv, collections, sampleData };