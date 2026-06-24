import 'dart:convert';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';

class RestoreService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Read, parse and validate the JSON backup file
  Future<Map<String, dynamic>?> parseAndValidateBackup(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception("File tidak ditemukan.");
      }

      final content = await file.readAsString();
      final decoded = jsonDecode(content);

      if (decoded is! Map<String, dynamic>) {
        throw Exception("Format JSON tidak valid.");
      }

      if (!decoded.containsKey('wilayah') ||
          !decoded.containsKey('sumber_leads') ||
          !decoded.containsKey('leads')) {
        throw Exception("Format backup tidak valid: Field 'wilayah', 'sumber_leads', atau 'leads' tidak ditemukan.");
      }

      if (decoded['wilayah'] is! List ||
          decoded['sumber_leads'] is! List ||
          decoded['leads'] is! List) {
        throw Exception("Format data dalam file backup tidak valid.");
      }

      return decoded;
    } catch (e) {
      print('Validation failed: $e');
      rethrow;
    }
  }

  // Restore the data into SQLite inside a database transaction
  Future<void> restoreBackup(Map<String, dynamic> backupData) async {
    final db = await _dbHelper.database;

    await db.transaction((txn) async {
      // Delete existing data in reverse order of foreign keys
      await txn.delete('leads');
      await txn.delete('wilayah');
      await txn.delete('sumber_leads');

      final List<dynamic> wilayahList = backupData['wilayah'];
      final List<dynamic> sumberList = backupData['sumber_leads'];
      final List<dynamic> leadsList = backupData['leads'];

      // Re-insert wilayah
      for (final w in wilayahList) {
        if (w is Map<String, dynamic>) {
          await txn.insert('wilayah', w, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }

      // Re-insert sumber leads
      for (final s in sumberList) {
        if (s is Map<String, dynamic>) {
          await txn.insert('sumber_leads', s, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }

      // Re-insert leads
      for (final l in leadsList) {
        if (l is Map<String, dynamic>) {
          await txn.insert('leads', l, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
    });
  }
}
