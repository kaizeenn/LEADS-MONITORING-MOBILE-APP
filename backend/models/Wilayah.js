const db = require('../config/db');

async function getAll() {
  const [rows] = await db.query('SELECT * FROM wilayah ORDER BY nama_wilayah ASC');
  return rows;
}

async function create(namaWilayah) {
  const [result] = await db.query('INSERT INTO wilayah (nama_wilayah) VALUES (?)', [namaWilayah]);
  return result.insertId;
}

async function isLinkedToLeads(id) {
  const [rows] = await db.query('SELECT id FROM leads WHERE wilayah_id = ? LIMIT 1', [id]);
  return rows.length > 0;
}

async function deleteWilayah(id) {
  const [result] = await db.query('DELETE FROM wilayah WHERE id = ?', [id]);
  return result.affectedRows > 0;
}

module.exports = {
  getAll,
  create,
  isLinkedToLeads,
  delete: deleteWilayah
};
