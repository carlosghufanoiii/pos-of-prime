# Prime POS Backend API

Node.js/Express backend with Firebase Admin SDK for secure user role management.

## Features

- 🔐 **Secure Role Management**: Uses Firebase Admin SDK with custom claims
- 👥 **User Management**: Create, update, delete users with proper role validation
- 🛡️ **Admin-Only Operations**: Protected endpoints for user management
- ⚡ **Role Validation**: Server-side role validation with fallback defaults
- 📊 **Audit Trail**: Track who creates/updates users

## Role Assignment Logic

- **Default Role**: `waiter` (if no role provided or invalid role)
- **Admin Assignment**: Only when explicitly requested by existing admin
- **Role Validation**: Server-side validation prevents client manipulation
- **Custom Claims**: Firebase Auth custom claims for secure role checking

## Setup

1. **Install Dependencies**:
   ```bash
   npm install
   ```

2. **Configure Environment**:
   - Copy `.env.example` to `.env`
   - Add your Firebase Admin SDK credentials
   - Get credentials from Firebase Console > Project Settings > Service Accounts

3. **Start Server**:
   ```bash
   # Development
   npm run dev
   
   # Production
   npm start
   ```

## API Endpoints

### Authentication Required
All endpoints except `/health` require Firebase ID token in `Authorization: Bearer <token>` header.

### User Management (Admin Only)

**POST** `/api/users` - Create new user
```json
{
  "email": "user@example.com",
  "password": "securePassword123",
  "name": "User Name",
  "role": "waiter" // Optional: admin, waiter, cashier, kitchen, bartender
}
```

**GET** `/api/users` - Get all users

**PUT** `/api/users/:userId` - Update user
```json
{
  "name": "Updated Name",
  "role": "cashier",
  "isActive": true
}
```

**DELETE** `/api/users/:userId` - Delete user

### User Profile

**GET** `/api/user/me` - Get current user profile

### Health Check

**GET** `/health` - Server health status

## Role Hierarchy

1. **admin** - Full system access, user management
2. **waiter** - Order creation, customer service
3. **cashier** - Payment processing, order approval
4. **kitchen** - Food preparation queue
5. **bartender** - Bar preparation queue

## Security Features

- Firebase Admin SDK for server-side validation
- Custom claims for role-based access control
- Admin verification middleware
- Input validation and sanitization
- Error handling with security in mind

## Error Handling

- Proper HTTP status codes
- Detailed error messages for development
- Security-conscious error responses
- Firebase-specific error handling