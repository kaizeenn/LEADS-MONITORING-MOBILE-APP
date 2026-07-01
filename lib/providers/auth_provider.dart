import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class AuthProvider extends ChangeNotifier {
  static const String apiBaseUrl = AppConfig.apiBaseUrl;

  String? _token;
  Map<String, dynamic>? _user;
  bool _isLoading = false;

  String? get token => _token;
  Map<String, dynamic>? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _token != null;

  String get userRole => _user?['role'] ?? 'karyawan';
  String get userName => _user?['nama_lengkap'] ?? 'Karyawan';
  String get userEmail => _user?['username'] ?? '';
  int get userId => _user?['id'] ?? 0;
  String get userBagian => _user?['bagian'] ?? '';

  Future<void> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('token')) return;

    final storedToken = prefs.getString('token');
    if (storedToken == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final response = await http
          .get(
            Uri.parse('$apiBaseUrl/auth/me'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $storedToken',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final payload =
            data is Map<String, dynamic> && data['data'] is Map<String, dynamic>
            ? data['data'] as Map<String, dynamic>
            : data;
        final userData = payload is Map<String, dynamic>
            ? payload['user']
            : null;

        if (userData is! Map<String, dynamic>) {
          await prefs.remove('token');
          return;
        }

        final role = userData['role'];
        if (role == 'admin' || role == 'owner') {
          await prefs.remove('token');
        } else {
          _token = storedToken;
          _user = userData;
        }
      } else {
        // Token expired or invalid
        await prefs.remove('token');
      }
    } on TimeoutException {
      await prefs.remove('token');
      print('Auto login error: request timeout');
    } on SocketException catch (e) {
      await prefs.remove('token');
      print('Auto login error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http
          .post(
            Uri.parse('$apiBaseUrl/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'username': username.trim(),
              'password': password.trim(),
            }),
          )
          .timeout(const Duration(seconds: 15));

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        final payload =
            data is Map<String, dynamic> && data['data'] is Map<String, dynamic>
            ? data['data'] as Map<String, dynamic>
            : data;
        final userData = payload is Map<String, dynamic>
            ? payload['user']
            : null;
        final token = payload is Map<String, dynamic> ? payload['token'] : null;

        if (userData is! Map<String, dynamic> ||
            token is! String ||
            token.isEmpty) {
          _isLoading = false;
          notifyListeners();
          return {'success': false, 'error': 'Respons server tidak valid'};
        }

        final role = userData['role'];
        if (role == 'admin' || role == 'owner') {
          _isLoading = false;
          notifyListeners();
          return {
            'success': false,
            'error': 'Akses ditolak. Aplikasi ini khusus Karyawan.',
          };
        }

        _token = token;
        _user = userData;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _token!);

        _isLoading = false;
        notifyListeners();
        return {'success': true};
      } else {
        _isLoading = false;
        notifyListeners();
        return {'success': false, 'error': data['error'] ?? 'Login gagal'};
      }
    } on TimeoutException {
      _isLoading = false;
      notifyListeners();
      return {
        'success': false,
        'error':
            'Request timeout. Jika pakai HP fisik, pastikan API_BASE_URL memakai IP laptop, bukan 10.0.2.2.',
      };
    } on SocketException catch (_) {
      _isLoading = false;
      notifyListeners();
      return {
        'success': false,
        'error':
            'Tidak bisa terhubung ke server. Cek IP backend dan jaringan device.',
      };
    }
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    notifyListeners();
  }
}
