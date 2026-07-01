/**
 * Middleware autentikasi memakai JWT.
 * Mendukung role: karyawan, admin, owner.
 */
const jwt = require('jsonwebtoken');

const JWT_SECRET = process.env.JWT_SECRET || 'leads_monitoring_secret_key_12345';

// Mengambil token dari header Authorization.
// Format yang benar: Authorization: Bearer TOKEN_JWT
function extractToken(req) {
  const header = req.headers.authorization;
  if (!header || !header.startsWith('Bearer ')) return null;
  return header.slice(7);
}

// Middleware umum: hanya mengecek apakah user sudah login.
function authenticateToken(req, res, next) {
  try {
    const token = extractToken(req);
    if (!token) {
      return res.status(401).json({ success: false, error: 'Akses ditolak. Token tidak ditemukan.' });
    }

    const decoded = jwt.verify(token, JWT_SECRET);
    req.user = decoded;
    next();
  } catch (err) {
    if (err.name === 'TokenExpiredError') {
      return res.status(401).json({ success: false, error: 'Token expired, silakan login ulang.' });
    }
    return res.status(403).json({ success: false, error: 'Token tidak valid.' });
  }
}

// Middleware khusus admin.
function requireAdmin(req, res, next) {
  if (req.user.role !== 'admin' && req.user.role !== 'owner') {
    return res.status(403).json({ success: false, error: 'Akses khusus administrator.' });
  }
  next();
}

// Middleware khusus owner.
function requireOwner(req, res, next) {
  if (req.user.role !== 'owner') {
    return res.status(403).json({ success: false, error: 'Akses khusus owner.' });
  }
  next();
}

module.exports = { authenticateToken, requireAdmin, requireOwner };
