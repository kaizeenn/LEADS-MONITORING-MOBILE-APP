const db = require('../config/db');

async function findById(id) {
  const [rows] = await db.query('SELECT * FROM leads_tour WHERE id = ? LIMIT 1', [id]);
  return rows[0] || null;
}

async function getFiltered({ userRole, userId, filterUserId, sumberId, startDate, endDate, lokasi }) {
  let query = `
    SELECT lt.*, s.nama_sumber, u.nama_lengkap as nama_inputter
    FROM leads_tour lt
    JOIN sumber_leads s ON lt.sumber_id = s.id
    JOIN users u ON lt.user_id = u.id
    WHERE 1=1
  `;
  const queryParams = [];

  if (userRole === 'karyawan') {
    query += ' AND lt.user_id = ? ';
    queryParams.push(userId);
  } else if (filterUserId) {
    query += ' AND lt.user_id = ? ';
    queryParams.push(filterUserId);
  }

  if (sumberId) {
    query += ' AND lt.sumber_id = ? ';
    queryParams.push(sumberId);
  }

  if (startDate) {
    query += ' AND lt.tanggal >= ? ';
    queryParams.push(startDate);
  }

  if (endDate) {
    query += ' AND lt.tanggal <= ? ';
    queryParams.push(endDate);
  }

  if (lokasi) {
    query += ' AND lt.lokasi LIKE ? ';
    queryParams.push(`%${lokasi.trim()}%`);
  }

  query += ' ORDER BY lt.tanggal DESC, lt.id DESC ';

  const [rows] = await db.query(query, queryParams);
  return rows;
}

async function create(lokasi, sumber_id, user_id, tanggal, nama_client, asal_client, no_hp_client) {
  const [result] = await db.query(
    'INSERT INTO leads_tour (lokasi, sumber_id, user_id, tanggal, nama_client, asal_client, no_hp_client) VALUES (?, ?, ?, ?, ?, ?, ?)',
    [lokasi.trim(), sumber_id, user_id, tanggal, nama_client.trim(), asal_client.trim(), no_hp_client.trim()]
  );
  return result.insertId;
}

async function update(id, lokasi, sumber_id, tanggal, nama_client, asal_client, no_hp_client) {
  const [result] = await db.query(
    'UPDATE leads_tour SET lokasi = ?, sumber_id = ?, tanggal = ?, nama_client = ?, asal_client = ?, no_hp_client = ? WHERE id = ?',
    [lokasi.trim(), sumber_id, tanggal, nama_client.trim(), asal_client.trim(), no_hp_client.trim(), id]
  );
  return result.affectedRows > 0;
}

async function deleteLeadTour(id) {
  const [result] = await db.query('DELETE FROM leads_tour WHERE id = ?', [id]);
  return result.affectedRows > 0;
}

module.exports = {
  findById,
  getFiltered,
  create,
  update,
  delete: deleteLeadTour
};
