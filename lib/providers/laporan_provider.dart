import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/leads_model.dart';
import '../models/leads_tour_model.dart';
import '../services/report_service.dart';
import '../services/excel_service.dart';

class LaporanProvider extends ChangeNotifier {
  final ReportService _reportService = ReportService();

  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  int? _wilayahId;
  int? _sumberId;
  String? _lokasi;
  String _currentDivision = 'marketing';

  List<dynamic> _filteredLeads = [];
  bool _isLoading = false;

  // Sorting
  String _sortColumn = 'Tanggal';
  bool _isAscending = false;

  // Statistics calculated from filtered list
  int _totalLeads = 0;
  double _averageLeads = 0.0;
  int _totalActiveDays = 0;
  String _bestWilayah = '-';
  String _bestSumber = '-';

  DateTime get startDate => _startDate;
  DateTime get endDate => _endDate;
  int? get wilayahId => _wilayahId;
  int? get sumberId => _sumberId;
  String? get lokasi => _lokasi;
  String get currentDivision => _currentDivision;
  List<dynamic> get filteredLeads => _filteredLeads;
  bool get isLoading => _isLoading;
  String get sortColumn => _sortColumn;
  bool get isAscending => _isAscending;

  int get totalLeads => _totalLeads;
  double get averageLeads => _averageLeads;
  int get totalActiveDays => _totalActiveDays;
  String get bestWilayah => _bestWilayah;
  String get bestSumber => _bestSumber;

  void setStartDate(DateTime date) {
    _startDate = date;
    notifyListeners();
  }

  void setEndDate(DateTime date) {
    _endDate = date;
    notifyListeners();
  }

  void setWilayahId(int? id) {
    _wilayahId = id;
    notifyListeners();
  }

  void setLokasi(String? loc) {
    _lokasi = loc;
    notifyListeners();
  }

  void setSumberId(int? id) {
    _sumberId = id;
    notifyListeners();
  }

  void setDivision(String div, String token) {
    _currentDivision = div;
    _wilayahId = null;
    _lokasi = null;
    _sumberId = null;
    loadReport(token);
  }

  Future<void> loadReport(String token) async {
    _isLoading = true;
    notifyListeners();

    try {
      final df = DateFormat('yyyy-MM-dd');
      final startStr = df.format(_startDate);
      final endStr = df.format(_endDate);

      final result = await _reportService.getFilteredLeads(
        token,
        division: _currentDivision,
        startDate: startStr,
        endDate: endStr,
        wilayahId: _wilayahId,
        sumberId: _sumberId,
        lokasi: _lokasi,
      );

      _filteredLeads = result;
      _calculateStats();
      _performSort();
    } catch (e) {
      print('Error loading report: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _calculateStats() {
    int total = 0;
    final Set<String> activeDates = {};
    final Map<String, int> wilayahSums = {};
    final Map<String, int> sumberSums = {};

    for (final lead in _filteredLeads) {
      final int amount;
      final String locName;
      final String sName;
      final String dateStr;

      if (_currentDivision == 'marketing') {
        final l = lead as LeadsModel;
        amount = l.jumlah;
        locName = l.namaWilayah ?? '-';
        sName = l.namaSumber ?? '-';
        dateStr = l.tanggal;
      } else {
        final l = lead as LeadsTourModel;
        amount = 1;
        locName = l.lokasi;
        sName = l.namaSumber ?? '-';
        dateStr = l.tanggal;
      }

      total += amount;
      activeDates.add(dateStr);
      wilayahSums[locName] = (wilayahSums[locName] ?? 0) + amount;
      sumberSums[sName] = (sumberSums[sName] ?? 0) + amount;
    }

    _totalLeads = total;
    _totalActiveDays = activeDates.length;
    _averageLeads = _totalActiveDays > 0 ? total / _totalActiveDays : 0.0;

    String bestW = '-';
    int maxWVal = -1;
    wilayahSums.forEach((key, value) {
      if (value > maxWVal) {
        maxWVal = value;
        bestW = key;
      }
    });
    _bestWilayah = bestW;

    String bestS = '-';
    int maxSVal = -1;
    sumberSums.forEach((key, value) {
      if (value > maxSVal) {
        maxSVal = value;
        bestS = key;
      }
    });
    _bestSumber = bestS;
  }

  void sortData(String column) {
    if (_sortColumn == column) {
      _isAscending = !_isAscending;
    } else {
      _sortColumn = column;
      _isAscending = true;
    }

    _performSort();
    notifyListeners();
  }

  void _performSort() {
    if (_sortColumn == 'Tanggal') {
      _filteredLeads.sort((a, b) {
        final String tA = a is LeadsModel ? a.tanggal : (a as LeadsTourModel).tanggal;
        final String tB = b is LeadsModel ? b.tanggal : (b as LeadsTourModel).tanggal;
        int cmp = tA.compareTo(tB);
        return _isAscending ? cmp : -cmp;
      });
    } else if (_sortColumn == 'Wilayah') {
      _filteredLeads.sort((a, b) {
        final String wA = a is LeadsModel ? (a.namaWilayah ?? '') : (a as LeadsTourModel).lokasi;
        final String wB = b is LeadsModel ? (b.namaWilayah ?? '') : (b as LeadsTourModel).lokasi;
        int cmp = wA.compareTo(wB);
        return _isAscending ? cmp : -cmp;
      });
    } else if (_sortColumn == 'Jumlah') {
      _filteredLeads.sort((a, b) {
        final int jA = a is LeadsModel ? a.jumlah : 1;
        final int jB = b is LeadsModel ? b.jumlah : 1;
        int cmp = jA.compareTo(jB);
        return _isAscending ? cmp : -cmp;
      });
    }
  }

  Future<String?> exportExcel() async {
    final ExcelService excelService = ExcelService();
    final stats = {
      'totalLeads': _totalLeads,
      'averageLeads': _averageLeads,
      'totalActiveDays': _totalActiveDays,
      'bestWilayah': _bestWilayah,
      'bestSumber': _bestSumber,
    };
    return await excelService.exportToExcel(_filteredLeads, stats, division: _currentDivision);
  }
}
