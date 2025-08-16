# Prime POS - Project Overview

## Purpose
Prime Bar POS is a production-grade Point-of-Sale application for Android & iOS developed by Alatiris Inc. It's designed specifically for bars and restaurants with multi-role support and comprehensive order management.

## Tech Stack
- **Frontend**: Flutter (Android, iOS, optional web admin)
- **Backend**: Firebase (Auth, Firestore, Cloud Functions) or Supabase with RBAC
- **Authentication**: Google OAuth + email/password
- **Printing**: ESC/POS thermal printers (58mm & 80mm, Bluetooth/Wi-Fi)
- **Currency**: Philippine Peso (₱)
- **Timezone**: Asia/Manila

## User Roles
1. **Waiter**: Create orders by table/customer, product search, track order status
2. **Cashier**: Approve orders, handle payments, print receipts, manage refunds
3. **Kitchen Display (KDS)**: Real-time food item queue, status management
4. **Bar Display (BDS)**: Real-time alcoholic item queue, alerts
5. **Admin**: Employee management, product CRUD, inventory, reports, exports

## Core Workflow
1. Waiter creates order → PENDING_APPROVAL
2. Cashier approves → prints receipt → routes to KDS/BDS
3. Kitchen/Bar marks items Ready
4. Waiter serves → order closed
5. Inventory auto-decrements on approval

## Key Features
- Real-time order tracking and status updates
- Automatic item routing (alcohol → Bar, food → Kitchen)
- Inventory management with in/out adjustments
- Google Sheets sync and Drive export
- Offline mode with sync capability
- ESC/POS thermal printer integration
- Philippine Peso currency formatting