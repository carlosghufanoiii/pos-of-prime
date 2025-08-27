#!/bin/bash

# Prime POS Local Backend Startup Script

echo "🚀 Starting Prime POS Local Backend..."

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed. Please install Node.js 16+ first."
    exit 1
fi

# Check if we're in the right directory
if [ ! -f "package.json" ]; then
    echo "❌ package.json not found. Please run this script from the backend directory."
    exit 1
fi

# Create data directory if it doesn't exist
mkdir -p data
mkdir -p logs

# Install dependencies if node_modules doesn't exist
if [ ! -d "node_modules" ]; then
    echo "📦 Installing dependencies..."
    npm install
fi

# Setup database if it doesn't exist
if [ ! -f "data/prime_pos_local.db" ]; then
    echo "🗃️ Setting up database with sample data..."
    npm run setup
fi

# Create .env file if it doesn't exist
if [ ! -f ".env" ]; then
    echo "⚙️ Creating default .env file..."
    cat > .env << EOL
# Prime POS Local Server Configuration
PORT=3000
JWT_SECRET=prime-pos-secret-change-in-production-$(date +%s)

# Default Admin Account
DEFAULT_ADMIN_EMAIL=admin@primepos.com
DEFAULT_ADMIN_PASSWORD=admin123

# Firebase Configuration (optional - for cloud sync)
# FIREBASE_PROJECT_ID=your-project-id
# FIREBASE_PRIVATE_KEY=your-private-key
# FIREBASE_CLIENT_EMAIL=your-client-email
EOL
    echo "✅ .env file created with default configuration"
fi

# Start the server
echo "🎬 Starting server..."
echo "📝 Logs will be saved to logs/server.log"
echo ""
echo "🔗 The server will display network addresses when ready"
echo "📱 Flutter apps will auto-discover the server on the same Wi-Fi network"
echo ""
echo "⭐ Default admin account: admin@primepos.com / admin123"
echo ""
echo "Press Ctrl+C to stop the server"
echo "=================================================================================="

# Start server with logging
node lan-server.js 2>&1 | tee logs/server.log