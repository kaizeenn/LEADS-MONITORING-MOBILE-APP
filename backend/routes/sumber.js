const express = require('express');
const router = express.Router();
const { SumberLeads } = require('../models');
const { authenticateToken, requireAdmin } = require('../middleware/auth');

// Get all lead sources
router.get('/', authenticateToken, async (req, res) => {
  try {
    const list = await SumberLeads.getAll();
    res.json(list);
  } catch (error) {
    res.status(500).json({ error: 'Gagal mengambil data sumber.' });
  }
});

// Admin: Create lead source
router.post('/', authenticateToken, requireAdmin, async (req, res) => {
  const { nama_sumber } = req.body;
  if (!nama_sumber || nama_sumber.trim() === '') {
    return res.status(400).json({ error: 'Nama sumber wajib diisi.' });
  }

  try {
    const insertId = await SumberLeads.create(nama_sumber.trim());
    res.status(201).json({ id: insertId, nama_sumber });
  } catch (error) {
    if (error.code === 'ER_DUP_ENTRY') {
      return res.status(400).json({ error: 'Sumber sudah terdaftar.' });
    }
    res.status(500).json({ error: 'Gagal menambahkan sumber leads.' });
  }
});

// Admin: Delete lead source
router.delete('/:id', authenticateToken, requireAdmin, async (req, res) => {
  const { id } = req.params;
  try {
    const isLinked = await SumberLeads.isLinkedToLeads(id);
    if (isLinked) {
      return res.status(400).json({ error: 'Sumber tidak bisa dihapus karena sedang digunakan oleh data leads.' });
    }

    await SumberLeads.delete(id);
    res.json({ message: 'Sumber berhasil dihapus.' });
  } catch (error) {
    res.status(500).json({ error: 'Gagal menghapus sumber leads.' });
  }
});

module.exports = router;
