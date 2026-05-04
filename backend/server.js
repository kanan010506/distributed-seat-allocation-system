// server.js
// Entry point. Only concern: bind the app to a port.
// Keeping this separate from app.js allows app.js to be
// imported in tests without starting a real HTTP server.

require('dotenv').config();       // load .env FIRST — before any other require
const app  = require('./src/app');

// DB pool import triggers the startup connection test
require('./src/config/db');

const PORT = process.env.PORT || 5000;

app.listen(PORT, () => {
  console.log(`🚀  Server running on http://localhost:${PORT}`);
  console.log(`    Environment: ${process.env.NODE_ENV}`);
});