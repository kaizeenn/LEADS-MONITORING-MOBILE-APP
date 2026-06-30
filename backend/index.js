require('dotenv').config();
const express = require('express');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const mysql = require('mysql2/promise');

const app = express();
const PORT = process.env.PORT || 3000;
const JWT_SECRET = process.env.JWT_SECRET || 'leads_monitoring_secret_key_12345';

// Middlewares
app.use(cors());
app.use(express.json());

// MySQL Connection Pool
const pool = mysql.createPool({
  host: process.env.DB_HOST || '127.0.0.1',
  port: process.env.DB_PORT || 3306,
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'leads_monitoring',
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0
});

// Database Auto-Seeding
async function seedDatabase() {
  try {
    const connection = await pool.getConnection();
    try {
      // 1. Check and Seed Users
      const [users] = await connection.query('SELECT * FROM users LIMIT 1');
      if (users.length === 0) {
        const adminPass = bcrypt.hashSync('admin123', 10);
        const empAPass = bcrypt.hashSync('karyawan123', 10);
        const empBPass = bcrypt.hashSync('karyawan123', 10);

        await connection.query(
          `INSERT INTO users (nama_lengkap, username, password, role) VALUES 
          ('Administrator', 'admin', ?, 'admin'),
          ('Khairil Anwar PENS', 'anwar', ?, 'karyawan'),
          ('Budi Santoso', 'budi', ?, 'karyawan')`,
          [adminPass, empAPass, empBPass]
        );
        console.log('Database Seeding: Created initial users.');
      }

      // 2. Check and Seed Wilayah
      const [wilayah] = await connection.query('SELECT * FROM wilayah LIMIT 1');
      if (wilayah.length === 0) {
        await connection.query(
          `INSERT INTO wilayah (nama_wilayah) VALUES 
          ('Gresik'), ('Surabaya'), ('Sidoarjo'), ('Malang'), ('Mojokerto')`
        );
        console.log('Database Seeding: Created initial wilayah.');
      }

      // 3. Check and Seed Sumber Leads
      const [sumber] = await connection.query('SELECT * FROM sumber_leads LIMIT 1');
      if (sumber.length === 0) {
        await connection.query(
          `INSERT INTO sumber_leads (nama_sumber) VALUES 
          ('TikTok'), ('Instagram'), ('Facebook'), ('Google Maps'), ('WhatsApp'), ('Brosur')`
        );
        console.log('Database Seeding: Created initial sumber leads.');
      }
    } finally {
      connection.release();
    }
  } catch (error) {
    console.error('Error during database seeding:', error.message);
  }
}

// Authentication Middleware
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ error: 'Akses ditolak. Token tidak ditemukan.' });
  }

  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    req.user = decoded;
    next();
  } catch (error) {
    return res.status(403).json({ error: 'Token tidak valid atau kedaluwarsa.' });
  }
};

// Check Admin Role Middleware
const requireAdmin = (req, res, next) => {
  if (req.user.role !== 'admin') {
    return res.status(403).json({ error: 'Akses khusus administrator.' });
  }
  next();
};

// --- AUTH ROUTESS ---

// Register User
app.post('/api/auth/register', async (req, res) => {
  const { nama_lengkap, username, password, role } = req.body;
  if (!nama_lengkap || !username || !password) {
    return res.status(400).json({ error: 'Nama lengkap, username, dan password wajib diisi.' });
  }

  try {
    const hashedPassword = await bcrypt.hash(password, 10);
    const userRole = role === 'admin' ? 'admin' : 'karyawan';

    await pool.query(
      'INSERT INTO users (nama_lengkap, username, password, role) VALUES (?, ?, ?, ?)',
      [nama_lengkap, username, hashedPassword, userRole]
    );

    res.status(201).json({ message: 'Registrasi berhasil!' });
  } catch (error) {
    if (error.code === 'ER_DUP_ENTRY') {
      return res.status(400).json({ error: 'Username sudah terdaftar.' });
    }
    res.status(500).json({ error: 'Gagal melakukan registrasi.' });
  }
});

