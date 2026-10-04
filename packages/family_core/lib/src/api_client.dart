import 'dart:convert';

import 'package:http/http.dart' as http;

/// Supplies the bearer token for each request (a Firebase ID token, or a demo user id).
typedef TokenProvider = Future<String?> Function();

/// An error response from the FamCare server (RFC 9457 problem details).
class ApiException implements Exception {
  const ApiException(this.statusCode, this.code, this.message);

  final int statusCode;

  /// Stable value to branch on, e.g. `NOT_IN_FAMILY`, `NOT_FOUND`, `CONFLICT`.
  final String? code;
  final String message;

  @override
  String toString() => 'ApiException($statusCode, $code): $message';
}

/// Thin JSON-over-HTTP client for the FamCare server. Feature APIs (family, gate
/// alerts, vitamins…) are built on top of it.
class ApiClient {
  ApiClient({required this.baseUrl, required TokenProvider token, http.Client? client})
      : _token = token, // ignore: prefer_initializing_formals — a private named parameter isn't allowed
        _http = client ?? http.Client();

  final Uri baseUrl;
  final TokenProvider _token;
  final http.Client _http;

  static const _timeout = Duration(seconds: 15);

  Future<dynamic> get(String path) => _send('GET', path);

  Future<dynamic> post(String path, [Object? body]) => _send('POST', path, body);

  Future<dynamic> put(String path, [Object? body]) => _send('PUT', path, body);

  Future<dynamic> _send(String method, String path, [Object? body]) async {
    final request = http.Request(method, baseUrl.resolve(path));
    final token = await _token();
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }

    final response = await http.Response.fromStream(await _http.send(request).timeout(_timeout));
    if (response.statusCode >= 400) throw _toException(response);
    if (response.statusCode == 204 || response.body.isEmpty) return null;
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  static ApiException _toException(http.Response response) {
    try {
      final problem = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      return ApiException(response.statusCode, problem['code'] as String?,
          (problem['detail'] ?? problem['title'] ?? 'Request failed') as String);
    } on FormatException {
      final message = response.statusCode == 401 ? 'Please sign in again' : 'Request failed';
      return ApiException(response.statusCode, null, message);
    }
  }
}
