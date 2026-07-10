import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/constants/api_constants.dart';

class BackendStatusService {
  BackendStatusService({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = (baseUrl ?? ApiConstants.defaultBackendBaseUrl).trim();

  final http.Client _client;
  final String _baseUrl;

  Future<BackendStatusResult> checkHealth() async {
    if (_baseUrl.isEmpty) {
      return const BackendStatusResult(
        isConnected: false,
        message: 'URL backend belum diatur.',
      );
    }

    final Uri uri = Uri.parse('$_baseUrl/api/health');
    try {
      final http.Response response = await _client.get(uri);
      if (response.statusCode != 200) {
        return BackendStatusResult(
          isConnected: false,
          message: 'Backend merespons dengan status ${response.statusCode}.',
        );
      }

      final Map<String, dynamic> payload =
          jsonDecode(response.body) as Map<String, dynamic>;
      final String message =
          (payload['message'] as String?)?.trim().isNotEmpty == true
          ? (payload['message'] as String).trim()
          : 'Backend MoneyPilot terhubung.';
      final DateTime? serverTime = DateTime.tryParse(
        payload['serverTime'] as String? ?? '',
      )?.toUtc();

      return BackendStatusResult(
        isConnected: true,
        message: message,
        serverTime: serverTime,
      );
    } catch (_) {
      return const BackendStatusResult(
        isConnected: false,
        message: 'Server MoneyPilot belum dapat dihubungi.',
      );
    }
  }
}

class BackendStatusResult {
  const BackendStatusResult({
    required this.isConnected,
    required this.message,
    this.serverTime,
  });

  final bool isConnected;
  final String message;
  final DateTime? serverTime;
}
