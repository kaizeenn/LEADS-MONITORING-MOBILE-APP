/**
 * Route manajemen sumber leads.
 * Endpoint: /api/sumber/...
 */
const express         = require('express');
const router          = express.Router();
const { SumberLeads } = require('../models');
const { ok, fail }                       = require('../utils/response');
const { authenticateToken, requireAdmin } = require('../middleware/auth');

// ===== GET /api/sumber =====
router.get('/', authenticateToken, async (req, res) => {
  try {
    const list = await SumberLeads.getAll();
    return ok(res, list);
  } catch (error) {
    return fail(res, 'Gagal mengambil data sumber leads.', 500, error.message);
  }
});

// ===== POST /api/sumber =====
// Admin: tambah sumber leads baru.
router.post('/', authenticateToken, requireAdmin, async (req, res) => {
  const { nama_sumber } = req.body;
  if (!nama_sumber || nama_sumber.trim() === '') {
    return fail(res, 'Nama sumber wajib diisi.');
  }

  try {
    const insertId = await SumberLeads.create(nama_sumber.trim());
    return ok(res, { id: insertId, nama_sumber }, 'Sumber leads berhasil ditambahkan.', 201);
  } catch (error) {
    if (error.code === 'ER_DUP_ENTRY') {
      return fail(res, 'Sumber sudah terdaftar.');
    }
    return fail(res, 'Gagal menambahkan sumber leads.', 500, error.message);
  }
});

// ===== DELETE /api/sumber/:id =====
// Admin: hapus sumber leads.
router.delete('/:id', authenticateToken, requireAdmin, async (req, res) => {
  const { id } = req.params;
  try {
    const isLinked = await SumberLeads.isLinkedToLeads(id);
    if (isLinked) {
      return fail(res, 'Sumber tidak bisa dihapus karena sedang digunakan oleh data leads.');
    }

    await SumberLeads.delete(id);
    return ok(res, null, 'Sumber leads berhasil dihapus.');
  } catch (error) {
    return fail(res, 'Gagal menghapus sumber leads.', 500, error.message);
  }
});

module.exports = router;
