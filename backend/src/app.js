// src/app.js
// Express application setup. Separated from server.js so it can be
// imported in tests without binding to a port.

const express = require('express');
const morgan  = require('morgan');
const cors    = require('cors');

const app = express();

// ── Middleware ──────────────────────────────────────────────
app.use(cors({
  origin: ['http://127.0.0.1:5500', 'http://localhost:5500'],
  credentials: true
}));
app.use(express.json());
app.use(express.urlencoded({ extended: false }));
app.use(morgan('dev'));

// ── Health check (no auth needed) ──────────────────────────
app.get('/health', (_req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// ── API Routes ───────────────────────────────────────────────
app.use('/api/auth',        require('./routes/auth.routes'));
app.use('/api/students',    require('./routes/student.routes'));
app.use('/api/choices',     require('./routes/choice.routes'));
app.use('/api/allocations', require('./routes/allocation.routes'));
app.use('/api/programs',    require('./routes/program.routes'));
app.use('/api/reports',     require('./routes/report.routes'));
app.use('/api/college',     require('./routes/college.routes'));   // ← ADD THIS

// ── 404 handler ─────────────────────────────────────────────
app.use((_req, res) => {
  res.status(404).json({ error: 'Route not found' });
});

// ── Global error handler ────────────────────────────────────
app.use(require('./middleware/errorHandler'));

module.exports = app;