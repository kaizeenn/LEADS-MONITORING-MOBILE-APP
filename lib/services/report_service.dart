import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/leads_model.dart';

class ReportService {
  static const String apiBaseUrl = 'http://localhost:3000/api';

  // Fetch all leads with details
  Future<List<LeadsModel>> getLeadsWithDetails(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/leads'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((e) => LeadsModel.fromMap(e)).toList();
      } else {
        throw Exception('Failed to load leads from server');
      }
    } catch (e) {
      print('Error in getLeadsWithDetails: $e');
      return [];
    }
  }

  // Fetch filtered leads
  Future<List<LeadsModel>> getFilteredLeads(
    String token, {
    String? startDate,
    String? endDate,
    int? wilayahId,
    int? sumberId,
  }) async {
    try {
      final queryParams = <String>[];
      if (startDate != null) queryParams.add('startDate=$startDate');
      if (endDate != null) queryParams.add('endDate=$endDate');
      if (wilayahId != null) queryParams.add('wilayah_id=$wilayahId');
      if (sumberId != null) queryParams.add('sumber_id=$sumberId');

      final queryString = queryParams.isNotEmpty ? '?${queryParams.join('&')}' : '';

      final response = await http.get(
        Uri.parse('$apiBaseUrl/leads$queryString'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((e) => LeadsModel.fromMap(e)).toList();
      } else {
        throw Exception('Failed to load filtered leads from server');
      }
    } catch (e) {
      print('Error in getFilteredLeads: $e');
      return [];
    }
  }

  // Get dashboard statistics
  Future<Map<String, dynamic>> getDashboardStats(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/dashboard'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        return {
          'today_total': data['todayTotal'] as int? ?? 0,
          'month_total': data['monthTotal'] as int? ?? 0,
          'year_total': data['yearTotal'] as int? ?? 0,
          'best_wilayah': data['bestWilayah'] as String? ?? '-',
          'best_sumber': data['bestSumber'] as String? ?? '-',
          'daily_trend': List<Map<String, dynamic>>.from(data['dailyTrend'] ?? []),
          'wilayah_chart': List<Map<String, dynamic>>.from(data['wilayahChart'] ?? []),
          'sumber_chart': List<Map<String, dynamic>>.from(data['sumberChart'] ?? []),
        };
      } else {
        throw Exception('Failed to load dashboard stats');
      }
    } catch (e) {
      print('Error in getDashboardStats: $e');
      return {
        'today_total': 0,
        'month_total': 0,
        'year_total': 0,
        'best_wilayah': '-',
        'best_sumber': '-',
        'daily_trend': <Map<String, dynamic>>[],
        'wilayah_chart': <Map<String, dynamic>>[],
        'sumber_chart': <Map<String, dynamic>>[],
      };
    }
  }
}
