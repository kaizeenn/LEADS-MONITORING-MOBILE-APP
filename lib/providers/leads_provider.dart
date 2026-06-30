import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart';
import 'package:http/http.dart' as http;
import '../models/leads_model.dart';
import '../models/leads_tour_model.dart';
import '../models/wilayah_model.dart';
import '../models/sumber_leads_model.dart';

class LeadsProvider extends ChangeNotifier {
  static const String apiBaseUrl = 'http://localhost:3000/api';

  List<WilayahModel> _wilayahList = [];
  List<SumberLeadsModel> _sumberLeadsList = [];
  List<LeadsModel> _leadsList = [];
  List<LeadsTourModel> _leadsTourList = [];
  bool _isLoading = false;

  List<WilayahModel> get wilayahList => _wilayahList;
  List<SumberLeadsModel> get sumberLeadsList => _sumberLeadsList;
  List<LeadsModel> get leadsList => _leadsList;
  List<LeadsTourModel> get leadsTourList => _leadsTourList;
  bool get isLoading => _isLoading;

  Future<void> loadInitialData(String token) async {
    _isLoading = true;
    notifyListeners();

    try {
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      // Load Wilayah from API
      final resWilayah = await http.get(Uri.parse('$apiBaseUrl/wilayah'), headers: headers);
      if (resWilayah.statusCode == 200) {
        final List<dynamic> data = json.decode(resWilayah.body);
        _wilayahList = data.map((e) => WilayahModel.fromMap(e)).toList();
      }

      // Load Sumber Leads from API
      final resSumber = await http.get(Uri.parse('$apiBaseUrl/sumber'), headers: headers);
      if (resSumber.statusCode == 200) {
        final List<dynamic> data = json.decode(resSumber.body);
        _sumberLeadsList = data.map((e) => SumberLeadsModel.fromMap(e)).toList();
      }

      // Automatic import regions from the specified Excel file if present
      await importWilayahFromExcel(token);

      // Load Leads from API
      await loadLeads(token);
      await loadLeadsTour(token);
    } catch (e) {
      print('Error loading initial data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> importWilayahFromExcel(String token) async {
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

      final Set<String> existingNames = _wilayahList
          .map((e) => e.namaWilayah.trim().toLowerCase())
          .toSet();

      bool didInsert = false;
      for (final wName in uniqueWilayahs) {
        if (!existingNames.contains(wName.toLowerCase())) {
          await addWilayah(token, wName);
          didInsert = true;
        }
      }

      if (didInsert) {
        // Reload Wilayah
        final headers = {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        };
        final resWilayah = await http.get(Uri.parse('$apiBaseUrl/wilayah'), headers: headers);
        if (resWilayah.statusCode == 200) {
          final List<dynamic> data = json.decode(resWilayah.body);
          _wilayahList = data.map((e) => WilayahModel.fromMap(e)).toList();
        }
      }
    } catch (e) {
      print('Error importing Wilayah from Excel: $e');
    }
  }

  Future<bool> addWilayah(String token, String nama) async {
    try {
      final res = await http.post(
        Uri.parse('$apiBaseUrl/wilayah'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'nama_wilayah': nama.trim()}),
      );

      if (res.statusCode == 201) {
        final data = json.decode(res.body);
        _wilayahList.add(WilayahModel.fromMap(data));
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Error adding wilayah: $e');
      return false;
    }
  }

  Future<bool> deleteWilayah(String token, int id) async {
    try {
      final res = await http.delete(
        Uri.parse('$apiBaseUrl/wilayah/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (res.statusCode == 200) {
        _wilayahList.removeWhere((w) => w.id == id);
        notifyListeners();
        return true;
      } else {
        final data = json.decode(res.body);
        throw Exception(data['error'] ?? 'Gagal menghapus wilayah.');
      }
    } catch (e) {
      print('Error deleting wilayah: $e');
      rethrow;
    }
  }

  Future<void> loadLeads(String token) async {
    try {
      final res = await http.get(
        Uri.parse('$apiBaseUrl/leads'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (res.statusCode == 200) {
        final List<dynamic> data = json.decode(res.body);
        _leadsList = data.map((e) => LeadsModel.fromMap(e)).toList();
        notifyListeners();
      }
    } catch (e) {
      print('Error loading leads: $e');
    }
  }

  Future<bool> addLead(String token, {
    required int wilayahId,
    required int sumberId,
    required String tanggal,
    required int jumlah,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$apiBaseUrl/leads'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'wilayah_id': wilayahId,
          'sumber_id': sumberId,
          'tanggal': tanggal,
          'jumlah': jumlah,
        }),
      );

      if (res.statusCode == 201) {
        await loadLeads(token);
        return true;
      }
      return false;
    } catch (e) {
      print('Error adding lead: $e');
      return false;
    }
  }

  Future<bool> updateLead(String token, LeadsModel lead) async {
    try {
      final res = await http.put(
        Uri.parse('$apiBaseUrl/leads/${lead.id}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'wilayah_id': lead.wilayahId,
          'sumber_id': lead.sumberId,
          'tanggal': lead.tanggal,
          'jumlah': lead.jumlah,
        }),
      );

      if (res.statusCode == 200) {
        await loadLeads(token);
        return true;
      }
      return false;
    } catch (e) {
      print('Error updating lead: $e');
      return false;
    }
  }

  Future<bool> deleteLead(String token, int id) async {
    try {
      final res = await http.delete(
        Uri.parse('$apiBaseUrl/leads/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (res.statusCode == 200) {
        await loadLeads(token);
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting lead: $e');
      return false;
    }
  }

  Future<void> loadLeadsTour(String token) async {
    try {
      final res = await http.get(
        Uri.parse('$apiBaseUrl/leads-tour'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (res.statusCode == 200) {
        final List<dynamic> data = json.decode(res.body);
        _leadsTourList = data.map((e) => LeadsTourModel.fromMap(e)).toList();
        notifyListeners();
      }
    } catch (e) {
      print('Error loading tour leads: $e');
    }
  }

  Future<bool> addLeadTour(String token, {
    required String lokasi,
    required int sumberId,
    required String tanggal,
    required String namaClient,
    required String asalClient,
    required String noHpClient,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$apiBaseUrl/leads-tour'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'lokasi': lokasi.trim(),
          'sumber_id': sumberId,
          'tanggal': tanggal,
          'nama_client': namaClient.trim(),
          'asal_client': asalClient.trim(),
          'no_hp_client': noHpClient.trim(),
        }),
      );

      if (res.statusCode == 201) {
        await loadLeadsTour(token);
        return true;
      }
      return false;
    } catch (e) {
      print('Error adding tour lead: $e');
      return false;
    }
  }

  Future<bool> updateLeadTour(String token, LeadsTourModel lead) async {
    try {
      final res = await http.put(
        Uri.parse('$apiBaseUrl/leads-tour/${lead.id}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'lokasi': lead.lokasi.trim(),
          'sumber_id': lead.sumberId,
          'tanggal': lead.tanggal,
          'nama_client': lead.namaClient.trim(),
          'asal_client': lead.asalClient.trim(),
          'no_hp_client': lead.noHpClient.trim(),
        }),
      );

      if (res.statusCode == 200) {
        await loadLeadsTour(token);
        return true;
      }
      return false;
    } catch (e) {
      print('Error updating tour lead: $e');
      return false;
    }
  }

  Future<bool> deleteLeadTour(String token, int id) async {
    try {
      final res = await http.delete(
        Uri.parse('$apiBaseUrl/leads-tour/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (res.statusCode == 200) {
        await loadLeadsTour(token);
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting tour lead: $e');
      return false;
    }
  }
}
