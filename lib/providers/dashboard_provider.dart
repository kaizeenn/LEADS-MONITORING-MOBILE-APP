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
      
      final trendData = stats['daily_trend'];
      if (trendData is List) {
        _dailyTrend = trendData.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      } else {
        _dailyTrend = [];
      }

      final wilayahData = stats['wilayah_chart'];
      if (wilayahData is List) {
        _wilayahChart = wilayahData.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      } else {
        _wilayahChart = [];
      }

      final sumberData = stats['sumber_chart'];
      if (sumberData is List) {
        _sumberChart = sumberData.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      } else {
        _sumberChart = [];
      }
    } catch (e) {
      print('Error refreshing dashboard: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
