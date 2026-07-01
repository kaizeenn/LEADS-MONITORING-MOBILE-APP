/**
 * Route data leads marketing.
 * Endpoint: /api/leads/...
 */
const express  = require('express');
const router   = express.Router();
const { Lead } = require('../models');
const { ok, fail }          = require('../utils/response');
const { authenticateToken } = require('../middleware/auth');

// ===== GET /api/leads =====
// Ambil semua leads marketing dengan filter opsional.
router.get('/', authenticateToken, async (req, res) => {
  const { user_id, wilayah_id, sumber_id, startDate, endDate } = req.query;

  try {
    const rows = await Lead.getFiltered({
      userRole:     req.user.role,
      userId:       req.user.id,
      filterUserId: user_id,
      wilayahId:    wilayah_id,
      sumberId:     sumber_id,
      startDate,
      endDate,
    });
    return ok(res, rows);
  } catch (error) {
    return fail(res, 'Gagal mengambil data leads.', 500, error.message);
  }
});

// ===== POST /api/leads =====
// Tambah data lead baru.
router.post('/', authenticateToken, async (req, res) => {
  const { wilayah_id, sumber_id, tanggal, jumlah } = req.body;

  if (!wilayah_id || !sumber_id || !tanggal || jumlah === undefined) {
    return fail(res, 'Semua kolom data leads wajib diisi.');
  }

  const creatorId = req.user.id;

  try {
    const insertId = await Lead.create(wilayah_id, sumber_id, creatorId, tanggal, jumlah);
    return ok(res, { id: insertId, wilayah_id, sumber_id, user_id: creatorId, tanggal, jumlah }, 'Data lead berhasil ditambahkan.', 201);
  } catch (error) {
    return fail(res, 'Gagal menambahkan data leads.', 500, error.message);
  }
});

// ===== PUT /api/leads/:id =====
// Perbarui data lead. Karyawan hanya bisa edit milik sendiri.
router.put('/:id', authenticateToken, async (req, res) => {
  const { id }                               = req.params;
  const { wilayah_id, sumber_id, tanggal, jumlah } = req.body;

  if (!wilayah_id || !sumber_id || !tanggal || jumlah === undefined) {
    return fail(res, 'Semua kolom data leads wajib diisi.');
  }

  try {
    const lead = await Lead.findById(id);
    if (!lead) return fail(res, 'Data lead tidak ditemukan.', 404);

    if (req.user.role === 'karyawan' && lead.user_id !== req.user.id) {
      return fail(res, 'Anda tidak memiliki hak untuk mengedit data lead orang lain.', 403);
    }

    await Lead.update(id, wilayah_id, sumber_id, tanggal, jumlah);
    return ok(res, null, 'Data lead berhasil diperbarui.');
  } catch (error) {
    return fail(res, 'Gagal memperbarui data lead.', 500, error.message);
  }
});

// ===== DELETE /api/leads/:id =====
// Hapus data lead. Karyawan hanya bisa hapus milik sendiri.
router.delete('/:id', authenticateToken, async (req, res) => {
  const { id } = req.params;

  try {
    const lead = await Lead.findById(id);
    if (!lead) return fail(res, 'Data lead tidak ditemukan.', 404);

    if (req.user.role === 'karyawan' && lead.user_id !== req.user.id) {
      return fail(res, 'Anda tidak memiliki hak untuk menghapus data lead orang lain.', 403);
    }

    await Lead.delete(id);
    return ok(res, null, 'Data lead berhasil dihapus.');
  } catch (error) {
    return fail(res, 'Gagal menghapus data lead.', 500, error.message);
  }
});

module.exports = router;
