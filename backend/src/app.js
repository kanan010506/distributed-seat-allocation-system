// src/app.js
// Express application setup. Separated from server.js so it can be
// imported in tests without binding to a port.

const express = require('express');
const morgan  = require('morgan');

const app = express();

// ── Middleware ──────────────────────────────────────────────
app.use(express.json());          // parse JSON request bodies
app.use(express.urlencoded({ extended: false })); // parse form data
app.use(morgan('dev'));            // log: METHOD /path STATUS ms

// ── Health check (no auth needed) ──────────────────────────
app.get('/health', (_req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// ── API Routes (will be added in later steps) ───────────────
app.use('/api/auth',       require('./routes/auth.routes'));
app.use('/api/students',   require('./routes/student.routes'));
app.use('/api/choices',    require('./routes/choice.routes'));
app.use('/api/allocation', require('./routes/allocation.routes'));
app.use('/api/programs',   require('./routes/program.routes'));
app.use('/api/reports',    require('./routes/report.routes'));

// ── 404 handler ─────────────────────────────────────────────
app.use((_req, res) => {
  res.status(404).json({ error: 'Route not found' });
});

// ── Global error handler (will be filled in Step 10) ────────
app.use(require('./middleware/errorHandler'));

module.exports = app;