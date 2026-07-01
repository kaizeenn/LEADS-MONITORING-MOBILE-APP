const db = require('../config/db');

async function findById(id) {
  const [rows] = await db.query('SELECT * FROM leads WHERE id = ? LIMIT 1', [id]);
  return rows[0] || null;
}

async function getFiltered({ userRole, userId, filterUserId, wilayahId, sumberId, startDate, endDate }) {
  let query = `
    SELECT l.*, w.nama_wilayah, s.nama_sumber, u.nama_lengkap as nama_inputter
    FROM leads l
    JOIN wilayah w ON l.wilayah_id = w.id
    JOIN sumber_leads s ON l.sumber_id = s.id
    JOIN users u ON l.user_id = u.id
    WHERE 1=1
  `;
  const queryParams = [];

  if (userRole === 'karyawan') {
    query += ' AND l.user_id = ? ';
    queryParams.push(userId);
  } else if (filterUserId) {
    query += ' AND l.user_id = ? ';
    queryParams.push(filterUserId);
  }

  if (wilayahId) {
    query += ' AND l.wilayah_id = ? ';
    queryParams.push(wilayahId);
  }

  if (sumberId) {
    query += ' AND l.sumber_id = ? ';
    queryParams.push(sumberId);
  }

  if (startDate) {
    query += ' AND l.tanggal >= ? ';
    queryParams.push(startDate);
  }

  if (endDate) {
    query += ' AND l.tanggal <= ? ';
    queryParams.push(endDate);
  }

  query += ' ORDER BY l.tanggal DESC, l.id DESC ';

  const [rows] = await db.query(query, queryParams);
  return rows;
}

async function create(wilayah_id, sumber_id, user_id, tanggal, jumlah) {
  const [result] = await db.query(
    'INSERT INTO leads (wilayah_id, sumber_id, user_id, tanggal, jumlah) VALUES (?, ?, ?, ?, ?)',
    [wilayah_id, sumber_id, user_id, tanggal, jumlah]
  );
  return result.insertId;
}

async function update(id, wilayah_id, sumber_id, tanggal, jumlah) {
  const [result] = await db.query(
    'UPDATE leads SET wilayah_id = ?, sumber_id = ?, tanggal = ?, jumlah = ? WHERE id = ?',
    [wilayah_id, sumber_id, tanggal, jumlah, id]
  );
  return result.affectedRows > 0;
}

async function deleteLead(id) {
  const [result] = await db.query('DELETE FROM leads WHERE id = ?', [id]);
  return result.affectedRows > 0;
}

module.exports = {
  findById,
  getFiltered,
  create,
  update,
  delete: deleteLead
};
