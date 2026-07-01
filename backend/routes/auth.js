/**
 * Route autentikasi: login, register, profil.
 * Endpoint: /api/auth/...
 */
const express  = require('express');
const router   = express.Router();
const bcrypt   = require('bcryptjs');
const { User } = require('../models');
const { signToken }              = require('../utils/jwt');
const { ok, fail }               = require('../utils/response');
const { authenticateToken }      = require('../middleware/auth');

// ===== POST /api/auth/register =====
// Buat akun karyawan baru (hanya admin yang boleh, sudah difilter dari route users).
router.post('/register', async (req, res) => {
  const { nama_lengkap, username, password, role, bagian } = req.body;
  if (!nama_lengkap || !username || !password) {
    return fail(res, 'Nama lengkap, username, dan password wajib diisi.');
  }

  try {
    const hashedPassword = await bcrypt.hash(password, 10);
    const userRole   = (role === 'admin' || role === 'owner') ? role : 'karyawan';
    const userBagian = (userRole === 'admin' || userRole === 'owner') ? null : (bagian || 'marketing');

    await User.create(nama_lengkap, username, hashedPassword, userRole, userBagian);
    return ok(res, null, 'Registrasi berhasil!', 201);
  } catch (error) {
    if (error.code === 'ER_DUP_ENTRY') {
      return fail(res, 'Username sudah terdaftar.');
    }
    return fail(res, 'Gagal melakukan registrasi.', 500);
  }
});

// ===== POST /api/auth/login =====
// Verifikasi username + password, kembalikan JWT.
router.post('/login', async (req, res) => {
  const { username, password } = req.body;
  if (!username || !password) {
    return fail(res, 'Username dan password wajib diisi.');
  }

  try {
    const user = await User.findByUsername(username.trim());
    if (!user) {
      return fail(res, 'Username tidak ditemukan.');
    }

    const validPassword = await bcrypt.compare(password, user.password);
    if (!validPassword) {
      return fail(res, 'Password salah.');
    }

    // Buat token JWT dengan payload user.
    const payload = {
      id:           user.id,
      nama_lengkap: user.nama_lengkap,
      username:     user.username,
      role:         user.role,
      bagian:       user.bagian,
    };
    const token = signToken(payload);

    return ok(res, {
      token,
      user: {
        id:           user.id,
        nama_lengkap: user.nama_lengkap,
        username:     user.username,
        role:         user.role,
        bagian:       user.bagian,
      },
    }, 'Login berhasil.');
  } catch (error) {
    return fail(res, 'Terjadi kesalahan pada server.', 500, error.message);
  }
});

// ===== GET /api/auth/me =====
// Kembalikan data user yang sedang login berdasarkan token.
router.get('/me', authenticateToken, (req, res) => {
  return ok(res, { user: req.user });
});

module.exports = router;
