Prime Bar POS — Made by Alatiris Inc.
(Android & iOS Cross-Platform POS System for Bars & Restaurants in ■ PHP)
Goal
Build a production-grade Point-of-Sale app called Prime Bar POS for Android & iOS (and optional
web admin). Developed and branded by Alatiris Inc. Roles: Waiter, Cashier, Kitchen, Bartender,
Admin. Core flow: Waiter creates order → Cashier approves & prints receipt → Kitchen prepares
food → Bartender prepares alcoholic drinks. Supports ■ Philippine Peso, full inventory in/out
adjustments, editable products in Admin, and Excel export + Google Sheets sync.
Tech Stack
- Flutter (Android, iOS; optional web for admin) - Backend: Firebase (Auth, Firestore, Cloud
Functions) or Supabase with RBAC - Auth: Google OAuth + email/password option - Printing:
ESC/POS thermal printers (58mm & 80mm, Bluetooth/Wi-Fi) - Timezone: Asia/Manila, Currency: ■
Philippine Peso
User Roles & Permissions
Waiter
- Create orders by table or customer name - Product search by category, modifiers, notes - Items
tagged isAlcoholic: true auto-route to Bar, others to Kitchen - Submit → status
PENDING_APPROVAL - Track order: Pending → Approved → In-Prep → Ready → Served
Cashier
- View all Pending Approval orders - Edit qty, apply VAT, service charges, discounts - On Approve +
Pay: 1. Print customer receipt 2. Auto-send Kitchen ticket (non-alcohol) & Bar ticket (alcohol) — no
prices on tickets 3. Update status to APPROVED/IN_PREP - Payment: cash, card, e-wallet
placeholder - Reprint, refund/void (admin PIN for large voids) - End-of-day Z Report
Kitchen Display (KDS)
- Real-time queue for food items - Change status: In-Prep → Ready - Display notes, modifiers, prep
timers
Bar Display (BDS)
- Real-time queue for alcoholic items - Change status: In-Prep → Ready - Alert cashier if item
needs support
Admin (Management)
- Create/manage employee accounts (Waiter, Cashier, Kitchen, Bartender, Admin) - Reset
passwords, disable users, assign shifts - Products: CRUD (with isAlcoholic toggle, category, SKU,
price, tax class, modifiers) - Inventory: - Track stock on hand - In/Out adjustments with reason
(delivery, spoilage, manual) - Prevent negative stock (optional setting) - Bulk import/edit via
CSV/XLSX - Tables/areas, pricing rules, promos - Reports: sales by period, category, item, staff;
voids audit; prep times - Export: Excel/XLSX & CSV; Google Sheets sync (per order + nightly
snapshot to Google Drive)
Workflow
1. Waiter creates order → PENDING_APPROVAL 2. Cashier approves → prints receipt → routes
to KDS/BDS 3. Kitchen/Bar marks items Ready 4. Waiter serves → order closed 5. Inventory
auto-decrements on approval; admin adjustments allowed
Google Integration
- Google Login for all roles - Sheets export: per-order append to “Sales” & “LineItems” sheets -
Drive snapshot: nightly CSV dump (Sales & LineItems) - Admin sets Google Sheet ID & Drive folder
ID in config
Acceptance Criteria
- End-to-end order flow functions with real printer - Correct item routing (alcohol → Bar; non-alcohol
→ Kitchen) - PHP currency formatting with ■ symbol - Editable products & inventory - Working
Google Sheets sync + Drive export - Offline mode with sync