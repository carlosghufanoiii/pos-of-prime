#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

console.log('🔧 Prime POS - Firebase Admin SDK Setup');
console.log('=' * 50);

const envPath = path.join(__dirname, '.env');
const projectId = 'prime-pos-system';

console.log('\n📋 Steps to get Firebase Admin SDK credentials:');
console.log('1. Go to Firebase Console: https://console.firebase.google.com/');
console.log(`2. Select project: ${projectId}`);
console.log('3. Go to Project Settings (gear icon)');
console.log('4. Navigate to "Service accounts" tab');
console.log('5. Click "Generate new private key"');
console.log('6. Download the JSON file');
console.log('7. Run this script with the JSON file path:');
console.log('   node setup-firebase-admin.js /path/to/service-account.json');
console.log('\n' + '=' * 50);

// Check if JSON file path is provided
const jsonPath = process.argv[2];

if (!jsonPath) {
  console.log('\n⚠️  No service account JSON file provided.');
  console.log('Please download the service account key and run:');
  console.log(`node setup-firebase-admin.js /path/to/service-account.json`);
  process.exit(1);
}

if (!fs.existsSync(jsonPath)) {
  console.log(`\n❌ File not found: ${jsonPath}`);
  console.log('Please check the file path and try again.');
  process.exit(1);
}

try {
  // Read the service account JSON
  const serviceAccount = JSON.parse(fs.readFileSync(jsonPath, 'utf8'));
  
  // Validate required fields
  const requiredFields = [
    'project_id', 
    'private_key_id', 
    'private_key', 
    'client_email', 
    'client_id'
  ];
  
  for (const field of requiredFields) {
    if (!serviceAccount[field]) {
      throw new Error(`Missing required field: ${field}`);
    }
  }
  
  // Update .env file
  const envContent = `# Firebase Admin SDK Configuration
FIREBASE_PROJECT_ID=${serviceAccount.project_id}
FIREBASE_PRIVATE_KEY_ID=${serviceAccount.private_key_id}
FIREBASE_PRIVATE_KEY="${serviceAccount.private_key.replace(/\n/g, '\\n')}"
FIREBASE_CLIENT_EMAIL=${serviceAccount.client_email}
FIREBASE_CLIENT_ID=${serviceAccount.client_id}

# Server Configuration
PORT=3001
NODE_ENV=development`;

  fs.writeFileSync(envPath, envContent);
  
  console.log('\n✅ Firebase Admin SDK credentials configured successfully!');
  console.log(`📄 Updated: ${envPath}`);
  console.log('\n🚀 You can now start the server with:');
  console.log('   npm start');
  console.log('   # or for development:');
  console.log('   npm run dev');
  
} catch (error) {
  console.log(`\n❌ Error processing service account file: ${error.message}`);
  console.log('Please make sure the file is a valid Firebase service account JSON.');
  process.exit(1);
}