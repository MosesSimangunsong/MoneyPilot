import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:http/http.dart' as http;

class SpreadsheetSyncService {
  SpreadsheetSyncService({http.Client? client, Duration? timeout})
    : _client = client ?? http.Client(),
      _timeout = timeout ?? const Duration(seconds: 20);

  static const int _maxRedirects = 3;
  static const Map<String, String> _jsonHeaders = <String, String>{
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  final http.Client _client;
  final Duration _timeout;

  Future<SpreadsheetSyncResponse> push({
    required String webAppUrl,
    required String token,
    required String entity,
    required List<Map<String, dynamic>> items,
  }) {
    _validateToken(token);
    return _send(
      webAppUrl: webAppUrl,
      operation: 'push',
      entity: entity,
      payload: <String, dynamic>{
        'token': token,
        'operation': 'push',
        'entity': entity,
        'items': items,
      },
    );
  }

  Future<SpreadsheetSyncResponse> pull({
    required String webAppUrl,
    required String token,
    required String entity,
    String? since,
  }) {
    _validateToken(token);
    return _send(
      webAppUrl: webAppUrl,
      operation: 'pull',
      entity: entity,
      payload: <String, dynamic>{
        'token': token,
        'operation': 'pull',
        'entity': entity,
        if ((since ?? '').trim().isNotEmpty) 'since': since!.trim(),
      },
    );
  }

  Future<SpreadsheetSyncResponse> healthCheck({
    required String webAppUrl,
  }) async {
    final Uri uri = _parseUri(webAppUrl);
    final String normalizedUrl = uri.toString();

    try {
      _logRequest(
        method: 'GET',
        url: normalizedUrl,
        operation: 'health_check',
        entity: '-',
      );
      final http.Response response = await _client
          .get(
            uri,
            headers: const <String, String>{'Accept': 'application/json'},
          )
          .timeout(_timeout);
      return _parseResponse(
        response,
        requestUrl: normalizedUrl,
        operation: 'health_check',
        entity: '-',
      );
    } on TimeoutException {
      throw const SpreadsheetSyncException(
        message: 'Permintaan health check melebihi batas waktu.',
        code: 'TIMEOUT',
      );
    } on http.ClientException catch (error) {
      throw SpreadsheetSyncException(
        message:
            'Tidak dapat terhubung ke Google Apps Script: ${error.message}',
        code: 'NETWORK_ERROR',
      );
    }
  }

  Future<SpreadsheetSyncResponse> _send({
    required String webAppUrl,
    required String operation,
    required String entity,
    required Map<String, dynamic> payload,
  }) async {
    final Uri uri = _parseUri(webAppUrl);
    final String normalizedUrl = uri.toString();

    try {
      _logRequest(
        method: 'POST',
        url: normalizedUrl,
        operation: operation,
        entity: entity,
      );
      final String body = jsonEncode(payload);
      final http.Response response = await _postJsonWithRedirect(
        uri: uri,
        body: body,
        operation: operation,
        entity: entity,
      ).timeout(_timeout);
      return _parseResponse(
        response,
        requestUrl: response.request?.url.toString() ?? normalizedUrl,
        operation: operation,
        entity: entity,
      );
    } on TimeoutException {
      throw SpreadsheetSyncException(
        message: 'Permintaan sinkronisasi melebihi batas waktu.',
        code: 'TIMEOUT',
        operation: operation,
        entity: entity,
        requestUrl: normalizedUrl,
      );
    } on http.ClientException catch (error) {
      throw SpreadsheetSyncException(
        message: 'Koneksi ke Google Apps Script gagal: ${error.message}',
        code: 'NETWORK_ERROR',
        operation: operation,
        entity: entity,
        requestUrl: normalizedUrl,
      );
    }
  }

  Future<http.Response> _postJsonWithRedirect({
    required Uri uri,
    required String body,
    required String operation,
    required String entity,
  }) async {
    Uri currentUri = uri;
    String currentMethod = 'POST';

    for (
      int redirectCount = 0;
      redirectCount <= _maxRedirects;
      redirectCount++
    ) {
      final http.Response response = await _sendRequestWithMethod(
        uri: currentUri,
        method: currentMethod,
        body: currentMethod == 'POST' ? body : null,
      );

      if (!_isRedirectStatus(response.statusCode)) {
        return response;
      }

      final Uri? redirectUri = _resolveRedirectUrl(
        currentUri: currentUri,
        headers: response.headers,
      );

      if (redirectUri == null) {
        return response;
      }

      if (redirectCount == _maxRedirects) {
        throw SpreadsheetSyncException(
          message:
              'Redirect Google Apps Script melebihi batas maksimum. statusCode=${response.statusCode}, location="$redirectUri"',
          code: 'TOO_MANY_REDIRECTS',
          statusCode: response.statusCode,
          operation: operation,
          entity: entity,
          requestUrl: currentUri.toString(),
          contentType: response.headers['content-type']?.trim(),
          responseSnippet: _buildResponseSnippet(response.body),
        );
      }

      final String nextMethod = _nextRedirectMethod(
        statusCode: response.statusCode,
        currentMethod: currentMethod,
      );
      developer.log(
        'Mengikuti redirect $currentMethod->$nextMethod $operation/$entity -> $redirectUri',
        name: 'SpreadsheetSyncService',
      );
      currentUri = redirectUri;
      currentMethod = nextMethod;
    }

    throw SpreadsheetSyncException(
      message: 'Redirect Google Apps Script melebihi batas maksimum.',
      code: 'TOO_MANY_REDIRECTS',
      operation: operation,
      entity: entity,
      requestUrl: uri.toString(),
    );
  }

  Future<http.Response> _sendRequestWithMethod({
    required Uri uri,
    required String method,
    String? body,
  }) async {
    final http.Request request = http.Request(method, uri);
    request.followRedirects = false;
    request.maxRedirects = 0;
    if (method == 'POST') {
      request.headers.addAll(_jsonHeaders);
      request.body = body ?? '';
    } else {
      request.headers.addAll(const <String, String>{
        'Accept': 'application/json',
      });
    }
    final http.StreamedResponse streamedResponse = await _client.send(request);
    return http.Response.fromStream(streamedResponse);
  }

  SpreadsheetSyncResponse _parseResponse(
    http.Response response, {
    required String requestUrl,
    required String operation,
    required String entity,
  }) {
    final String contentType = response.headers['content-type']?.trim() ?? '';
    final String responseSnippet = _buildResponseSnippet(response.body);

    _logResponse(
      statusCode: response.statusCode,
      contentType: contentType,
      operation: operation,
      entity: entity,
      url: requestUrl,
      responseSnippet: responseSnippet,
    );

    if (!_looksLikeJson(response.body)) {
      throw SpreadsheetSyncException(
        message:
            'Response bukan JSON valid. statusCode=${response.statusCode}, contentType=${contentType.isEmpty ? '-' : contentType}, bodyPreview="$responseSnippet"',
        code: 'INVALID_RESPONSE',
        statusCode: response.statusCode,
        operation: operation,
        entity: entity,
        requestUrl: requestUrl,
        contentType: contentType,
        responseSnippet: responseSnippet,
      );
    }

    final dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw SpreadsheetSyncException(
        message:
            'Response gagal diparse sebagai JSON. statusCode=${response.statusCode}, contentType=${contentType.isEmpty ? '-' : contentType}, bodyPreview="$responseSnippet"',
        code: 'INVALID_RESPONSE',
        statusCode: response.statusCode,
        operation: operation,
        entity: entity,
        requestUrl: requestUrl,
        contentType: contentType,
        responseSnippet: responseSnippet,
      );
    }

    if (decoded is! Map<String, dynamic>) {
      throw SpreadsheetSyncException(
        message:
            'Response Google Apps Script harus berupa object JSON. statusCode=${response.statusCode}, contentType=${contentType.isEmpty ? '-' : contentType}, bodyPreview="$responseSnippet"',
        code: 'INVALID_RESPONSE',
        statusCode: response.statusCode,
        operation: operation,
        entity: entity,
        requestUrl: requestUrl,
        contentType: contentType,
        responseSnippet: responseSnippet,
      );
    }

    final String status = decoded['status']?.toString().trim() ?? '';
    if (status.isEmpty) {
      throw SpreadsheetSyncException(
        message:
            'Field status tidak ditemukan di response JSON. statusCode=${response.statusCode}, contentType=${contentType.isEmpty ? '-' : contentType}, bodyPreview="$responseSnippet"',
        code: 'INVALID_RESPONSE',
        statusCode: response.statusCode,
        operation: operation,
        entity: entity,
        requestUrl: requestUrl,
        contentType: contentType,
        responseSnippet: responseSnippet,
      );
    }

    if (response.statusCode >= 400 || status == 'error') {
      throw SpreadsheetSyncException(
        message: decoded['message']?.toString().trim().isNotEmpty == true
            ? decoded['message'].toString().trim()
            : 'Sinkronisasi ke spreadsheet gagal.',
        code: decoded['code']?.toString().trim().isNotEmpty == true
            ? decoded['code'].toString().trim()
            : 'SYNC_ERROR',
        statusCode: response.statusCode,
        operation: operation,
        entity: entity,
        requestUrl: requestUrl,
        contentType: contentType,
        responseSnippet: responseSnippet,
      );
    }

    final List<Map<String, dynamic>> items = _readItems(
      decoded['items'],
      statusCode: response.statusCode,
      contentType: contentType,
      responseSnippet: responseSnippet,
      operation: operation,
      entity: entity,
      requestUrl: requestUrl,
    );

    return SpreadsheetSyncResponse(
      status: status,
      inserted: _readInt(decoded['inserted']),
      updated: _readInt(decoded['updated']),
      failed: _readInt(decoded['failed']),
      serverTime: _readNullableDateTime(decoded['serverTime']),
      message: decoded['message']?.toString(),
      code: decoded['code']?.toString(),
      items: items,
    );
  }

