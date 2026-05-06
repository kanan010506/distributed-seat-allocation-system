# DSAS — Distributed Seat Allocation System

> Merit-based JEE counselling & seat allocation engine modelled after JoSAA.
> Built for **UCS310 — Database Management Systems** · Thapar Institute of Engineering and Technology

**Team:** Kanan · Samriddhi Gupta · Rohan Bansal

---

## Stack

| | |
|---|---|
| **Database** | MySQL 8.0 (InnoDB) · Aiven cloud |
| **Backend** | Node.js · Express 5 · mysql2 · JWT · bcrypt |
| **Frontend** | Vanilla HTML/CSS/JS |

---

## Folder Structure

```
dsas/
├── backend/
│   ├── server.js
│   ├── .env.example
│   ├── generateHashes.js
│   └── src/
│       ├── app.js
│       ├── config/
│       │   ├── db.js
│       │   └── constants.js
│       ├── controllers/
│       │   ├── auth.controller.js
│       │   ├── student.controller.js
│       │   ├── choice.controller.js
│       │   ├── allocation.controller.js
│       │   ├── program.controller.js
│       │   ├── report.controller.js
│       │   └── college.controller.js
│       ├── middleware/
│       │   ├── auth.js
│       │   └── errorHandler.js
│       └── routes/
│           ├── auth.routes.js
│           ├── student.routes.js
│           ├── choice.routes.js
│           ├── allocation.routes.js
│           ├── program.routes.js
│           ├── report.routes.js
│           └── college.routes.js
│
├── frontend/
│   ├── index.html               # Login / Register
│   ├── js/
│   │   └── api.js               # Centralised fetch client
│   └── pages/
│       ├── admin.html
│       ├── college.html
│       └── student.html
│
└── database/
    ├── schema.sql               # All 9 tables
    ├── triggers.sql             # 10 triggers
    ├── seed.sql                 # Sample data
    ├── functions.sql            # 14 stored functions
    ├── procedures.sql           # 3 stored procedures
    ├── views.sql                # 7 views
    └── queries.sql              # 30+ demo queries
```

---

## Quick Start

### 1. Clone & install
```bash
git clone https://github.com/your-username/dsas.git
cd dsas/backend && npm install
```

### 2. Configure environment
```bash
cp .env.example .env   # fill in your Aiven credentials
```

```env
DB_HOST=your-host.aivencloud.com
DB_PORT=16576
DB_USER=avnadmin
DB_PASSWORD=your_password
DB_NAME=jee_admission_db
DB_SSL=true
DB_SSL_CA=./ca.pem
JWT_SECRET=your_secret
PORT=5001
```

### 3. Set up database
Run in this exact order:
```bash
mysql -u <user> -p <db> < database/schema.sql      # tables
mysql -u <user> -p <db> < database/triggers.sql    # triggers (before seed!)
mysql -u <user> -p <db> < database/seed.sql        # sample data
mysql -u <user> -p <db> < database/functions.sql
mysql -u <user> -p <db> < database/procedures.sql
mysql -u <user> -p <db> < database/views.sql
```

> **Aiven:** Use `schema_aiven.sql` — omits `CREATE DATABASE` / `USE` which Aiven blocks.

### 4. Run
```bash
# Backend
npm run dev          # http://localhost:5001

# Frontend — open with VS Code Live Server or:
npx serve frontend   # http://localhost:5500
```

---

## Database

9 tables · 10 triggers · 14 functions · 3 procedures · 7 views

| Table | Purpose |
|---|---|
| `INSTITUTE` | Participating colleges (IIT / NIT / IIIT / Private) |
| `PROGRAM` | Courses per institute |
| `SEAT_MATRIX` | Category-wise seats. `Available_Seats` is a stored generated column |
| `STUDENT` | Registered candidates with JEE rank |
| `CHOICE` | Ordered preference lists |
| `SEAT_ALLOCATION` | Live allocation results — **empty in seed, populated via `AllocateSeats()`** |
| `USERS` | Auth accounts (Admin · College · Student) |
| `JEE_RANK_VERIFY` | Official rank registry for registration validation |
| `ALLOCATION_AUDIT` | Immutable status change log (no FK cascades by design) |

### Core: `AllocateSeats()`
Iterates students by rank (best first) → finds their highest-preference choice with an available seat in their category → inserts into `SEAT_ALLOCATION`. Triggers handle seat counters, choice sync, and audit logging automatically. Safe to re-run.

---

## Portals

| Role | Email | Dashboard |
|---|---|---|
| Admin | `admin@jeeadmission.in` | Run allocations · view reports |
| College | `admissions@<institute>.ac.in` | Seat matrix · allocated students · confirm admissions |
| Student | Registered email | Submit choices · view allocation |

---

*UCS310 · DBMS Course Project · Thapar Institute of Engineering and Technology*
