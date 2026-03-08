import 'dart:convert';

import 'package:http/http.dart' as http;

/// API 异常
class ApiException implements Exception {
  final int code;
  final String message;
  ApiException(this.code, this.message);

  @override
  String toString() => 'ApiException($code): $message';
}

/// HTTP API 客户端
///
/// 封装 JWT 认证、统一响应解析、错误处理
class ApiClient {
  static const String defaultBaseUrl = 'https://seat.phoenixcity.online/api/v1';

  String _baseUrl;
  String? _token;

  ApiClient({String? baseUrl}) : _baseUrl = baseUrl ?? defaultBaseUrl;

  /// 获取/设置后端 URL
  String get baseUrl => _baseUrl;
  void setBaseUrl(String url) {
    _baseUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  /// 设置 JWT Token
  void setToken(String? token) {
    _token = token;
  }

  /// 获取当前 Token
  String? get token => _token;

  /// 是否有有效 Token
  bool get hasToken => _token != null && _token!.isNotEmpty;

  /// 构建请求头
  Map<String, String> _headers({bool json = true}) {
    final headers = <String, String>{};
    if (json) {
      headers['Content-Type'] = 'application/json';
    }
    if (_token != null && _token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  /// 解析统一响应格式
  dynamic _parseResponse(http.Response response) {
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final code = body['code'] as int? ?? response.statusCode;
    final msg = body['msg'] as String? ?? 'Unknown error';
    final data = body['data'];

    if (code != 200) {
      throw ApiException(code, msg);
    }
    return data;
  }

  /// GET 请求
  Future<dynamic> get(String path,
      {Map<String, String>? queryParams}) async {
    final uri = Uri.parse('$_baseUrl$path').replace(
      queryParameters: queryParams?.isNotEmpty == true ? queryParams : null,
    );
    final response = await http.get(uri, headers: _headers(json: false));
    return _parseResponse(response);
  }

  /// POST 请求
  Future<dynamic> post(String path, {Object? body}) async {
    final uri = Uri.parse('$_baseUrl$path');
    final response = await http.post(
      uri,
      headers: _headers(),
      body: body != null ? jsonEncode(body) : null,
    );
    return _parseResponse(response);
  }

  /// PUT 请求
  Future<dynamic> put(String path, {Object? body}) async {
    final uri = Uri.parse('$_baseUrl$path');
    final response = await http.put(
      uri,
      headers: _headers(),
      body: body != null ? jsonEncode(body) : null,
    );
    return _parseResponse(response);
  }

  /// DELETE 请求
  Future<dynamic> delete(String path) async {
    final uri = Uri.parse('$_baseUrl$path');
    final response = await http.delete(uri, headers: _headers(json: false));
    return _parseResponse(response);
  }
}