  Uri _parseUri(String value) {
    final String normalized = value.replaceAll(RegExp(r'[\r\n\t]'), '').trim();
    if (normalized.isEmpty) {
      throw const SpreadsheetSyncException(
        message: 'URL Google Apps Script wajib diisi.',
        code: 'MISSING_URL',
      );
    }
    final Uri? uri = Uri.tryParse(normalized);
    if (uri == null ||
        !uri.hasScheme ||
        !uri.hasAuthority ||
        !uri.path.endsWith('/exec')) {
      throw SpreadsheetSyncException(
        message:
            'URL Google Apps Script tidak valid. Gunakan URL Web App /exec.',
        code: 'INVALID_URL',
        requestUrl: normalized,
      );
    }
    return uri;
  }

  void _validateToken(String value) {
    if (value.replaceAll(RegExp(r'[\r\n\t]'), '').trim().isEmpty) {
      throw const SpreadsheetSyncException(
        message: 'Secret token wajib diisi.',
        code: 'MISSING_TOKEN',
      );
    }
  }

  bool _isRedirectStatus(int statusCode) {
    return statusCode == 301 ||
        statusCode == 302 ||
        statusCode == 303 ||
        statusCode == 307 ||
        statusCode == 308;
  }

  Uri? _resolveRedirectUrl({
    required Uri currentUri,
    required Map<String, String> headers,
  }) {
    final String? rawLocation = headers['location']?.trim();
    if (rawLocation == null || rawLocation.isEmpty) {
      return null;
    }

    return currentUri.resolve(rawLocation);
  }

