import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'seed_data.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('leads_monitoring_v3.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    final db = await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      onConfigure: _configureDB,
    );
    await _checkAndSeedIfEmpty(db);
    return db;
  }

  Future<void> _checkAndSeedIfEmpty(Database db) async {
    try {
      final List<Map<String, dynamic>> wilayahCount = await db.query('wilayah', limit: 1);
      if (wilayahCount.isEmpty) {
        for (final nama in seedWilayah) {
          await db.insert('wilayah', {'nama_wilayah': nama});
        }
      }

      final List<Map<String, dynamic>> sumberCount = await db.query('sumber_leads', limit: 1);
      if (sumberCount.isEmpty) {
        for (final nama in seedSumberLeads) {
          await db.insert('sumber_leads', {'nama_sumber': nama});
        }
      }
    } catch (e) {
      print('Database seeding validation failed: $e');
    }
  }

  Future _configureDB(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE wilayah (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama_wilayah TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE sumber_leads (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama_sumber TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE leads (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        wilayah_id INTEGER NOT NULL,
        sumber_id INTEGER NOT NULL,
        tanggal TEXT NOT NULL,
        jumlah INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        FOREIGN KEY(wilayah_id) REFERENCES wilayah(id),
        FOREIGN KEY(sumber_id) REFERENCES sumber_leads(id)
      )
    ''');

    // Create Indexes
    await db.execute('CREATE INDEX idx_leads_tanggal ON leads(tanggal)');
    await db.execute('CREATE INDEX idx_leads_wilayah ON leads(wilayah_id)');
    await db.execute('CREATE INDEX idx_leads_sumber ON leads(sumber_id)');

    // Seed Data
    for (final nama in seedWilayah) {
      await db.insert('wilayah', {'nama_wilayah': nama});
    }

    for (final nama in seedSumberLeads) {
      await db.insert('sumber_leads', {'nama_sumber': nama});
    }
  }

  Future<void> close() async {
    final db = _database;
    if (db != null && db.isOpen) {
      await db.close();
    }
    _database = null;
  }
}
