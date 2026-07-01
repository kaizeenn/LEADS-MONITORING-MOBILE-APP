const express = require('express');
const router = express.Router();
const pool = require('../config/db');
const { authenticateToken } = require('../middleware/auth');

// Dashboard Tour Stats
router.get('/dashboard-tour', authenticateToken, async (req, res) => {
  const isKaryawan = req.user.role === 'karyawan';
  const userId = req.user.id;

  const userFilter = isKaryawan ? ' AND user_id = ? ' : ' AND 1=1 ';
  const userParams = isKaryawan ? [userId] : [];

  try {
    const today = new Date().toISOString().split('T')[0];
    const curMonth = today.substring(0, 7) + '%';
    const curYear = today.substring(0, 4) + '%';

    // 1. Totals
    const [[{ todayTotal }]] = await pool.query(
      `SELECT COUNT(*) as todayTotal FROM leads_tour WHERE tanggal = ? ${userFilter}`,
      [today, ...userParams]
    );

    const [[{ monthTotal }]] = await pool.query(
      `SELECT COUNT(*) as monthTotal FROM leads_tour WHERE tanggal LIKE ? ${userFilter}`,
      [curMonth, ...userParams]
    );

    const [[{ yearTotal }]] = await pool.query(
      `SELECT COUNT(*) as yearTotal FROM leads_tour WHERE tanggal LIKE ? ${userFilter}`,
      [curYear, ...userParams]
    );

    // 2. Best Lokasi
    const [lokasiBest] = await pool.query(
      `SELECT lokasi as name, COUNT(*) as total
       FROM leads_tour
       WHERE 1=1 ${userFilter}
       GROUP BY lokasi
       ORDER BY total DESC LIMIT 1`,
      userParams
    );
    const bestLokasi = lokasiBest.length > 0 ? lokasiBest[0].name : '-';

    // 3. Best Sumber
    const [sumberBest] = await pool.query(
      `SELECT s.nama_sumber as name, COUNT(*) as total
       FROM leads_tour lt
       JOIN sumber_leads s ON lt.sumber_id = s.id
       WHERE 1=1 ${userFilter}
       GROUP BY lt.sumber_id
       ORDER BY total DESC LIMIT 1`,
      userParams
    );
    const bestSumber = sumberBest.length > 0 ? sumberBest[0].name : '-';

    // 4. Daily Trend
    const [dailyTrend] = await pool.query(
      `SELECT tanggal as date, DATE_FORMAT(tanggal, '%d/%m') as label, COUNT(*) as total
       FROM leads_tour
       WHERE 1=1 ${userFilter}
       GROUP BY tanggal
       ORDER BY tanggal DESC LIMIT 7`,
      userParams
    );

    // 5. Lokasi Breakdown (Top 5)
    const [lokasiChart] = await pool.query(
      `SELECT lokasi as nama_wilayah, COUNT(*) as total
       FROM leads_tour
       WHERE 1=1 ${userFilter}
       GROUP BY lokasi
       ORDER BY total DESC LIMIT 5`,
      userParams
    );

    // 6. Sumber Breakdown (Top 5)
    const [sumberChart] = await pool.query(
      `SELECT s.nama_sumber, COUNT(*) as total
       FROM leads_tour lt
       JOIN sumber_leads s ON lt.sumber_id = s.id
       WHERE 1=1 ${userFilter}
       GROUP BY lt.sumber_id
       ORDER BY total DESC LIMIT 5`,
      userParams
    );

    // 7. Leaderboard (Admin / Owner Only)
    let leaderboard = [];
    if (req.user.role === 'admin' || req.user.role === 'owner') {
      const [rows] = await pool.query(
        `SELECT u.nama_lengkap as name, COUNT(lt.id) as total
         FROM users u
         LEFT JOIN leads_tour lt ON u.id = lt.user_id
         WHERE u.role = 'karyawan' AND u.bagian = 'tour'
         GROUP BY u.id
         ORDER BY total DESC`
      );
      leaderboard = rows;
    }

    res.json({
      todayTotal,
      monthTotal,
      yearTotal,
      bestWilayah: bestLokasi,
      bestSumber,
      dailyTrend: dailyTrend.reverse(),
      wilayahChart: lokasiChart,
      sumberChart,
      leaderboard
    });
  } catch (error) {
    res.status(500).json({ error: 'Gagal mengambil statistik dashboard tour.' });
  }
});

