import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/leads_model.dart';
import '../services/report_service.dart';
import '../services/excel_service.dart';
import '../services/pdf_service.dart';

class LaporanProvider extends ChangeNotifier {
  final ReportService _reportService = ReportService();

  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  int? _wilayahId;
  int? _sumberId;

  List<LeadsModel> _filteredLeads = [];
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
  List<LeadsModel> get filteredLeads => _filteredLeads;
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

  void setSumberId(int? id) {
    _sumberId = id;
    notifyListeners();
  }

  Future<void> loadReport() async {
    _isLoading = true;
    notifyListeners();

    try {
      final df = DateFormat('yyyy-MM-dd');
      final startStr = df.format(_startDate);
      final endStr = df.format(_endDate);

      final result = await _reportService.getFilteredLeads(
        startDate: startStr,
        endDate: endStr,
        wilayahId: _wilayahId,
        sumberId: _sumberId,
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
      total += lead.jumlah;
      activeDates.add(lead.tanggal);
      
      final wName = lead.namaWilayah ?? '-';
      wilayahSums[wName] = (wilayahSums[wName] ?? 0) + lead.jumlah;

      final sName = lead.namaSumber ?? '-';
      sumberSums[sName] = (sumberSums[sName] ?? 0) + lead.jumlah;
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
        int cmp = a.tanggal.compareTo(b.tanggal);
        return _isAscending ? cmp : -cmp;
      });
    } else if (_sortColumn == 'Wilayah') {
      _filteredLeads.sort((a, b) {
        String wA = a.namaWilayah ?? '';
        String wB = b.namaWilayah ?? '';
        int cmp = wA.compareTo(wB);
        return _isAscending ? cmp : -cmp;
      });
    } else if (_sortColumn == 'Jumlah') {
      _filteredLeads.sort((a, b) {
        int cmp = a.jumlah.compareTo(b.jumlah);
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
    return await excelService.exportToExcel(_filteredLeads, stats);
  }

  Future<String?> exportPdf() async {
    final PdfService pdfService = PdfService();
    final stats = {
      'totalLeads': _totalLeads,
      'averageLeads': _averageLeads,
      'totalActiveDays': _totalActiveDays,
      'bestWilayah': _bestWilayah,
      'bestSumber': _bestSumber,
    };
    final df = DateFormat('dd/MM/yyyy');
    final periodText = '${df.format(_startDate)} s/d ${df.format(_endDate)}';
    return await pdfService.exportToPdf(_filteredLeads, stats, periodText);
  }
}