// Login User
app.post('/api/auth/login', async (req, res) => {
  const { username, password } = req.body;
  if (!username || !password) {
    return res.status(400).json({ error: 'Username dan password wajib diisi.' });
  }

  try {
    const [rows] = await pool.query('SELECT * FROM users WHERE username = ?', [username.trim()]);
    if (rows.length === 0) {
      return res.status(400).json({ error: 'Username tidak ditemukan.' });
    }

    const user = rows[0];
    const validPassword = await bcrypt.compare(password, user.password);
    if (!validPassword) {
      return res.status(400).json({ error: 'Password salah.' });
    }

    const token = jwt.sign(
      { id: user.id, nama_lengkap: user.nama_lengkap, username: user.username, role: user.role },
      JWT_SECRET,
      { expiresIn: '7d' }
    );

    res.json({
      token,
      user: {
        id: user.id,
        nama_lengkap: user.nama_lengkap,
        username: user.username,
        role: user.role
      }
    });
  } catch (error) {
    res.status(500).json({ error: 'Terjadi kesalahan pada server.' });
  }
});

// Get Current User Profile
app.get('/api/auth/me', authenticateToken, async (req, res) => {
  res.json({ user: req.user });
});

// --- USER MANAGEMENT ROUTES (ADMIN ONLY) ---

// Get all users
app.get('/api/users', authenticateToken, requireAdmin, async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT id, nama_lengkap, username, role, created_at FROM users ORDER BY nama_lengkap ASC');
    res.json(rows);
  } catch (error) {
    res.status(500).json({ error: 'Gagal mengambil data user.' });
  }
});

// Create new user (Admin adding employee)
app.post('/api/users', authenticateToken, requireAdmin, async (req, res) => {
  const { nama_lengkap, username, password, role } = req.body;
  if (!nama_lengkap || !username || !password || !role) {
    return res.status(400).json({ error: 'Nama lengkap, username, password, dan role wajib diisi.' });
  }

  try {
    const hashedPassword = await bcrypt.hash(password, 10);
    const userRole = role === 'admin' ? 'admin' : 'karyawan';

    const [result] = await pool.query(
      'INSERT INTO users (nama_lengkap, username, password, role) VALUES (?, ?, ?, ?)',
      [nama_lengkap, username, hashedPassword, userRole]
    );

    res.status(201).json({
      id: result.insertId,
      nama_lengkap,
      username,
      role: userRole
    });
  } catch (error) {
    if (error.code === 'ER_DUP_ENTRY') {
      return res.status(400).json({ error: 'Username sudah terdaftar.' });
    }
    res.status(500).json({ error: 'Gagal menambahkan user baru.' });
  }
});

// Delete user
app.delete('/api/users/:id', authenticateToken, requireAdmin, async (req, res) => {
  const { id } = req.params;
  if (parseInt(id) === req.user.id) {
    return res.status(400).json({ error: 'Anda tidak dapat menghapus akun Anda sendiri.' });
  }

  try {
    await pool.query('DELETE FROM users WHERE id = ?', [id]);
    res.json({ message: 'User berhasil dihapus.' });
  } catch (error) {
    res.status(500).json({ error: 'Gagal menghapus user.' });
  }
});

// --- WILAYAH ROUTES ---

app.get('/api/wilayah', authenticateToken, async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT * FROM wilayah ORDER BY nama_wilayah ASC');
    res.json(rows);
  } catch (error) {
    res.status(500).json({ error: 'Gagal mengambil data wilayah.' });
  }
});

app.post('/api/wilayah', authenticateToken, async (req, res) => {
  const { nama_wilayah } = req.body;
  if (!nama_wilayah || nama_wilayah.trim() === '') {
    return res.status(400).json({ error: 'Nama wilayah wajib diisi.' });
  }

  try {
    const [result] = await pool.query('INSERT INTO wilayah (nama_wilayah) VALUES (?)', [nama_wilayah.trim()]);
    res.status(201).json({ id: result.insertId, nama_wilayah });
  } catch (error) {
    if (error.code === 'ER_DUP_ENTRY') {
      return res.status(400).json({ error: 'Wilayah sudah terdaftar.' });
    }
    res.status(500).json({ error: 'Gagal menambahkan wilayah.' });
  }
});

