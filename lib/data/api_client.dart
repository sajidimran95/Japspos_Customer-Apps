import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/config.dart';
import 'repository.dart';

/// Thrown on 401/403 from an authenticated endpoint: the token is no longer
/// valid (logged out, user blocked, permission removed). The app signs out.
class AuthExpiredException extends RepoException {
  AuthExpiredException(super.message);
}

/// The JapsPos envelope `{ success, message, data, meta }`.
class ApiResponse {
  ApiResponse(this.data, this.message, this.meta);
  final dynamic data;
  final String? message;
  final Map<String, dynamic> meta;

  Map<String, dynamic> get map => data is Map ? Map<String, dynamic>.from(data as Map) : <String, dynamic>{};
  bool get hasMore => meta['has_more'] == true;
}

class ApiClient {
  ApiClient({required this.baseUrl, this.token, this.onAuthExpired});

  final String baseUrl;
  String? token;
  void Function()? onAuthExpired;

  /// Any store domain. `www.xyz.com` and `https://www.xyz.com/customer` both
  /// become `https://www.xyz.com`. Paths are dropped so API calls always use
  /// `{domain}/api/v1/customer`.
  static String normalizeBaseUrl(String raw) {
    var url = raw.trim();
    if (url.isEmpty) return url;
    if (!url.contains('://')) url = 'https://$url';
    final uri = Uri.tryParse(url);
    if (uri == null || uri.host.isEmpty) return url;
    final scheme = uri.scheme == 'http' ? 'http' : 'https';
    final port = uri.hasPort ? ':${uri.port}' : '';
    return '$scheme://${uri.host.toLowerCase()}$port';
  }

  /// Returns null when [baseUrl] runs the JapsPos mobile API, or a reason otherwise.
  static Future<String?> ping(String baseUrl) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl${AppConfig.pingPath}'), headers: {'Accept': 'application/json'}).timeout(AppConfig.activationTimeout);
      final body = jsonDecode(res.body);
      if (res.statusCode == 200 && body is Map && body['success'] == true && body['data'] is Map && body['data']['api'] == AppConfig.pingApiId) {
        return null;
      }
      return 'This server does not have the JapsPos mobile API (HTTP ${res.statusCode}).';
    } on FormatException {
      return 'This address is not a JapsPos server.';
    } catch (_) {
      return 'Could not reach the server. Check the URL and your connection.';
    }
  }

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final q = <String, String>{};
    query?.forEach((k, v) {
      if (v != null && '$v'.isNotEmpty) q[k] = '$v';
    });
    return Uri.parse('$baseUrl${AppConfig.apiPrefix}$path').replace(queryParameters: q.isEmpty ? null : q);
  }

  Map<String, String> get _headers => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  ApiResponse _decode(http.Response res, {bool authCall = false}) {
    dynamic body;
    try {
      body = res.body.isEmpty ? null : jsonDecode(res.body);
    } on FormatException {
      body = null;
    }
    final map = body is Map ? body : const {};
    if (res.statusCode >= 200 && res.statusCode < 300 && map['success'] != false) {
      return ApiResponse(map['data'], map['message'] as String?, map['meta'] is Map ? Map<String, dynamic>.from(map['meta']) : const {});
    }
    var msg = map['message'] != null ? '${map['message']}' : 'Request failed (${res.statusCode})';
    final errors = map['errors'];
    if (errors is Map && errors.isNotEmpty) {
      final first = errors.values.first;
      msg = first is List && first.isNotEmpty ? '${first.first}' : '$first';
    }
    // For customers a 403 always means Customer App access was disabled.
    if (!authCall && token != null && (res.statusCode == 401 || res.statusCode == 403)) {
      onAuthExpired?.call();
      throw AuthExpiredException(res.statusCode == 401 ? 'Session expired. Please sign in again.' : msg);
    }
    throw RepoException(msg, data: map['data']);
  }

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on RepoException {
      rethrow;
    } on TimeoutException {
      throw RepoException('The server took too long to respond. Try again.');
    } on SocketException {
      throw RepoException('Network error. Check your connection.');
    } on http.ClientException {
      throw RepoException('Network error. Check your connection.');
    } catch (e) {
      debugPrint('ApiClient error: $e');
      throw RepoException('Unexpected server response.');
    }
  }

  Future<ApiResponse> get(String path, [Map<String, dynamic>? query]) =>
      _guard(() async => _decode(await http.get(_uri(path, query), headers: _headers).timeout(AppConfig.requestTimeout)));

  Future<ApiResponse> send(String method, String path, {Object? body, Map<String, dynamic>? query, bool authCall = false}) => _guard(() async {
        final req = http.Request(method, _uri(path, query))
          ..headers.addAll(_headers)
          ..body = body == null ? '' : jsonEncode(body);
        final streamed = await req.send().timeout(AppConfig.requestTimeout);
        return _decode(await http.Response.fromStream(streamed), authCall: authCall);
      });

  Future<ApiResponse> post(String path, [Object? body]) => send('POST', path, body: body);
  Future<ApiResponse> put(String path, [Object? body]) => send('PUT', path, body: body);
  Future<ApiResponse> delete(String path, [Map<String, dynamic>? query]) => send('DELETE', path, query: query);

  Future<ApiResponse> multipart(String path, Map<String, String> fields, {String? filePath, String fileField = 'document'}) => _guard(() async {
        final req = http.MultipartRequest('POST', _uri(path))
          ..headers.addAll({..._headers}..remove('Content-Type'))
          ..fields.addAll(fields);
        if (filePath != null) req.files.add(await http.MultipartFile.fromPath(fileField, filePath));
        final streamed = await req.send().timeout(AppConfig.requestTimeout);
        return _decode(await http.Response.fromStream(streamed));
      });

  /// Raw bytes (invoice PDF).
  Future<Uint8List> bytes(String path, [Map<String, dynamic>? query]) => _guard(() async {
        final res = await http.get(_uri(path, query), headers: {..._headers, 'Accept': 'application/pdf'}).timeout(AppConfig.requestTimeout);
        if (res.statusCode != 200) _decode(res);
        return res.bodyBytes;
      });
}
