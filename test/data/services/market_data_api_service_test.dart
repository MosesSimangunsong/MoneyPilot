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
              'displaySymbol': 'BBCA',
              'price': 9050,
              'currency': 'IDR',
              'source': 'mock',
              'provider': 'MockMarketDataProvider',
              'isMock': true,
              'isFallback': false,
              'asOf': '2026-07-09T00:00:00Z',
              'cachedAt': '2026-07-09T00:05:00Z',
              'cacheTtlSeconds': 900,
              'message':
                  'Data pasar bersifat estimasi dan bukan rekomendasi investasi.',
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
    expect(quote?.displaySymbol, 'BBCA');
    expect(quote?.price, 9050);
    expect(quote?.isMock, isTrue);
  });

  test('MarketDataApiService parse quote batch contract baru', () async {
    final service = MarketDataApiService(
      client: MockClient((http.Request request) async {
        return http.Response(
          jsonEncode(<String, dynamic>{
            'status': 'success',
            'data': <String, dynamic>{
              'quotes': <Map<String, dynamic>>[
                <String, dynamic>{
                  'symbol': 'BBCA.JK',
                  'displaySymbol': 'BBCA',
                  'price': 9050,
                  'currency': 'IDR',
                  'source': 'mock',
                  'provider': 'MockMarketDataProvider',
                  'isMock': true,
                  'isFallback': false,
                  'asOf': '2026-07-09T00:00:00Z',
                  'cachedAt': '2026-07-09T00:05:00Z',
                  'cacheTtlSeconds': 900,
                  'message':
                      'Data pasar bersifat estimasi dan bukan rekomendasi investasi.',
                  'isStale': false,
                },
              ],
              'errors': <Map<String, dynamic>>[],
              'count': 1,
            },
          }),
          200,
        );
      }),
      baseUrl: 'http://localhost:5000',
    );

    final response = await service.getQuotesResult(<String>['BBCA.JK']);

    expect(response.quotes['BBCA.JK']?.price, 9050);
    expect(response.quotes['BBCA.JK']?.currency, 'IDR');
    expect(response.backendReachable, isTrue);
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

    final response = await service.getQuotesResult(<String>['BBCA.JK']);

    expect(response.quotes, isEmpty);
    expect(response.backendReachable, isTrue);
    expect(response.message, 'backend unavailable');
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

    final result = await service.getQuoteResult('BBCA.JK');

    expect(result.quote, isNull);
    expect(result.backendReachable, isTrue);
    expect(result.message, 'backend unavailable');
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

      final response = await service.getQuotesResult(<String>[
        'BBCA.JK',
        'TLKM.JK',
      ]);

      expect(response.quotes, isEmpty);
      expect(response.backendReachable, isFalse);
    },
  );

  test(
    'MarketDataApiService tetap kompatibel dengan response batch lama',
    () async {
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

      final response = await service.getQuotesResult(<String>['BBCA']);

      expect(response.quotes['BBCA.JK']?.price, 9050);
      expect(response.quotes['BBCA.JK']?.displaySymbol, '');
    },
  );
}
