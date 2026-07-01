const express = require('express');
const cors = require('cors');

const app = express();

// ===== Global middleware =====
app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// ===== Health check =====
app.get('/api/health', (req, res) => {
  res.json({
    success: true,
    message: 'Leads Monitoring API is running',
    timestamp: new Date().toISOString(),
  });
});

// ===== Routes =====
app.use('/api/auth', require('./routes/auth'));
app.use('/api/wilayah', require('./routes/wilayah'));
app.use('/api/sumber', require('./routes/sumber'));
app.use('/api/leads', require('./routes/leads'));
app.use('/api/leads-tour', require('./routes/leads-tour'));
app.use('/api', require('./routes/dashboard')); // /api/dashboard & /api/dashboard-tour

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
  });
});

module.exports = app;
