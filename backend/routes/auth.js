const express = require('express');
const router = express.Router();
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { User } = require('../models');
const { authenticateToken, requireAdmin } = require('../middleware/auth');

const JWT_SECRET = process.env.JWT_SECRET || 'leads_monitoring_secret_key_12345';

// Register User
router.post('/register', async (req, res) => {
  const { nama_lengkap, username, password, role, bagian } = req.body;
  if (!nama_lengkap || !username || !password) {
    return res.status(400).json({ error: 'Nama lengkap, username, dan password wajib diisi.' });
  }

  try {
    const hashedPassword = await bcrypt.hash(password, 10);
    const userRole = (role === 'admin' || role === 'owner') ? role : 'karyawan';
    const userBagian = (userRole === 'admin' || userRole === 'owner') ? null : (bagian || 'marketing');

    await User.create(nama_lengkap, username, hashedPassword, userRole, userBagian);
    res.status(201).json({ message: 'Registrasi berhasil!' });
  } catch (error) {
    if (error.code === 'ER_DUP_ENTRY') {
      return res.status(400).json({ error: 'Username sudah terdaftar.' });
    }
    res.status(500).json({ error: 'Gagal melakukan registrasi.' });
  }
});

// Login User
router.post('/login', async (req, res) => {
  const { username, password } = req.body;
  if (!username || !password) {
    return res.status(400).json({ error: 'Username dan password wajib diisi.' });
  }

  try {
    const user = await User.findByUsername(username.trim());
    if (!user) {
      return res.status(400).json({ error: 'Username tidak ditemukan.' });
    }

    const validPassword = await bcrypt.compare(password, user.password);
    if (!validPassword) {
      return res.status(400).json({ error: 'Password salah.' });
    }

    const token = jwt.sign(
      { id: user.id, nama_lengkap: user.nama_lengkap, username: user.username, role: user.role, bagian: user.bagian },
      JWT_SECRET,
      { expiresIn: '7d' }
    );

    res.json({
      token,
      user: {
        id: user.id,
        nama_lengkap: user.nama_lengkap,
        username: user.username,
        role: user.role,
        bagian: user.bagian
      }
    });
  } catch (error) {
    res.status(500).json({ error: 'Terjadi kesalahan pada server.' });
  }
});

// Get Profile
router.get('/me', authenticateToken, async (req, res) => {
  res.json({ user: req.user });
});

module.exports = router;
