/**
 * Helper JWT: sign & verify token.
 * Dipakai oleh route auth & middleware auth.
 */
const jwt = require('jsonwebtoken');

const JWT_SECRET  = process.env.JWT_SECRET  || 'leads_monitoring_secret_key_12345';
const JWT_EXPIRES = process.env.JWT_EXPIRES || '8h';

/**
 * Buat token JWT dari payload.
 * @param {object} payload - data yang disimpan di dalam token (id, username, role, dsb.)
 * @returns {string} token JWT
 */
function signToken(payload) {
  return jwt.sign(payload, JWT_SECRET, { expiresIn: JWT_EXPIRES });
}

/**
 * Verifikasi dan decode token JWT.
 * Akan throw error kalau token invalid atau expired.
 * @param {string} token
 * @returns {object} payload yang didekode
 */
function verifyToken(token) {
  return jwt.verify(token, JWT_SECRET);
}

module.exports = { signToken, verifyToken };