  String _nextRedirectMethod({
    required int statusCode,
    required String currentMethod,
  }) {
    if (statusCode == 301 || statusCode == 302 || statusCode == 303) {
      return 'GET';
    }

    if (statusCode == 307 || statusCode == 308) {
      return currentMethod;
    }

    return currentMethod;
  }

  List<Map<String, dynamic>> _readItems(
    dynamic value, {
    required int statusCode,
    required String contentType,
    required String responseSnippet,
    required String operation,
    required String entity,
    required String requestUrl,
  }) {
    if (value == null) {
      return const <Map<String, dynamic>>[];
    }

    if (value is List<dynamic>) {
      return value
          .map((dynamic item) {
            if (item is Map<String, dynamic>) {
              return item;
            }
            if (item is Map) {
              return Map<String, dynamic>.from(item);
            }
            throw SpreadsheetSyncException(
              message:
                  'Field items harus berisi object JSON. statusCode=$statusCode, contentType=${contentType.isEmpty ? '-' : contentType}, bodyPreview="$responseSnippet"',
              code: 'INVALID_RESPONSE',
              statusCode: statusCode,
              operation: operation,
              entity: entity,
              requestUrl: requestUrl,
              contentType: contentType,
              responseSnippet: responseSnippet,
            );
          })
          .toList(growable: false);
    }

    if (value is Map && value.isEmpty) {
      return const <Map<String, dynamic>>[];
    }

    throw SpreadsheetSyncException(
      message:
          'Field items harus berupa array JSON. statusCode=$statusCode, contentType=${contentType.isEmpty ? '-' : contentType}, bodyPreview="$responseSnippet"',
      code: 'INVALID_RESPONSE',
      statusCode: statusCode,
      operation: operation,
      entity: entity,
      requestUrl: requestUrl,
      contentType: contentType,
      responseSnippet: responseSnippet,
    );
  }

