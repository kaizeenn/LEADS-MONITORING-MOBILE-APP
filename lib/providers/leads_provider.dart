import 'dart:io';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart';
import '../database/database_helper.dart';
import '../models/leads_model.dart';
import '../models/wilayah_model.dart';
import '../models/sumber_leads_model.dart';

class LeadsProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  List<WilayahModel> _wilayahList = [];
  List<SumberLeadsModel> _sumberLeadsList = [];
  List<LeadsModel> _leadsList = [];
  bool _isLoading = false;

  List<WilayahModel> get wilayahList => _wilayahList;
  List<SumberLeadsModel> get sumberLeadsList => _sumberLeadsList;
  List<LeadsModel> get leadsList => _leadsList;
  bool get isLoading => _isLoading;

  Future<void> loadInitialData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final db = await _dbHelper.database;
      
      // Load Wilayah
      final List<Map<String, dynamic>> wilayahMaps = await db.query('wilayah');
      _wilayahList = wilayahMaps.map((e) => WilayahModel.fromMap(e)).toList();

      // Load Sumber Leads
      final List<Map<String, dynamic>> sumberMaps = await db.query('sumber_leads');
      _sumberLeadsList = sumberMaps.map((e) => SumberLeadsModel.fromMap(e)).toList();

      // Automatic import regions from the specified Excel file if present
      await importWilayahFromExcel();

      // Load Leads
      await loadLeads();
    } catch (e) {
      print('Error loading initial data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> importWilayahFromExcel() async {
    final file = File('/home/yume/Downloads/leads-report.xlsx');
    if (!await file.exists()) return;

    try {
      final bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);
      if (excel.tables.isEmpty) return;

      final sheetName = excel.tables.keys.firstWhere(
        (k) => k.toLowerCase() == 'leads',
        orElse: () => excel.tables.keys.first,
      );

      final table = excel.tables[sheetName];
      if (table == null) return;

      int wilayahColIndex = -1;
      if (table.rows.isNotEmpty) {
        final firstRow = table.rows.first;
        for (int i = 0; i < firstRow.length; i++) {
          final cellValue = firstRow[i]?.value?.toString().trim().toLowerCase();
          if (cellValue == 'wilayah') {
            wilayahColIndex = i;
            break;
          }
        }
      }

      if (wilayahColIndex == -1) return;

      final Set<String> uniqueWilayahs = {};
      for (int i = 1; i < table.rows.length; i++) {
        final row = table.rows[i];
        if (row.length > wilayahColIndex) {
          final cellVal = row[wilayahColIndex]?.value?.toString().trim();
          if (cellVal != null && cellVal.isNotEmpty && cellVal != '-') {
            uniqueWilayahs.add(cellVal);
          }
        }
      }

      if (uniqueWilayahs.isEmpty) return;

      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> existing = await db.query('wilayah');
      final Set<String> existingNames = existing
          .map((e) => e['nama_wilayah'].toString().trim().toLowerCase())
          .toSet();

      bool didInsert = false;
      for (final wName in uniqueWilayahs) {
        if (!existingNames.contains(wName.toLowerCase())) {
          await db.insert('wilayah', {'nama_wilayah': wName});
          didInsert = true;
        }
      }

      if (didInsert) {
        final List<Map<String, dynamic>> updatedWilayahMaps = await db.query('wilayah');
        _wilayahList = updatedWilayahMaps.map((e) => WilayahModel.fromMap(e)).toList();
      }
    } catch (e) {
      print('Error importing Wilayah from Excel: $e');
    }
  }

  Future<bool> addWilayah(String nama) async {
    try {
      final db = await _dbHelper.database;
      await db.insert('wilayah', {'nama_wilayah': nama.trim()});
      
      final List<Map<String, dynamic>> wilayahMaps = await db.query('wilayah');
      _wilayahList = wilayahMaps.map((e) => WilayahModel.fromMap(e)).toList();
      notifyListeners();
      return true;
    } catch (e) {
      print('Error adding wilayah: $e');
      return false;
    }
  }

  Future<bool> deleteWilayah(int id) async {
    try {
      final db = await _dbHelper.database;
      await db.delete('wilayah', where: 'id = ?', whereArgs: [id]);
      
      final List<Map<String, dynamic>> wilayahMaps = await db.query('wilayah');
      _wilayahList = wilayahMaps.map((e) => WilayahModel.fromMap(e)).toList();
      notifyListeners();
      return true;
    } catch (e) {
      print('Error deleting wilayah: $e');
      rethrow; // Rethrow to handle FK errors in UI
    }
  }

  Future<void> loadLeads() async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> leadsMaps = await db.rawQuery('''
        SELECT l.*, w.nama_wilayah, s.nama_sumber
        FROM leads l
        JOIN wilayah w ON l.wilayah_id = w.id
        JOIN sumber_leads s ON l.sumber_id = s.id
        ORDER BY l.tanggal DESC, l.id DESC
      ''');
      _leadsList = leadsMaps.map((e) => LeadsModel.fromMap(e)).toList();
      notifyListeners();
    } catch (e) {
      print('Error loading leads: $e');
    }
  }

  Future<bool> addLead({
    required int wilayahId,
    required int sumberId,
    required String tanggal,
    required int jumlah,
  }) async {
    try {
      final db = await _dbHelper.database;
      final lead = LeadsModel(
        wilayahId: wilayahId,
        sumberId: sumberId,
        tanggal: tanggal,
        jumlah: jumlah,
        createdAt: DateTime.now().toIso8601String(),
      );
      await db.insert('leads', lead.toMap());
      await loadLeads();
      return true;
    } catch (e) {
      print('Error adding lead: $e');
      return false;
    }
  }

  Future<bool> updateLead(LeadsModel lead) async {
    try {
      final db = await _dbHelper.database;
      final updatedLead = LeadsModel(
        id: lead.id,
        wilayahId: lead.wilayahId,
        sumberId: lead.sumberId,
        tanggal: lead.tanggal,
        jumlah: lead.jumlah,
        createdAt: lead.createdAt,
        updatedAt: DateTime.now().toIso8601String(),
      );
      await db.update(
        'leads',
        updatedLead.toMap(),
        where: 'id = ?',
        whereArgs: [lead.id],
      );
      await loadLeads();
      return true;
    } catch (e) {
      print('Error updating lead: $e');
      return false;
    }
  }

  Future<bool> deleteLead(int id) async {
    try {
      final db = await _dbHelper.database;
      await db.delete(
        'leads',
        where: 'id = ?',
        whereArgs: [id],
      );
      await loadLeads();
      return true;
    } catch (e) {
      print('Error deleting lead: $e');
      return false;
    }
  }
}
