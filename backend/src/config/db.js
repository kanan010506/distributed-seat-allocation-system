// src/config/db.js
// Single mysql2 connection pool shared across the entire application.
// Using createPool (not createConnection) because:
//   - Pool reuses connections instead of creating a new TCP handshake per query
//   - connectionLimit caps concurrent DB usage (prevents exhausting Aiven's limit)
//   - Promise-based API lets us use async/await throughout services

const mysql = require('mysql2/promise');
require('dotenv').config();

const pool = mysql.createPool({
  host:               process.env.DB_HOST,
  port:               parseInt(process.env.DB_PORT, 10),
  user:               process.env.DB_USER,
  password:           process.env.DB_PASSWORD,
  database:           process.env.DB_NAME,
  connectionLimit:    10,      // max concurrent connections (Aiven free tier supports ~25)
  waitForConnections: true,    // queue queries instead of throwing when limit hit
  queueLimit:         0,       // 0 = unlimited queue (fine for dev; cap in prod)
  multipleStatements: false,   // SECURITY: prevents SQL injection via stacked queries
  ssl: process.env.DB_SSL === 'true' ? { rejectUnauthorized: false } : false,
  timezone: '+00:00',          // store all DATETIMEs as UTC
});

// Test the pool on startup — fail fast if credentials are wrong
pool.getConnection()
  .then(conn => {
    console.log('✅  MySQL pool connected to:', process.env.DB_NAME);
    conn.release(); // always release back to pool
  })
  .catch(err => {
    console.error('❌  MySQL connection failed:', err.message);
    process.exit(1); // crash early — no point starting with no DB
  });

module.exports = pool;