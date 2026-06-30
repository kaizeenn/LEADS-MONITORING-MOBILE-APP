import 'package:flutter/material.dart';
import '../services/report_service.dart';

class DashboardProvider extends ChangeNotifier {
  final ReportService _reportService = ReportService();

  int _todayTotal = 0;
  int _monthTotal = 0;
  int _yearTotal = 0;
  String _bestWilayah = '-';
  String _bestSumber = '-';
  List<Map<String, dynamic>> _dailyTrend = [];
  List<Map<String, dynamic>> _wilayahChart = [];
  List<Map<String, dynamic>> _sumberChart = [];
  bool _isLoading = false;
  String _currentDivision = 'marketing';

  int get todayTotal => _todayTotal;
  int get monthTotal => _monthTotal;
  int get yearTotal => _yearTotal;
  String get bestWilayah => _bestWilayah;
  String get bestSumber => _bestSumber;
  List<Map<String, dynamic>> get dailyTrend => _dailyTrend;
  List<Map<String, dynamic>> get wilayahChart => _wilayahChart;
  List<Map<String, dynamic>> get sumberChart => _sumberChart;
  bool get isLoading => _isLoading;
  String get currentDivision => _currentDivision;

  void initializeDivision(String div) {
    _currentDivision = div;
  }

  void setDivision(String div, String token) {
    _currentDivision = div;
    refreshDashboard(token);
  }

  Future<void> refreshDashboard(String token) async {
    _isLoading = true;
    notifyListeners();

    try {
      final stats = await _reportService.getDashboardStats(token, division: _currentDivision);
      _todayTotal = stats['today_total'] as int? ?? 0;
      _monthTotal = stats['month_total'] as int? ?? 0;
      _yearTotal = stats['year_total'] as int? ?? 0;
      _bestWilayah = stats['best_wilayah'] as String? ?? '-';
      _bestSumber = stats['best_sumber'] as String? ?? '-';
      _dailyTrend = List<Map<String, dynamic>>.from(stats['daily_trend']);
      _wilayahChart = List<Map<String, dynamic>>.from(stats['wilayah_chart']);
      _sumberChart = List<Map<String, dynamic>>.from(stats['sumber_chart']);
    } catch (e) {
      print('Error refreshing dashboard: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
