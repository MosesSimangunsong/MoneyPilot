import 'dart:convert';

import 'package:app/data/services/backend_status_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('BackendStatusService membaca health sukses', () async {
    final BackendStatusService service = BackendStatusService(
      client: MockClient((http.Request request) async {
        return http.Response(
          jsonEncode(<String, dynamic>{
            'status': 'success',
            'message': 'MoneyPilot backend is healthy',
            'serverTime': '2026-07-10T10:00:00Z',
          }),
          200,
        );
      }),
      baseUrl: 'http://localhost:5000',
    );

    final BackendStatusResult result = await service.checkHealth();

    expect(result.isConnected, isTrue);
    expect(result.message, contains('healthy'));
    expect(result.serverTime?.isUtc, isTrue);
  });

  test('BackendStatusService fallback saat backend gagal', () async {
    final BackendStatusService service = BackendStatusService(
      client: MockClient((http.Request request) async {
        throw http.ClientException('network failed');
      }),
      baseUrl: 'http://localhost:5000',
    );

    final BackendStatusResult result = await service.checkHealth();

    expect(result.isConnected, isFalse);
    expect(result.message, contains('belum dapat dihubungi'));
  });
}
