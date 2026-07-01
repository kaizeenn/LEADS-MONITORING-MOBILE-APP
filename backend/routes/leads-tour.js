/**
 * Route data leads tour.
 * Endpoint: /api/leads-tour/...
 */
const express      = require('express');
const router       = express.Router();
const { LeadTour } = require('../models');
const { ok, fail }          = require('../utils/response');
const { authenticateToken } = require('../middleware/auth');

// ===== GET /api/leads-tour =====
// Ambil semua leads tour dengan filter opsional.
router.get('/', authenticateToken, async (req, res) => {
  const { user_id, sumber_id, startDate, endDate, lokasi } = req.query;

  try {
    const rows = await LeadTour.getFiltered({
      userRole:     req.user.role,
      userId:       req.user.id,
      filterUserId: user_id,
      sumberId:     sumber_id,
      startDate,
      endDate,
      lokasi,
    });
    return ok(res, rows);
  } catch (error) {
    return fail(res, 'Gagal mengambil data leads tour.', 500, error.message);
  }
});

// ===== POST /api/leads-tour =====
// Tambah data lead tour baru.
router.post('/', authenticateToken, async (req, res) => {
  const { lokasi, sumber_id, tanggal, nama_client, asal_client, no_hp_client } = req.body;

  if (!lokasi || !sumber_id || !tanggal || !nama_client || !asal_client || !no_hp_client) {
    return fail(res, 'Semua kolom data leads tour wajib diisi.');
  }

  const creatorId = req.user.id;

  try {
    const insertId = await LeadTour.create(lokasi, sumber_id, creatorId, tanggal, nama_client, asal_client, no_hp_client);
    return ok(res, {
      id: insertId, lokasi, sumber_id, user_id: creatorId,
      tanggal, nama_client, asal_client, no_hp_client,
    }, 'Data lead tour berhasil ditambahkan.', 201);
  } catch (error) {
    return fail(res, 'Gagal menambahkan data leads tour.', 500, error.message);
  }
});

// ===== PUT /api/leads-tour/:id =====
// Perbarui data lead tour. Karyawan hanya bisa edit milik sendiri.
router.put('/:id', authenticateToken, async (req, res) => {
  const { id } = req.params;
  const { lokasi, sumber_id, tanggal, nama_client, asal_client, no_hp_client } = req.body;

  if (!lokasi || !sumber_id || !tanggal || !nama_client || !asal_client || !no_hp_client) {
    return fail(res, 'Semua kolom data leads tour wajib diisi.');
  }

  try {
    const lead = await LeadTour.findById(id);
    if (!lead) return fail(res, 'Data lead tour tidak ditemukan.', 404);

    if (req.user.role === 'karyawan' && lead.user_id !== req.user.id) {
      return fail(res, 'Anda tidak memiliki hak untuk mengedit data lead tour orang lain.', 403);
    }

    await LeadTour.update(id, lokasi, sumber_id, tanggal, nama_client, asal_client, no_hp_client);
    return ok(res, null, 'Data lead tour berhasil diperbarui.');
  } catch (error) {
    return fail(res, 'Gagal memperbarui data lead tour.', 500, error.message);
  }
});

// ===== DELETE /api/leads-tour/:id =====
// Hapus data lead tour. Karyawan hanya bisa hapus milik sendiri.
router.delete('/:id', authenticateToken, async (req, res) => {
  const { id } = req.params;

  try {
    const lead = await LeadTour.findById(id);
    if (!lead) return fail(res, 'Data lead tour tidak ditemukan.', 404);

    if (req.user.role === 'karyawan' && lead.user_id !== req.user.id) {
      return fail(res, 'Anda tidak memiliki hak untuk menghapus data lead tour orang lain.', 403);
    }

    await LeadTour.delete(id);
    return ok(res, null, 'Data lead tour berhasil dihapus.');
  } catch (error) {
    return fail(res, 'Gagal menghapus data lead tour.', 500, error.message);
  }
});

module.exports = router;
