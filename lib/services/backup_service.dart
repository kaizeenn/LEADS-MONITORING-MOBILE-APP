import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../database/database_helper.dart';

class BackupService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<String?> generateBackup() async {
    try {
      final db = await _dbHelper.database;

      // Query database tables
      final List<Map<String, dynamic>> wilayahList = await db.query('wilayah');
      final List<Map<String, dynamic>> sumberLeadsList = await db.query('sumber_leads');
      final List<Map<String, dynamic>> leadsList = await db.query('leads');

      final now = DateTime.now();
      final backupDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
      
      final Map<String, dynamic> backupData = {
        "version": "1.0",
        "backup_date": backupDate,
        "wilayah": wilayahList,
        "sumber_leads": sumberLeadsList,
        "leads": leadsList
      };

      final jsonString = jsonEncode(backupData);
      
      // Save JSON string to file
      final directory = await getApplicationDocumentsDirectory();
      final fileDate = DateFormat('yyyyMMdd_HHmmss').format(now);
      final fileName = 'backup_leads_$fileDate.json';
      final file = File('${directory.path}/$fileName');
      
      await file.writeAsString(jsonString);
      return file.path;
    } catch (e) {
      print('Error during backup generation: $e');
      return null;
    }
  }

  Future<void> shareBackupFile(String filePath) async {
    final file = XFile(filePath);
    await Share.shareXFiles([file], text: 'Backup Data Aplikasi Leads Monitoring');
  }
}
