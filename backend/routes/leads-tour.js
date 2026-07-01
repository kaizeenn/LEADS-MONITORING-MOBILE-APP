const express = require('express');
const router = express.Router();
const { LeadTour } = require('../models');
const { authenticateToken } = require('../middleware/auth');

// Get all tour leads (with filters)
router.get('/', authenticateToken, async (req, res) => {
  const { user_id, sumber_id, startDate, endDate, lokasi } = req.query;

  try {
    const rows = await LeadTour.getFiltered({
      userRole: req.user.role,
      userId: req.user.id,
      filterUserId: user_id,
      sumberId: sumber_id,
      startDate,
      endDate,
      lokasi
    });
    res.json(rows);
  } catch (error) {
    res.status(500).json({ error: 'Gagal mengambil data leads tour.' });
  }
});

// Create tour lead
router.post('/', authenticateToken, async (req, res) => {
  const { lokasi, sumber_id, tanggal, nama_client, asal_client, no_hp_client } = req.body;

  if (!lokasi || !sumber_id || !tanggal || !nama_client || !asal_client || !no_hp_client) {
    return res.status(400).json({ error: 'Semua kolom data leads tour wajib diisi.' });
  }

  const creatorId = req.user.id;

  try {
    const insertId = await LeadTour.create(lokasi, sumber_id, creatorId, tanggal, nama_client, asal_client, no_hp_client);
    res.status(201).json({
      id: insertId,
      lokasi,
      sumber_id,
      user_id: creatorId,
      tanggal,
      nama_client,
      asal_client,
      no_hp_client
    });
  } catch (error) {
    res.status(500).json({ error: 'Gagal menambahkan data leads tour.' });
  }
});

// Update tour lead
router.put('/:id', authenticateToken, async (req, res) => {
  const { id } = req.params;
  const { lokasi, sumber_id, tanggal, nama_client, asal_client, no_hp_client } = req.body;

  if (!lokasi || !sumber_id || !tanggal || !nama_client || !asal_client || !no_hp_client) {
    return res.status(400).json({ error: 'Semua kolom data leads tour wajib diisi.' });
  }

  try {
    const lead = await LeadTour.findById(id);
    if (!lead) {
      return res.status(404).json({ error: 'Data lead tour tidak ditemukan.' });
    }

    if (req.user.role !== 'admin' && lead.user_id !== req.user.id) {
      return res.status(403).json({ error: 'Anda tidak memiliki hak untuk mengedit data lead tour orang lain.' });
    }

    await LeadTour.update(id, lokasi, sumber_id, tanggal, nama_client, asal_client, no_hp_client);
    res.json({ message: 'Data lead tour berhasil diperbarui.' });
  } catch (error) {
    res.status(500).json({ error: 'Gagal memperbarui data lead tour.' });
  }
});

// Delete tour lead
router.delete('/:id', authenticateToken, async (req, res) => {
  const { id } = req.params;

  try {
    const lead = await LeadTour.findById(id);
    if (!lead) {
      return res.status(404).json({ error: 'Data lead tour tidak ditemukan.' });
    }

    if (req.user.role !== 'admin' && lead.user_id !== req.user.id) {
      return res.status(403).json({ error: 'Anda tidak memiliki hak untuk menghapus data lead tour orang lain.' });
    }

    await LeadTour.delete(id);
    res.json({ message: 'Data lead tour berhasil dihapus.' });
  } catch (error) {
    res.status(500).json({ error: 'Gagal menghapus data lead tour.' });
  }
});

module.exports = router;
