const mysql = require('mysql2/promise');
const bcrypt = require('bcryptjs');

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
        const ownerPass = bcrypt.hashSync('owner123', 10);

        await connection.query(
          `INSERT INTO users (nama_lengkap, username, password, role, bagian) VALUES 
          ('Administrator', 'admin', ?, 'admin', NULL),
          ('Khairil Anwar PENS', 'anwar', ?, 'karyawan', 'marketing'),
          ('Budi Santoso', 'budi', ?, 'karyawan', 'tour'),
          ('Owner Group', 'owner', ?, 'owner', NULL)`,
          [adminPass, empAPass, empBPass, ownerPass]
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

async function testConnection() {
  try {
    await pool.query('SELECT 1 + 1 AS result');
    console.log('✅ Database connected:', process.env.DB_NAME || 'leads_monitoring');
    await seedDatabase();
    return true;
  } catch (error) {
    console.error('❌ Database connection failed:', error.message);
    return false;
  }
}

module.exports = pool;
module.exports.testConnection = testConnection;
