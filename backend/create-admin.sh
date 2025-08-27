#!/bin/bash

echo "🔐 Prime POS - Create Admin Account"
echo "================================="

# Check if server is running
if ! curl -s http://localhost:3001/health > /dev/null; then
    echo "❌ Backend server is not running!"
    echo "Please start the server first:"
    echo "   node production-server.js"
    exit 1
fi

echo ""
echo "📝 Enter admin account details:"
echo ""

# Get email
read -p "Admin Email: " email
if [ -z "$email" ]; then
    echo "❌ Email is required!"
    exit 1
fi

# Get password
read -s -p "Password: " password
echo ""
if [ -z "$password" ]; then
    echo "❌ Password is required!"
    exit 1
fi

# Get name
read -p "Full Name: " name
if [ -z "$name" ]; then
    echo "❌ Name is required!"
    exit 1
fi

echo ""
echo "Creating admin account..."

# Create admin user
RESULT=$(curl -s -X POST \
    -H "Authorization: Bearer demo-token" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"$email\",\"password\":\"$password\",\"name\":\"$name\",\"role\":\"admin\"}" \
    http://localhost:3001/api/users)

# Check if successful
if echo "$RESULT" | grep -q '"success":true'; then
    USER_ROLE=$(echo "$RESULT" | jq -r '.user.role')
    USER_ID=$(echo "$RESULT" | jq -r '.user.id')
    
    echo "✅ Admin account created successfully!"
    echo ""
    echo "📋 Account Details:"
    echo "   Email: $email"
    echo "   Name: $name"
    echo "   Role: $USER_ROLE"
    echo "   ID: $USER_ID"
    echo ""
    echo "🔐 Login Credentials:"
    echo "   Username: $email"
    echo "   Password: [hidden]"
    echo ""
    echo "🎯 This admin can now:"
    echo "   ✅ Create/manage users"
    echo "   ✅ Assign roles properly"
    echo "   ✅ Access admin panel"
    
else
    echo "❌ Failed to create admin account!"
    echo ""
    echo "Error details:"
    echo "$RESULT" | jq -r '.error // "Unknown error"'
fi