/**
 * Route manajemen wilayah.
 * Endpoint: /api/wilayah/...
 */
const express     = require('express');
const router      = express.Router();
const { Wilayah } = require('../models');
const { ok, fail }          = require('../utils/response');
const { authenticateToken } = require('../middleware/auth');

// ===== GET /api/wilayah =====
router.get('/', authenticateToken, async (req, res) => {
  try {
    const list = await Wilayah.getAll();
    return ok(res, list);
  } catch (error) {
    return fail(res, 'Gagal mengambil data wilayah.', 500, error.message);
  }
});

// ===== POST /api/wilayah =====
router.post('/', authenticateToken, async (req, res) => {
  const { nama_wilayah } = req.body;
  if (!nama_wilayah || nama_wilayah.trim() === '') {
    return fail(res, 'Nama wilayah wajib diisi.');
  }

  try {
    const insertId = await Wilayah.create(nama_wilayah.trim());
    return ok(res, { id: insertId, nama_wilayah }, 'Wilayah berhasil ditambahkan.', 201);
  } catch (error) {
    if (error.code === 'ER_DUP_ENTRY') {
      return fail(res, 'Wilayah sudah terdaftar.');
    }
    return fail(res, 'Gagal menambahkan wilayah.', 500, error.message);
  }
});

// ===== DELETE /api/wilayah/:id =====
router.delete('/:id', authenticateToken, async (req, res) => {
  const { id } = req.params;
  try {
    const isLinked = await Wilayah.isLinkedToLeads(id);
    if (isLinked) {
      return fail(res, 'Wilayah tidak bisa dihapus karena sedang digunakan oleh data leads.');
    }

    await Wilayah.delete(id);
    return ok(res, null, 'Wilayah berhasil dihapus.');
  } catch (error) {
    return fail(res, 'Gagal menghapus wilayah.', 500, error.message);
  }
});

module.exports = router;
