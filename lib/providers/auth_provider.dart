import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService api;

  String? _token;
  Map<String, dynamic>? _user;
  bool _initializing = true;

  AuthProvider(this.api) {
    _restoreSession();
  }

  bool get isLoggedIn => _token != null;
  bool get isInitializing => _initializing;
  Map<String, dynamic>? get user => _user;
  String? get displayName =>
      (_user?['full_name'] as String?) ?? (_user?['email'] as String?);

  Future<void> _restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token != null) {
      _token = token;
      api.setAuthToken(token);
    }
    _initializing = false;
    notifyListeners();
  }

  Future<void> _persistSession(String token, Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    _token = token;
    _user = user;
    api.setAuthToken(token);
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    final result = await api.login(email: email, password: password);
    await _persistSession(
      result['access_token'] as String,
      result['user'] as Map<String, dynamic>,
    );
  }

  Future<void> register(String email, String password, String? fullName) async {
    final result = await api.register(
      email: email,
      password: password,
      fullName: fullName,
    );
    await _persistSession(
      result['access_token'] as String,
      result['user'] as Map<String, dynamic>,
    );
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    _token = null;
    _user = null;
    api.setAuthToken(null);
    notifyListeners();
  }
}
