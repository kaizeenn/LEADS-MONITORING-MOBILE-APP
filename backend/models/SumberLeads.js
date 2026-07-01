const db = require('../config/db');

async function getAll() {
  const [rows] = await db.query('SELECT * FROM sumber_leads ORDER BY nama_sumber ASC');
  return rows;
}

async function create(namaSumber) {
  const [result] = await db.query('INSERT INTO sumber_leads (nama_sumber) VALUES (?)', [namaSumber]);
  return result.insertId;
}

async function isLinkedToLeads(id) {
  const [rows] = await db.query('SELECT id FROM leads WHERE sumber_id = ? LIMIT 1', [id]);
  return rows.length > 0;
}

async function deleteSumber(id) {
  const [result] = await db.query('DELETE FROM sumber_leads WHERE id = ?', [id]);
  return result.affectedRows > 0;
}

module.exports = {
  getAll,
  create,
  isLinkedToLeads,
  delete: deleteSumber
};
