const express = require('express');
const router = express.Router();
const bcrypt = require('bcryptjs');
const { User } = require('../models');
const { authenticateToken, requireAdmin } = require('../middleware/auth');

// Admin: Get all users
router.get('/', authenticateToken, requireAdmin, async (req, res) => {
  try {
    const users = await User.getAll();
    res.json(users);
  } catch (error) {
    res.status(500).json({ error: 'Gagal mengambil data user.' });
  }
});

// Admin: Add new user
router.post('/', authenticateToken, requireAdmin, async (req, res) => {
  const { nama_lengkap, username, password, role, bagian } = req.body;
  if (!nama_lengkap || !username || !password || !role) {
    return res.status(400).json({ error: 'Nama lengkap, username, password, dan role wajib diisi.' });
  }

  try {
    const hashedPassword = await bcrypt.hash(password, 10);
    const userRole = (role === 'admin' || role === 'owner') ? role : 'karyawan';
    const userBagian = (userRole === 'admin' || userRole === 'owner') ? null : (bagian || 'marketing');

    const insertId = await User.create(nama_lengkap, username, hashedPassword, userRole, userBagian);

    res.status(201).json({
      id: insertId,
      nama_lengkap,
      username,
      role: userRole,
      bagian: userBagian
    });
  } catch (error) {
    if (error.code === 'ER_DUP_ENTRY') {
      return res.status(400).json({ error: 'Username sudah terdaftar.' });
    }
    res.status(500).json({ error: 'Gagal menambahkan user baru.' });
  }
});

// Admin: Delete user
router.delete('/:id', authenticateToken, requireAdmin, async (req, res) => {
  const { id } = req.params;
  if (parseInt(id) === req.user.id) {
    return res.status(400).json({ error: 'Anda tidak dapat menghapus akun Anda sendiri.' });
  }

  try {
    await User.delete(id);
    res.json({ message: 'User berhasil dihapus.' });
  } catch (error) {
    res.status(500).json({ error: 'Gagal menghapus user.' });
  }
});

module.exports = router;
