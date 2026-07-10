import 'dart:convert';

import 'package:app/data/services/market_data_api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('MarketDataApiService parse single quote sukses', () async {
    final service = MarketDataApiService(
      client: MockClient((http.Request request) async {
        return http.Response(
          jsonEncode(<String, dynamic>{
            'status': 'success',
            'data': <String, dynamic>{
              'symbol': 'BBCA.JK',
              'price': 9050,
              'currency': 'IDR',
              'source': 'mock',
              'asOf': '2026-07-09T00:00:00Z',
              'isStale': false,
            },
          }),
          200,
        );
      }),
      baseUrl: 'http://localhost:5000',
    );

    final quote = await service.getQuote('BBCA.JK');

    expect(quote?.symbol, 'BBCA.JK');
    expect(quote?.price, 9050);
  });

  test('MarketDataApiService parse quote sukses', () async {
    final service = MarketDataApiService(
      client: MockClient((http.Request request) async {
        return http.Response(
          jsonEncode(<String, dynamic>{
            'status': 'success',
            'data': <Map<String, dynamic>>[
              <String, dynamic>{
                'symbol': 'BBCA.JK',
                'price': 9050,
                'currency': 'IDR',
                'source': 'mock',
                'asOf': '2026-07-09T00:00:00Z',
                'isStale': false,
              },
            ],
          }),
          200,
        );
      }),
      baseUrl: 'http://localhost:5000',
    );

    final quotes = await service.getQuotes(<String>['BBCA.JK']);

    expect(quotes['BBCA.JK']?.price, 9050);
    expect(quotes['BBCA.JK']?.currency, 'IDR');
  });

  test('MarketDataApiService menangani backend error', () async {
    final service = MarketDataApiService(
      client: MockClient((http.Request request) async {
        return http.Response(
          jsonEncode(<String, dynamic>{
            'status': 'error',
            'message': 'backend unavailable',
          }),
          503,
        );
      }),
      baseUrl: 'http://localhost:5000',
    );

    final quotes = await service.getQuotes(<String>['BBCA.JK']);

    expect(quotes, isEmpty);
  });

  test('MarketDataApiService menangani single quote gagal', () async {
    final service = MarketDataApiService(
      client: MockClient((http.Request request) async {
        return http.Response(
          jsonEncode(<String, dynamic>{
            'status': 'error',
            'message': 'backend unavailable',
          }),
          503,
        );
      }),
      baseUrl: 'http://localhost:5000',
    );

    final quote = await service.getQuote('BBCA.JK');

    expect(quote, isNull);
  });

  test(
    'MarketDataApiService menangani batch quote gagal karena exception',
    () async {
      final service = MarketDataApiService(
        client: MockClient((http.Request request) async {
          throw http.ClientException('connection failed');
        }),
        baseUrl: 'http://localhost:5000',
      );

      final quotes = await service.getQuotes(<String>['BBCA.JK', 'TLKM.JK']);

      expect(quotes, isEmpty);
    },
  );
}
