import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class AuthProvider extends ChangeNotifier {
  static const String apiBaseUrl = 'http://localhost:3000/api';

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

  Future<void> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('token')) return;

    final storedToken = prefs.getString('token');
    if (storedToken == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/auth/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $storedToken',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _token = storedToken;
        _user = data['user'];
      } else {
        // Token expired or invalid
        await prefs.remove('token');
      }
    } catch (e) {
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
      final response = await http.post(
        Uri.parse('$apiBaseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username.trim(),
          'password': password.trim(),
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        _token = data['token'];
        _user = data['user'];

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
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'error': 'Gagal terhubung ke server'};
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
