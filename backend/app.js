/**
 * Express app — definisi middleware & routes.
 * Tidak listen di sini; itu tugas server.js.
 */
const express = require('express');
const cors    = require('cors');
const morgan  = require('morgan');
const path    = require('path');

const app = express();

// ===== Global middleware =====
// CORS: terima FRONTEND_URL (csv di .env) + default localhost dev port
const envOrigins = (process.env.FRONTEND_URL || '')
  .split(',')
  .map((s) => s.trim())
  .filter(Boolean);

const allowedOrigins = new Set([
  ...envOrigins,
  'http://localhost:5173',
  'http://127.0.0.1:5173',
]);

app.use(cors({
  origin: (origin, cb) => {
    // izinkan tanpa origin (curl/Postman) & yang ada di whitelist
    if (!origin || allowedOrigins.has(origin)) return cb(null, true);
    return cb(new Error(`CORS: origin ${origin} tidak diizinkan`));
  },
  credentials: true,
}));

// Supaya backend bisa membaca body JSON dari frontend.
app.use(express.json({ limit: '10mb' }));

// Supaya backend juga bisa membaca form-urlencoded bila diperlukan.
app.use(express.urlencoded({ extended: true }));

if (process.env.NODE_ENV === 'development') {
  app.use(morgan('dev'));
}

// ===== Health check =====
app.get('/api/health', (req, res) => {
  res.json({
    success: true,
    message: 'Leads Monitoring API is running',
    timestamp: new Date().toISOString(),
    env: process.env.NODE_ENV,
  });
});

// ===== Routes =====
// Setiap file route berisi endpoint + logic query SQL langsung.
app.use('/api/auth',       require('./routes/auth'));
app.use('/api/users',      require('./routes/users'));
app.use('/api/wilayah',    require('./routes/wilayah'));
app.use('/api/sumber',     require('./routes/sumber'));
app.use('/api/leads',      require('./routes/leads'));
app.use('/api/leads-tour', require('./routes/leads-tour'));
app.use('/api',            require('./routes/dashboard')); // /api/dashboard & /api/dashboard-tour

// ===== Frontend production build =====
// Tanpa Nginx: Express juga melayani file frontend React/Vite dari folder frontend/dist.
const frontendDistPath = path.join(__dirname, '../frontend/dist');
app.use(express.static(frontendDistPath));

// React Router fallback: semua route non-API diarahkan ke index.html.
app.get('*', (req, res, next) => {
  if (req.path.startsWith('/api')) {
    return next();
  }
  res.sendFile(path.join(frontendDistPath, 'index.html'));
});

// ===== 404 handler =====
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: `Endpoint ${req.method} ${req.originalUrl} tidak ditemukan`,
  });
});

// ===== Global error handler =====
app.use((err, req, res, next) => {
  console.error('🔥 Error:', err);
  res.status(err.status || 500).json({
    success: false,
    message: err.message || 'Internal server error',
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack }),
  });
});

module.exports = app;
