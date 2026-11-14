import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../services/cv_picker.dart';

class ApiException implements Exception {
  /// 0 = errore di rete (server spento, indirizzo sbagliato, timeout).
  final int statusCode;
  final String message;

  const ApiException(this.statusCode, this.message);

  @override
  String toString() => message;
}

const String _networkMessage =
    'Impossibile contattare il server. Controlla che sia avviato e che l\'indirizzo in lib/config/api_config.dart sia corretto.';

class ApiClient {
  final http.Client _client;

  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  /// Token Bearer corrente (null = utente non autenticato).
  String? token;

  /// Invocato su 401 con un utente autenticato: il client fa logout locale.
  void Function()? onUnauthorized;

  Future<dynamic> get(String path, {Map<String, String?>? query}) =>
      _send('GET', path, query: query);

  Future<dynamic> post(String path, {Object? body}) =>
      _send('POST', path, body: body);

  Future<dynamic> put(String path, {Object? body}) =>
      _send('PUT', path, body: body);

  Future<dynamic> delete(String path) => _send('DELETE', path);

  /// URL del curriculum: il token viaggia come parametro perché il file viene
  /// aperto dal browser/visualizzatore PDF del sistema, fuori dall'app.
  String cvUrl(int applicationId) =>
      '${ApiConfig.baseUrl}/api/applications/$applicationId/cv?token=${token ?? ''}';

  /// R6 - invio della candidatura come multipart/form-data.
  Future<Map<String, dynamic>> applyToJob(
    int jobId, {
    required String firstName,
    required String lastName,
    required String email,
    required String message,
    required PickedCv cv,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConfig.baseUrl}/api/jobs/$jobId/applications'),
    );
    request.headers['Accept'] = 'application/json';
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    request.fields.addAll({
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'message': message,
    });
    request.files.add(
      http.MultipartFile.fromBytes('cv', cv.bytes, filename: cv.fileName),
    );

    http.Response res;
    try {
      final streamed = await _client.send(request).timeout(ApiConfig.timeout);
      res = await http.Response.fromStream(streamed)
          .timeout(ApiConfig.timeout);
    } on TimeoutException {
      throw const ApiException(0, _networkMessage);
    } on SocketException {
      throw const ApiException(0, _networkMessage);
    } on http.ClientException {
      throw const ApiException(0, _networkMessage);
    }

    final data = _decode(res);
    if (res.statusCode >= 400) {
      throw ApiException(res.statusCode, _errorMessage(data, res.statusCode));
    }
    return Map<String, dynamic>.from(data as Map);
  }

  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, String?>? query,
    Object? body,
  }) async {
    var uri = Uri.parse('${ApiConfig.baseUrl}$path');
    if (query != null) {
      final q = <String, String>{};
      query.forEach((k, v) {
        if (v != null && v.isNotEmpty) q[k] = v;
      });
      if (q.isNotEmpty) uri = uri.replace(queryParameters: q);
    }

    final req = http.Request(method, uri);
    req.headers['Accept'] = 'application/json';
    if (token != null) req.headers['Authorization'] = 'Bearer $token';
    if (body != null) {
      req.headers['Content-Type'] = 'application/json; charset=utf-8';
      req.body = jsonEncode(body);
    }

    http.Response res;
    try {
      final streamed = await _client.send(req).timeout(ApiConfig.timeout);
      res = await http.Response.fromStream(streamed)
          .timeout(ApiConfig.timeout);
    } on TimeoutException {
      throw const ApiException(0, _networkMessage);
    } on SocketException {
      throw const ApiException(0, _networkMessage);
    } on http.ClientException {
      throw const ApiException(0, _networkMessage);
    }

    final data = _decode(res);
    if (res.statusCode >= 400) {
      if (res.statusCode == 401 && token != null) onUnauthorized?.call();
      throw ApiException(res.statusCode, _errorMessage(data, res.statusCode));
    }
    return data;
  }

  dynamic _decode(http.Response res) {
    final text = utf8.decode(res.bodyBytes, allowMalformed: true);
    if (text.isEmpty) return null;
    try {
      return jsonDecode(text);
    } catch (_) {
      return null;
    }
  }

  String _errorMessage(dynamic data, int status) {
    if (data is Map && data['error'] is String) return data['error'] as String;
    return 'Errore del server ($status)';
  }
}
