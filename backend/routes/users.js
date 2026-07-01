/**
 * Route manajemen user: CRUD user oleh admin.
 * Endpoint: /api/users/...
 */
const express  = require('express');
const router   = express.Router();
const bcrypt   = require('bcryptjs');
const { User } = require('../models');
const { ok, fail }                       = require('../utils/response');
const { authenticateToken, requireAdmin } = require('../middleware/auth');

// ===== GET /api/users =====
// Admin: ambil semua user.
router.get('/', authenticateToken, requireAdmin, async (req, res) => {
  try {
    const users = await User.getAll();
    return ok(res, users);
  } catch (error) {
    return fail(res, 'Gagal mengambil data user.', 500, error.message);
  }
});

// ===== POST /api/users =====
// Admin: tambah user baru.
router.post('/', authenticateToken, requireAdmin, async (req, res) => {
  const { nama_lengkap, username, password, role, bagian } = req.body;
  if (!nama_lengkap || !username || !password || !role) {
    return fail(res, 'Nama lengkap, username, password, dan role wajib diisi.');
  }

  try {
    const hashedPassword = await bcrypt.hash(password, 10);
    const userRole   = (role === 'admin' || role === 'owner') ? role : 'karyawan';
    const userBagian = (userRole === 'admin' || userRole === 'owner') ? null : (bagian || 'marketing');

    const insertId = await User.create(nama_lengkap, username, hashedPassword, userRole, userBagian);
    return ok(res, { id: insertId, nama_lengkap, username, role: userRole, bagian: userBagian }, 'User berhasil ditambahkan.', 201);
  } catch (error) {
    if (error.code === 'ER_DUP_ENTRY') {
      return fail(res, 'Username sudah terdaftar.');
    }
    return fail(res, 'Gagal menambahkan user baru.', 500, error.message);
  }
});

// ===== DELETE /api/users/:id =====
// Admin: hapus user.
router.delete('/:id', authenticateToken, requireAdmin, async (req, res) => {
  const { id } = req.params;
  if (parseInt(id) === req.user.id) {
    return fail(res, 'Anda tidak dapat menghapus akun Anda sendiri.');
  }

  try {
    await User.delete(id);
    return ok(res, null, 'User berhasil dihapus.');
  } catch (error) {
    return fail(res, 'Gagal menghapus user.', 500, error.message);
  }
});

// ===== PUT /api/users/:id/password =====
// Admin: ganti password user lain.
router.put('/:id/password', authenticateToken, requireAdmin, async (req, res) => {
  const { id }      = req.params;
  const { password } = req.body;

  if (!password || password.trim() === '') {
    return fail(res, 'Password baru wajib diisi.');
  }

  try {
    const user = await User.findById(id);
    if (!user) {
      return fail(res, 'User tidak ditemukan.', 404);
    }

    const hashedPassword = await bcrypt.hash(password, 10);
    await User.updatePassword(id, hashedPassword);
    return ok(res, null, 'Password user berhasil diperbarui.');
  } catch (error) {
    return fail(res, 'Gagal memperbarui password user.', 500, error.message);
  }
});

module.exports = router;
