const db = require('../config/db');

async function findById(id) {
  const [rows] = await db.query('SELECT id, nama_lengkap, username, role, bagian, created_at FROM users WHERE id = ? LIMIT 1', [id]);
  return rows[0] || null;
}

async function findByUsername(username) {
  const [rows] = await db.query('SELECT * FROM users WHERE username = ? LIMIT 1', [username]);
  return rows[0] || null;
}

async function getAll() {
  const [rows] = await db.query('SELECT id, nama_lengkap, username, role, bagian, created_at FROM users ORDER BY nama_lengkap ASC');
  return rows;
}

async function create(nama_lengkap, username, hashedPassword, role, bagian) {
  const [result] = await db.query(
    'INSERT INTO users (nama_lengkap, username, password, role, bagian) VALUES (?, ?, ?, ?, ?)',
    [nama_lengkap, username, hashedPassword, role, bagian]
  );
  return result.insertId;
}

async function deleteUser(id) {
  const [result] = await db.query('DELETE FROM users WHERE id = ?', [id]);
  return result.affectedRows > 0;
}

module.exports = {
  findById,
  findByUsername,
  getAll,
  create,
  delete: deleteUser
};
