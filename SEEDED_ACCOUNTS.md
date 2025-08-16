# PrimePOS Seeded Accounts

This document contains all the test accounts seeded in the database for development and testing purposes.

## Database Connection
- **Database**: `primepos_db`
- **Host**: `localhost:3306`
- **phpMyAdmin**: http://localhost:8080

## User Accounts

### Administrator
| Role | Name | Email | Password | Employee ID |
|------|------|-------|----------|-------------|
| admin | System Administrator | admin@primepos.com | admin123 | ADM001 |

### Waiters
| Role | Name | Email | Password | Employee ID |
|------|------|-------|----------|-------------|
| waiter | Maria Santos | maria.santos@primepos.com | waiter123 | WTR001 |
| waiter | Carlos Rivera | carlos.rivera@primepos.com | waiter123 | WTR002 |
| waiter | Ana Garcia | ana.garcia@primepos.com | waiter123 | WTR003 |

### Cashiers
| Role | Name | Email | Password | Employee ID |
|------|------|-------|----------|-------------|
| cashier | Pedro Garcia | pedro.garcia@primepos.com | cashier123 | CSH001 |
| cashier | Rosa Martinez | rosa.martinez@primepos.com | cashier123 | CSH002 |

### Kitchen Staff
| Role | Name | Email | Password | Employee ID |
|------|------|-------|----------|-------------|
| kitchen | Chef Miguel Reyes | miguel.reyes@primepos.com | kitchen123 | KIT001 |
| kitchen | Chef Linda Cruz | linda.cruz@primepos.com | kitchen123 | KIT002 |
| kitchen | Sous Chef Tony Lim | tony.lim@primepos.com | kitchen123 | KIT003 |

### Bartenders
| Role | Name | Email | Password | Employee ID |
|------|------|-------|----------|-------------|
| bartender | Mixologist Alex Torres | alex.torres@primepos.com | bartender123 | BAR001 |
| bartender | Bartender Sofia Lee | sofia.lee@primepos.com | bartender123 | BAR002 |

## Quick Login Reference
For quick testing, use these common credentials:

- **Admin Access**: admin@primepos.com / admin123
- **Waiter Access**: maria.santos@primepos.com / waiter123
- **Cashier Access**: pedro.garcia@primepos.com / cashier123
- **Kitchen Access**: miguel.reyes@primepos.com / kitchen123
- **Bar Access**: alex.torres@primepos.com / bartender123

## Seeded Data Summary
- **Total Users**: 11 accounts
- **Products**: 23 menu items (food & beverages)
- **Sample Orders**: 5 orders with different statuses
- **Product Modifiers**: Various add-ons and customizations

## Password Security
- All passwords are hashed using SHA256 in the database
- For production deployment, consider upgrading to bcrypt with proper salting
- Current implementation is for development/testing purposes only

## Testing Workflow
1. Start Docker containers: `docker compose up -d`
2. Access app and login with any account above
3. Test role-specific functionality
4. Use phpMyAdmin to inspect database changes
5. Test logout functionality returns to login screen

## Database Reset
To reset all data to initial seeded state:
```bash
docker compose down
docker compose up -d
```

The database will automatically reinitialize with fresh seeded data.