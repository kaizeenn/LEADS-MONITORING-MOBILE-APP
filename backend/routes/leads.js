const express = require('express');
const router = express.Router();
const { Lead } = require('../models');
const { authenticateToken } = require('../middleware/auth');

// Get all leads (with filters)
router.get('/', authenticateToken, async (req, res) => {
  const { user_id, wilayah_id, sumber_id, startDate, endDate } = req.query;

  try {
    const rows = await Lead.getFiltered({
      userRole: req.user.role,
      userId: req.user.id,
      filterUserId: user_id,
      wilayahId: wilayah_id,
      sumberId: sumber_id,
      startDate,
      endDate
    });
    res.json(rows);
  } catch (error) {
    res.status(500).json({ error: 'Gagal mengambil data leads.' });
  }
});

// Create lead
router.post('/', authenticateToken, async (req, res) => {
  const { wilayah_id, sumber_id, tanggal, jumlah } = req.body;

  if (!wilayah_id || !sumber_id || !tanggal || jumlah === undefined) {
    return res.status(400).json({ error: 'Semua kolom data leads wajib diisi.' });
  }

  const creatorId = req.user.id;

  try {
    const insertId = await Lead.create(wilayah_id, sumber_id, creatorId, tanggal, jumlah);
    res.status(201).json({
      id: insertId,
      wilayah_id,
      sumber_id,
      user_id: creatorId,
      tanggal,
      jumlah
    });
  } catch (error) {
    res.status(500).json({ error: 'Gagal menambahkan data leads.' });
  }
});

// Update lead
router.put('/:id', authenticateToken, async (req, res) => {
  const { id } = req.params;
  const { wilayah_id, sumber_id, tanggal, jumlah } = req.body;

  if (!wilayah_id || !sumber_id || !tanggal || jumlah === undefined) {
    return res.status(400).json({ error: 'Semua kolom data leads wajib diisi.' });
  }

  try {
    const lead = await Lead.findById(id);
    if (!lead) {
      return res.status(404).json({ error: 'Data lead tidak ditemukan.' });
    }

    if (req.user.role !== 'admin' && lead.user_id !== req.user.id) {
      return res.status(403).json({ error: 'Anda tidak memiliki hak untuk mengedit data lead orang lain.' });
    }

    await Lead.update(id, wilayah_id, sumber_id, tanggal, jumlah);
    res.json({ message: 'Data lead berhasil diperbarui.' });
  } catch (error) {
    res.status(500).json({ error: 'Gagal memperbarui data lead.' });
  }
});

// Delete lead
router.delete('/:id', authenticateToken, async (req, res) => {
  const { id } = req.params;

  try {
    const lead = await Lead.findById(id);
    if (!lead) {
      return res.status(404).json({ error: 'Data lead tidak ditemukan.' });
    }

    if (req.user.role !== 'admin' && lead.user_id !== req.user.id) {
      return res.status(403).json({ error: 'Anda tidak memiliki hak untuk menghapus data lead orang lain.' });
    }

    await Lead.delete(id);
    res.json({ message: 'Data lead berhasil dihapus.' });
  } catch (error) {
    res.status(500).json({ error: 'Gagal menghapus data lead.' });
  }
});

module.exports = router;
