import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/company.dart';
import '../services/api_client.dart';

class AuthProvider extends ChangeNotifier {
  static const _tokenKey = 'auth_token';

  final ApiClient _api;
  Company? _company;
  bool _initializing = true;
  bool _manualLogout = false;

  /// true quando il logout è forzato da un 401 (letto da main.dart).
  bool sessionExpired = false;

  AuthProvider(this._api) {
    _api.onUnauthorized = _handleUnauthorized;
  }

  Company? get company => _company;
  bool get isLoggedIn => _company != null;
  bool get initializing => _initializing;

  /// Ripristina la sessione salvata chiamando /api/auth/me.
  Future<void> restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      if (token != null && token.isNotEmpty) {
        _api.token = token;
        try {
          final json = await _api.get('/api/auth/me');
          _company = Company.fromJson(Map<String, dynamic>.from(json as Map));
        } catch (_) {
          await _clearLocal();
        }
      }
    } finally {
      _initializing = false;
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    final json = await _api.post(
      '/api/auth/login',
      body: {'email': email, 'password': password},
    );
    await _setSession(json as Map);
  }

  Future<void> register(String name, String email, String password) async {
    final json = await _api.post(
      '/api/auth/register',
      body: {'name': name, 'email': email, 'password': password},
    );
    await _setSession(json as Map);
  }

  Future<void> logout() async {
    _manualLogout = true;
    try {
      await _api.post('/api/auth/logout');
    } catch (_) {
      // anche se il server non risponde si esce comunque in locale
    }
    await _clearLocal();
    _manualLogout = false;
  }

  Future<void> _setSession(Map json) async {
    final token = json['token'] as String;
    _api.token = token;
    _company = Company.fromJson(
      Map<String, dynamic>.from(json['company'] as Map),
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    notifyListeners();
  }

  void _handleUnauthorized() {
    if (_company == null || _initializing || _manualLogout) return;
    sessionExpired = true;
    _clearLocal();
  }

  Future<void> _clearLocal() async {
    _api.token = null;
    _company = null;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }
}