app.delete('/api/wilayah/:id', authenticateToken, async (req, res) => {
  const { id } = req.params;
  try {
    // Check if linked to any leads
    const [linked] = await pool.query('SELECT id FROM leads WHERE wilayah_id = ? LIMIT 1', [id]);
    if (linked.length > 0) {
      return res.status(400).json({ error: 'Wilayah tidak bisa dihapus karena sedang digunakan oleh data leads.' });
    }

    await pool.query('DELETE FROM wilayah WHERE id = ?', [id]);
    res.json({ message: 'Wilayah berhasil dihapus.' });
  } catch (error) {
    res.status(500).json({ error: 'Gagal menghapus wilayah.' });
  }
});

// --- SUMBER LEADS ROUTES ---

app.get('/api/sumber', authenticateToken, async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT * FROM sumber_leads ORDER BY nama_sumber ASC');
    res.json(rows);
  } catch (error) {
    res.status(500).json({ error: 'Gagal mengambil data sumber.' });
  }
});

app.post('/api/sumber', authenticateToken, requireAdmin, async (req, res) => {
  const { nama_sumber } = req.body;
  if (!nama_sumber || nama_sumber.trim() === '') {
    return res.status(400).json({ error: 'Nama sumber wajib diisi.' });
  }

  try {
    const [result] = await pool.query('INSERT INTO sumber_leads (nama_sumber) VALUES (?)', [nama_sumber.trim()]);
    res.status(201).json({ id: result.insertId, nama_sumber });
  } catch (error) {
    if (error.code === 'ER_DUP_ENTRY') {
      return res.status(400).json({ error: 'Sumber sudah terdaftar.' });
    }
    res.status(500).json({ error: 'Gagal menambahkan sumber leads.' });
  }
});

app.delete('/api/sumber/:id', authenticateToken, requireAdmin, async (req, res) => {
  const { id } = req.params;
  try {
    const [linked] = await pool.query('SELECT id FROM leads WHERE sumber_id = ? LIMIT 1', [id]);
    if (linked.length > 0) {
      return res.status(400).json({ error: 'Sumber tidak bisa dihapus karena sedang digunakan oleh data leads.' });
    }

    await pool.query('DELETE FROM sumber_leads WHERE id = ?', [id]);
    res.json({ message: 'Sumber berhasil dihapus.' });
  } catch (error) {
    res.status(500).json({ error: 'Gagal menghapus sumber leads.' });
  }
});

// --- LEADS ROUTES ---

