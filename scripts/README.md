# Prime POS Migration Scripts

This directory contains migration and setup scripts for the Prime POS Appwrite backend.

## Quick Start

1. **Install dependencies:**
   ```bash
   cd scripts
   npm install
   ```

2. **Run migration:**
   ```bash
   npm run migrate
   ```

## Available Scripts

### `migrate.js` - Complete Database Migration
**Recommended:** Use this script for setting up your database.

```bash
node migrate.js
# or
npm run migrate
```

**Features:**
- ✅ Reads configuration from `.env` file
- ✅ Creates collections (users, products, orders)
- ✅ Sets up attributes and permissions
- ✅ Seeds initial test data
- ✅ Smart detection of existing data
- ✅ Detailed progress logging

### Legacy Scripts

- `setup-appwrite.sh` - Bash script (use migrate.js instead)
- `seed-data.js` - Data seeding only (use migrate.js instead)

## Configuration

The migration script reads from your `.env` file in the project root:

```env
APPWRITE_ENDPOINT=http://localhost/v1
APPWRITE_PROJECT_ID=prime-pos
APPWRITE_API_KEY=your_api_key_here
APPWRITE_DATABASE_ID=prime_pos_db
```

## What Gets Created

### Collections:
1. **users** - System users (admin, waiter, cashier, kitchen)
2. **products** - Menu items with pricing and categories
3. **orders** - Customer orders with real-time status tracking

### Sample Data:
- 4 users with different roles
- 5 sample products (food and beverages)
- Ready for testing all POS workflows

## Troubleshooting

### Database Not Found
```
❌ Database 'prime_pos_db' not found
```
**Solution:** Create the database in Appwrite Console first.

### Collection Already Exists
```
⚠️ Collection 'Users' already exists, skipping creation
```
**Normal:** Script detects existing collections and skips them.

### Permission Errors
```
❌ Failed to create collection: Missing permissions
```
**Solution:** Check your API key has database permissions.

## Next Steps

After running the migration:

1. Open Appwrite Console: http://localhost
2. Add Flutter platform (Web: localhost)
3. Run: `flutter run -d chrome`
4. Test real-time updates across all modules