  bool _looksLikeJson(String value) {
    final String trimmed = value.trimLeft();
    return trimmed.startsWith('{') || trimmed.startsWith('[');
  }

  String _buildResponseSnippet(String value) {
    final String compact = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (compact.isEmpty) {
      return '<empty>';
    }
    if (compact.length <= 300) {
      return compact;
    }
    return '${compact.substring(0, 300)}...';
  }

  void _logRequest({
    required String method,
    required String url,
    required String operation,
    required String entity,
  }) {
    developer.log(
      '$method $operation/$entity -> $url',
      name: 'SpreadsheetSyncService',
    );
  }

  void _logResponse({
    required int statusCode,
    required String contentType,
    required String operation,
    required String entity,
    required String url,
    required String responseSnippet,
  }) {
    developer.log(
      'Response $operation/$entity <- $url statusCode=$statusCode contentType=${contentType.isEmpty ? '-' : contentType} bodyPreview="$responseSnippet"',
      name: 'SpreadsheetSyncService',
    );
  }

  int _readInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  DateTime? _readNullableDateTime(dynamic value) {
    final String normalized = value?.toString().trim() ?? '';
    if (normalized.isEmpty) {
      return null;
    }
    final DateTime? parsed = DateTime.tryParse(normalized);
    return parsed?.toUtc();
  }
}

class SpreadsheetSyncResponse {
  const SpreadsheetSyncResponse({
    required this.status,
    required this.inserted,
    required this.updated,
    required this.failed,
    required this.serverTime,
    required this.message,
    required this.code,
    required this.items,
  });

  final String status;
  final int inserted;
  final int updated;
  final int failed;
  final DateTime? serverTime;
  final String? message;
  final String? code;
  final List<Map<String, dynamic>> items;
}

class SpreadsheetSyncException implements Exception {
  const SpreadsheetSyncException({
    required this.message,
    required this.code,
    this.statusCode,
    this.operation,
    this.entity,
    this.requestUrl,
    this.contentType,
    this.responseSnippet,
  });

  final String message;
  final String code;
  final int? statusCode;
  final String? operation;
  final String? entity;
  final String? requestUrl;
  final String? contentType;
  final String? responseSnippet;

  @override
  String toString() {
    return 'SpreadsheetSyncException(code: $code, message: $message, statusCode: $statusCode, operation: $operation, entity: $entity, requestUrl: $requestUrl, contentType: $contentType, responseSnippet: $responseSnippet)';
  }
}