// Dashboard Marketing Stats
router.get('/dashboard', authenticateToken, async (req, res) => {
  const isKaryawan = req.user.role === 'karyawan';
  const userId = req.user.id;

  const userFilter = isKaryawan ? ' AND user_id = ? ' : ' AND 1=1 ';
  const userParams = isKaryawan ? [userId] : [];

  try {
    const today = new Date().toISOString().split('T')[0];
    const curMonth = today.substring(0, 7) + '%';
    const curYear = today.substring(0, 4) + '%';

    const [[{ todayTotal }]] = await pool.query(
      `SELECT COALESCE(SUM(jumlah), 0) as todayTotal FROM leads WHERE tanggal = ? ${userFilter}`,
      [today, ...userParams]
    );

    const [[{ monthTotal }]] = await pool.query(
      `SELECT COALESCE(SUM(jumlah), 0) as monthTotal FROM leads WHERE tanggal LIKE ? ${userFilter}`,
      [curMonth, ...userParams]
    );

    const [[{ yearTotal }]] = await pool.query(
      `SELECT COALESCE(SUM(jumlah), 0) as yearTotal FROM leads WHERE tanggal LIKE ? ${userFilter}`,
      [curYear, ...userParams]
    );

    // 2. Best Wilayah
    const [wilayahBest] = await pool.query(
      `SELECT w.nama_wilayah as name, COALESCE(SUM(l.jumlah), 0) as total
       FROM leads l
       JOIN wilayah w ON l.wilayah_id = w.id
       WHERE 1=1 ${userFilter}
       GROUP BY l.wilayah_id
       ORDER BY total DESC LIMIT 1`,
      userParams
    );
    const bestWilayah = wilayahBest.length > 0 ? wilayahBest[0].name : '-';

    // 3. Best Sumber
    const [sumberBest] = await pool.query(
      `SELECT s.nama_sumber as name, COALESCE(SUM(l.jumlah), 0) as total
       FROM leads l
       JOIN sumber_leads s ON l.sumber_id = s.id
       WHERE 1=1 ${userFilter}
       GROUP BY l.sumber_id
       ORDER BY total DESC LIMIT 1`,
      userParams
    );
    const bestSumber = sumberBest.length > 0 ? sumberBest[0].name : '-';

    // 4. Daily Trend (7 Last days with input)
    const [dailyTrend] = await pool.query(
      `SELECT tanggal as date, DATE_FORMAT(tanggal, '%d/%m') as label, COALESCE(SUM(jumlah), 0) as total
       FROM leads
       WHERE 1=1 ${userFilter}
       GROUP BY tanggal
       ORDER BY tanggal DESC LIMIT 7`,
      userParams
    );

    // 5. Wilayah Breakdown (Top 5)
    const [wilayahChart] = await pool.query(
      `SELECT w.nama_wilayah, COALESCE(SUM(l.jumlah), 0) as total
       FROM leads l
       JOIN wilayah w ON l.wilayah_id = w.id
       WHERE 1=1 ${userFilter}
       GROUP BY l.wilayah_id
       ORDER BY total DESC LIMIT 5`,
      userParams
    );

    // 6. Sumber Breakdown (Top 5)
    const [sumberChart] = await pool.query(
      `SELECT s.nama_sumber, COALESCE(SUM(l.jumlah), 0) as total
       FROM leads l
       JOIN sumber_leads s ON l.sumber_id = s.id
       WHERE 1=1 ${userFilter}
       GROUP BY l.sumber_id
       ORDER BY total DESC LIMIT 5`,
      userParams
    );

    // 7. Leaderboard (Admin / Owner Only)
    let leaderboard = [];
    if (req.user.role === 'admin' || req.user.role === 'owner') {
      const [rows] = await pool.query(
        `SELECT u.nama_lengkap as name, COALESCE(SUM(l.jumlah), 0) as total
         FROM users u
         LEFT JOIN leads l ON u.id = l.user_id
         WHERE u.role = 'karyawan' AND u.bagian = 'marketing'
         GROUP BY u.id
         ORDER BY total DESC`
      );
      leaderboard = rows;
    }

    res.json({
      todayTotal,
      monthTotal,
      yearTotal,
      bestWilayah,
      bestSumber,
      dailyTrend: dailyTrend.reverse(),
      wilayahChart,
      sumberChart,
      leaderboard
    });
  } catch (error) {
    res.status(500).json({ error: 'Gagal mengambil statistik dashboard.' });
  }
});

module.exports = router;
