import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/leads_model.dart';
import '../models/leads_tour_model.dart';

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
  Future<List<dynamic>> getFilteredLeads(
    String token, {
    String division = 'marketing',
    String? startDate,
    String? endDate,
    int? wilayahId,
    int? sumberId,
    String? lokasi,
  }) async {
    try {
      final queryParams = <String>[];
      if (startDate != null) queryParams.add('startDate=$startDate');
      if (endDate != null) queryParams.add('endDate=$endDate');
      if (division == 'marketing') {
        if (wilayahId != null) queryParams.add('wilayah_id=$wilayahId');
      } else {
        if (lokasi != null && lokasi.isNotEmpty) queryParams.add('lokasi=$lokasi');
      }
      if (sumberId != null) queryParams.add('sumber_id=$sumberId');

      final queryString = queryParams.isNotEmpty ? '?${queryParams.join('&')}' : '';
      final endpoint = division == 'marketing' ? '/leads' : '/leads-tour';

      final response = await http.get(
        Uri.parse('$apiBaseUrl$endpoint$queryString'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (division == 'marketing') {
          return data.map((e) => LeadsModel.fromMap(e)).toList();
        } else {
          return data.map((e) => LeadsTourModel.fromMap(e)).toList();
        }
      } else {
        throw Exception('Failed to load filtered leads from server');
      }
    } catch (e) {
      print('Error in getFilteredLeads: $e');
      return [];
    }
  }

  // Get dashboard statistics
  Future<Map<String, dynamic>> getDashboardStats(String token, {String division = 'marketing'}) async {
    try {
      final endpoint = division == 'marketing' ? '/dashboard' : '/dashboard-tour';
      final response = await http.get(
        Uri.parse('$apiBaseUrl$endpoint'),
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
          'daily_trend': (data['dailyTrend'] as List<dynamic>?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [],
          'wilayah_chart': (data['wilayahChart'] as List<dynamic>?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [],
          'sumber_chart': (data['sumberChart'] as List<dynamic>?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [],
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
