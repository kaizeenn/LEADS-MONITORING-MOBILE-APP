const express = require('express');
const router = express.Router();
const { Wilayah } = require('../models');
const { authenticateToken } = require('../middleware/auth');

// Get all regions
router.get('/', authenticateToken, async (req, res) => {
  try {
    const list = await Wilayah.getAll();
    res.json(list);
  } catch (error) {
    res.status(500).json({ error: 'Gagal mengambil data wilayah.' });
  }
});

// Create region
router.post('/', authenticateToken, async (req, res) => {
  const { nama_wilayah } = req.body;
  if (!nama_wilayah || nama_wilayah.trim() === '') {
    return res.status(400).json({ error: 'Nama wilayah wajib diisi.' });
  }

  try {
    const insertId = await Wilayah.create(nama_wilayah.trim());
    res.status(201).json({ id: insertId, nama_wilayah });
  } catch (error) {
    if (error.code === 'ER_DUP_ENTRY') {
      return res.status(400).json({ error: 'Wilayah sudah terdaftar.' });
    }
    res.status(500).json({ error: 'Gagal menambahkan wilayah.' });
  }
});

// Delete region
router.delete('/:id', authenticateToken, async (req, res) => {
  const { id } = req.params;
  try {
    const isLinked = await Wilayah.isLinkedToLeads(id);
    if (isLinked) {
      return res.status(400).json({ error: 'Wilayah tidak bisa dihapus karena sedang digunakan oleh data leads.' });
    }

    await Wilayah.delete(id);
    res.json({ message: 'Wilayah berhasil dihapus.' });
  } catch (error) {
    res.status(500).json({ error: 'Gagal menghapus wilayah.' });
  }
});

module.exports = router;