// Get all leads (with filters)
app.get('/api/leads', authenticateToken, async (req, res) => {
  const { user_id, wilayah_id, sumber_id, startDate, endDate } = req.query;
  
  let query = `
    SELECT l.*, w.nama_wilayah, s.nama_sumber, u.nama_lengkap as nama_inputter
    FROM leads l
    JOIN wilayah w ON l.wilayah_id = w.id
    JOIN sumber_leads s ON l.sumber_id = s.id
    JOIN users u ON l.user_id = u.id
    WHERE 1=1
  `;
  const queryParams = [];

  // If role is karyawan, they can ONLY see their own leads
  if (req.user.role === 'karyawan') {
    query += ' AND l.user_id = ? ';
    queryParams.push(req.user.id);
  } else if (user_id) {
    // If admin is filtering by user
    query += ' AND l.user_id = ? ';
    queryParams.push(user_id);
  }

  if (wilayah_id) {
    query += ' AND l.wilayah_id = ? ';
    queryParams.push(wilayah_id);
  }

  if (sumber_id) {
    query += ' AND l.sumber_id = ? ';
    queryParams.push(sumber_id);
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

  try {
    const [rows] = await pool.query(query, queryParams);
    res.json(rows);
  } catch (error) {
    res.status(500).json({ error: 'Gagal mengambil data leads.' });
  }
});

// Create lead
app.post('/api/leads', authenticateToken, async (req, res) => {
  const { wilayah_id, sumber_id, tanggal, jumlah } = req.body;
  
  if (!wilayah_id || !sumber_id || !tanggal || jumlah === undefined) {
    return res.status(400).json({ error: 'Semua kolom data leads wajib diisi.' });
  }

  // Set creator id from token
  const creatorId = req.user.id;

  try {
    const [result] = await pool.query(
      'INSERT INTO leads (wilayah_id, sumber_id, user_id, tanggal, jumlah) VALUES (?, ?, ?, ?, ?)',
      [wilayah_id, sumber_id, creatorId, tanggal, jumlah]
    );

    res.status(201).json({
      id: result.insertId,
      wilayah_id,
      sumber_id,
      user_id: creatorId,
      tanggal,
      jumlah
    });
  } catch (error) {
    res.status(500).json({ error: 'Gagal menambahkan data leads.' });
  }
});

// Update lead
app.put('/api/leads/:id', authenticateToken, async (req, res) => {
  const { id } = req.params;
  const { wilayah_id, sumber_id, tanggal, jumlah } = req.body;

  if (!wilayah_id || !sumber_id || !tanggal || jumlah === undefined) {
    return res.status(400).json({ error: 'Semua kolom data leads wajib diisi.' });
  }

  try {
    // Check ownership
    const [rows] = await pool.query('SELECT user_id FROM leads WHERE id = ?', [id]);
    if (rows.length === 0) {
      return res.status(404).json({ error: 'Data lead tidak ditemukan.' });
    }

    if (req.user.role !== 'admin' && rows[0].user_id !== req.user.id) {
      return res.status(403).json({ error: 'Anda tidak memiliki hak untuk mengedit data lead orang lain.' });
    }

    await pool.query(
      'UPDATE leads SET wilayah_id = ?, sumber_id = ?, tanggal = ?, jumlah = ? WHERE id = ?',
      [wilayah_id, sumber_id, tanggal, jumlah, id]
    );

    res.json({ message: 'Data lead berhasil diperbarui.' });
  } catch (error) {
    res.status(500).json({ error: 'Gagal memperbarui data lead.' });
  }
});

// Delete lead
app.delete('/api/leads/:id', authenticateToken, async (req, res) => {
  const { id } = req.params;

  try {
    // Check ownership
    const [rows] = await pool.query('SELECT user_id FROM leads WHERE id = ?', [id]);
    if (rows.length === 0) {
      return res.status(404).json({ error: 'Data lead tidak ditemukan.' });
    }

    if (req.user.role !== 'admin' && rows[0].user_id !== req.user.id) {
      return res.status(403).json({ error: 'Anda tidak memiliki hak untuk menghapus data lead orang lain.' });
    }

    await pool.query('DELETE FROM leads WHERE id = ?', [id]);
    res.json({ message: 'Data lead berhasil dihapus.' });
  } catch (error) {
    res.status(500).json({ error: 'Gagal menghapus data lead.' });
  }
});

// --- DASHBOARD / STATS ROUTES ---

app.get('/api/dashboard', authenticateToken, async (req, res) => {
  const isKaryawan = req.user.role === 'karyawan';
  const userId = req.user.id;

  // Build filter for user
  const userFilter = isKaryawan ? ' AND user_id = ? ' : ' AND 1=1 ';
  const userParams = isKaryawan ? [userId] : [];

  try {
    // 1. Totals (Today, Month, Year)
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

    // 7. Leaderboard (Admin Only)
    let leaderboard = [];
    if (req.user.role === 'admin') {
      const [rows] = await pool.query(
        `SELECT u.nama_lengkap as name, COALESCE(SUM(l.jumlah), 0) as total
         FROM users u
         LEFT JOIN leads l ON u.id = l.user_id
         WHERE u.role = 'karyawan'
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

// Run seeding and start server
seedDatabase().then(() => {
  app.listen(PORT, () => {
    console.log(`Server Express berjalan lancar di http://localhost:${PORT}`);
  });
});
