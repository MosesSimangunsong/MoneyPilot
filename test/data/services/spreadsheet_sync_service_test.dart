import 'dart:convert';

import 'package:app/data/models/dividend.dart';
import 'package:app/data/models/money_transaction.dart';
import 'package:app/data/models/stock_transaction.dart';
import 'package:app/data/services/spreadsheet_sync_mapper.dart';
import 'package:app/data/services/spreadsheet_sync_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('SpreadsheetSyncMapper', () {
    test('transaction payload mengikuti kontrak spreadsheet', () {
      final MoneyTransaction transaction = MoneyTransaction(
        uuid: 'tx-001',
        type: 'expense',
        title: 'Beli kopi',
        amount: 15000,
        categoryUuid: 'cat-food',
        categoryNameSnapshot: 'Makanan & Minuman',
        paymentMethod: 'QRIS',
        note: '',
        source: 'manual',
        syncStatus: 'pending',
        syncErrorMessage: null,
        isDeleted: false,
        transactionDate: DateTime.utc(2026, 7, 9, 3),
        createdAt: DateTime.utc(2026, 7, 9, 3),
        updatedAt: DateTime.utc(2026, 7, 9, 3),
      );

      final Map<String, dynamic> payload =
          SpreadsheetSyncMapper.transactionToPayload(transaction);

      expect(payload['uuid'], 'tx-001');
      expect(payload['title'], 'Beli kopi');
      expect(payload['amount'], 15000);
      expect(payload['syncStatus'], 'pending');
      expect(payload['transactionDate'], '2026-07-09T03:00:00.000Z');
      expect(payload['deletedAt'], '');
    });

    test('stock transaction payload mengikuti kontrak spreadsheet', () {
      final StockTransaction transaction = StockTransaction(
        uuid: 'stock-001',
        symbol: 'BBCA',
        companyName: 'Bank Central Asia',
        actionType: 'buy',
        lot: 1,
        shares: 100,
        price: 9000,
        fee: 1000,
        transactionDate: DateTime.utc(2026, 7, 9, 3),
        note: 'Beli awal',
        syncStatus: 'pending',
        syncErrorMessage: null,
        isDeleted: false,
        createdAt: DateTime.utc(2026, 7, 9, 3),
        updatedAt: DateTime.utc(2026, 7, 9, 3),
      );

      final Map<String, dynamic> payload =
          SpreadsheetSyncMapper.stockTransactionToPayload(transaction);

      expect(payload['uuid'], 'stock-001');
      expect(payload['symbol'], 'BBCA');
      expect(payload['companyName'], 'Bank Central Asia');
      expect(payload['lot'], 1);
      expect(payload['shares'], 100);
      expect(payload['transactionDate'], '2026-07-09T03:00:00.000Z');
      expect(payload['deletedAt'], '');
    });

    test('dividend payload mengikuti kontrak spreadsheet', () {
      final Dividend dividend = Dividend(
        uuid: 'div-001',
        symbol: 'BBCA',
        companyName: 'Bank Central Asia',
        grossAmount: 55000,
        tax: 5000,
        netAmount: 50000,
        receivedDate: DateTime.utc(2026, 7, 9, 3),
        linkedTransactionUuid: 'tx-div-001',
        note: 'Dividen interim',
        syncStatus: 'pending',
        syncErrorMessage: null,
        isDeleted: false,
        createdAt: DateTime.utc(2026, 7, 9, 3),
        updatedAt: DateTime.utc(2026, 7, 9, 3),
      );

      final Map<String, dynamic> payload =
          SpreadsheetSyncMapper.dividendToPayload(dividend);

      expect(payload['uuid'], 'div-001');
      expect(payload['symbol'], 'BBCA');
      expect(payload['companyName'], 'Bank Central Asia');
      expect(payload['netAmount'], 50000);
      expect(payload['linkedTransactionUuid'], 'tx-div-001');
      expect(payload['receivedDate'], '2026-07-09T03:00:00.000Z');
      expect(payload['deletedAt'], '');
    });
  });

  group('SpreadsheetSyncService', () {
    test('request awal tetap POST ke url exec', () async {
      final List<String> methods = <String>[];
      final List<Uri> requestedUris = <Uri>[];

      final SpreadsheetSyncService service = SpreadsheetSyncService(
        client: MockClient((http.Request request) async {
          methods.add(request.method);
          requestedUris.add(request.url);
          return http.Response(
            jsonEncode(<String, dynamic>{
              'status': 'success',
              'inserted': 0,
              'updated': 0,
              'failed': 0,
              'serverTime': '2026-07-09T10:00:00.000Z',
              'items': <Map<String, dynamic>>[],
            }),
            200,
            headers: const <String, String>{
              'content-type': 'application/json; charset=utf-8',
            },
          );
        }),
      );

      await service.push(
        webAppUrl: 'https://script.google.com/macros/s/test/exec',
        token: 'secret',
        entity: 'Transactions',
        items: const <Map<String, dynamic>>[],
      );

      expect(methods.single, 'POST');
      expect(
        requestedUris.single.toString(),
        'https://script.google.com/macros/s/test/exec',
      );
    });

    test('redirect 302 diikuti dengan GET ke location', () async {
      final List<Uri> requestedUris = <Uri>[];
      final List<String> methods = <String>[];
      final List<String> requestBodies = <String>[];

      final SpreadsheetSyncService service = SpreadsheetSyncService(
        client: MockClient((http.Request request) async {
          requestedUris.add(request.url);
          methods.add(request.method);
          requestBodies.add(request.body);

          if (request.url.toString() ==
              'https://script.google.com/macros/s/test/exec') {
            return http.Response(
              '',
              302,
              headers: <String, String>{
                'location':
                    'https://script.googleusercontent.com/macros/echo?user_content_key=test',
                'content-type': 'text/html; charset=UTF-8',
              },
            );
          }

          return http.Response(
            jsonEncode(<String, dynamic>{
              'status': 'success',
              'inserted': 1,
              'updated': 0,
              'failed': 0,
              'serverTime': '2026-07-09T10:00:00.000Z',
              'items': <Map<String, dynamic>>[],
            }),
            200,
            headers: const <String, String>{
              'content-type': 'application/json; charset=utf-8',
            },
          );
        }),
      );

      final SpreadsheetSyncResponse response = await service.push(
        webAppUrl: 'https://script.google.com/macros/s/test/exec',
        token: 'secret',
        entity: 'Transactions',
        items: const <Map<String, dynamic>>[],
      );

      expect(response.status, 'success');
      expect(requestedUris, hasLength(2));
      expect(
        requestedUris.first.toString(),
        'https://script.google.com/macros/s/test/exec',
      );
      expect(
        requestedUris.last.toString(),
        'https://script.googleusercontent.com/macros/echo?user_content_key=test',
      );
      expect(methods, <String>['POST', 'GET']);
      expect(requestBodies.first, isNotEmpty);
      expect(requestBodies.last, isEmpty);
    });

    test('redirect 303 diikuti dengan GET ke location', () async {
      final List<String> methods = <String>[];

      final SpreadsheetSyncService service = SpreadsheetSyncService(
        client: MockClient((http.Request request) async {
          methods.add(request.method);

          if (methods.length == 1) {
            return http.Response(
              '',
              303,
              headers: <String, String>{
                'location':
                    'https://script.googleusercontent.com/macros/echo?user_content_key=test303',
                'content-type': 'text/html; charset=UTF-8',
              },
            );
          }

          return http.Response(
            jsonEncode(<String, dynamic>{
              'status': 'success',
              'inserted': 0,
              'updated': 1,
              'failed': 0,
              'serverTime': '2026-07-09T10:00:00.000Z',
              'items': <Map<String, dynamic>>[],
            }),
            200,
            headers: const <String, String>{
              'content-type': 'application/json; charset=utf-8',
            },
          );
        }),
      );

      final SpreadsheetSyncResponse response = await service.push(
        webAppUrl: 'https://script.google.com/macros/s/test/exec',
        token: 'secret',
        entity: 'Categories',
        items: const <Map<String, dynamic>>[],
      );

      expect(response.status, 'success');
      expect(methods, <String>['POST', 'GET']);
    });

    test('redirect 307 tetap preserve POST dan body', () async {
      final List<String> methods = <String>[];
      final List<String> bodies = <String>[];

      final SpreadsheetSyncService service = SpreadsheetSyncService(
        client: MockClient((http.Request request) async {
          methods.add(request.method);
          bodies.add(request.body);

          if (methods.length == 1) {
            return http.Response(
              '',
              307,
              headers: <String, String>{
                'location': '/macros/echo?step=307',
                'content-type': 'text/html; charset=UTF-8',
              },
            );
          }

          return http.Response(
            jsonEncode(<String, dynamic>{
              'status': 'success',
              'inserted': 1,
              'updated': 0,
              'failed': 0,
              'serverTime': '2026-07-09T10:00:00.000Z',
              'items': <Map<String, dynamic>>[],
            }),
            200,
            headers: const <String, String>{
              'content-type': 'application/json; charset=utf-8',
            },
          );
        }),
      );

      await service.push(
        webAppUrl: 'https://script.google.com/macros/s/test/exec',
        token: 'secret',
        entity: 'Transactions',
        items: const <Map<String, dynamic>>[],
      );

      expect(methods, <String>['POST', 'POST']);
      expect(bodies[0], bodies[1]);
    });

    test('redirect 308 tetap preserve POST dan body', () async {
      final List<String> methods = <String>[];
      final List<String> bodies = <String>[];

      final SpreadsheetSyncService service = SpreadsheetSyncService(
        client: MockClient((http.Request request) async {
          methods.add(request.method);
          bodies.add(request.body);

          if (methods.length == 1) {
            return http.Response(
              '',
              308,
              headers: <String, String>{
                'location':
                    'https://script.googleusercontent.com/macros/echo?step=308',
                'content-type': 'text/html; charset=UTF-8',
              },
            );
          }

          return http.Response(
            jsonEncode(<String, dynamic>{
              'status': 'success',
              'inserted': 1,
              'updated': 0,
              'failed': 0,
              'serverTime': '2026-07-09T10:00:00.000Z',
              'items': <Map<String, dynamic>>[],
            }),
            200,
            headers: const <String, String>{
              'content-type': 'application/json; charset=utf-8',
            },
          );
        }),
      );

      await service.push(
        webAppUrl: 'https://script.google.com/macros/s/test/exec',
        token: 'secret',
        entity: 'Transactions',
        items: const <Map<String, dynamic>>[],
      );

      expect(methods, <String>['POST', 'POST']);
      expect(bodies[0], bodies[1]);
    });

    test('pull mem-parse response JSON yang valid', () async {
      final SpreadsheetSyncService service = SpreadsheetSyncService(
        client: MockClient((http.Request request) async {
          expect(request.method, 'POST');
          final Map<String, dynamic> body =
              jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['operation'], 'pull');
          expect(body['entity'], 'Transactions');

          return http.Response(
            jsonEncode(<String, dynamic>{
              'status': 'success',
              'inserted': 0,
              'updated': 0,
              'failed': 0,
              'serverTime': '2026-07-09T10:00:00.000Z',
              'items': <Map<String, dynamic>>[
                <String, dynamic>{
                  'uuid': 'tx-001',
                  'type': 'expense',
                  'title': 'Beli kopi',
                  'amount': 15000,
                  'categoryUuid': 'cat-food',
                  'categoryNameSnapshot': 'Makanan & Minuman',
                  'paymentMethod': 'QRIS',
                  'note': '',
                  'source': 'manual',
                  'syncStatus': 'synced',
                  'syncErrorMessage': '',
                  'isDeleted': false,
                  'transactionDate': '2026-07-09T03:00:00.000Z',
                  'createdAt': '2026-07-09T03:00:00.000Z',
                  'updatedAt': '2026-07-09T03:00:00.000Z',
                  'deletedAt': '',
                },
              ],
            }),
            200,
          );
        }),
      );

      final SpreadsheetSyncResponse response = await service.pull(
        webAppUrl: 'https://script.google.com/macros/s/test/exec',
        token: 'secret',
        entity: 'Transactions',
        since: DateTime.utc(2026, 7, 9),
      );

      expect(response.status, 'success');
      expect(response.items, hasLength(1));
      expect(response.serverTime, DateTime.utc(2026, 7, 9, 10));
    });

    test('response error melempar SpreadsheetSyncException', () async {
      final SpreadsheetSyncService service = SpreadsheetSyncService(
        client: MockClient((http.Request request) async {
          return http.Response(
            jsonEncode(<String, dynamic>{
              'status': 'error',
              'message': 'Token tidak valid.',
              'code': 'INVALID_TOKEN',
            }),
            200,
          );
        }),
      );

      expect(
        () => service.push(
          webAppUrl: 'https://script.google.com/macros/s/test/exec',
          token: 'wrong',
          entity: 'Transactions',
          items: const <Map<String, dynamic>>[],
        ),
        throwsA(
          isA<SpreadsheetSyncException>().having(
            (SpreadsheetSyncException error) => error.code,
            'code',
            'INVALID_TOKEN',
          ),
        ),
      );
    });

    test('response non JSON melempar diagnostics yang aman', () async {
      final SpreadsheetSyncService service = SpreadsheetSyncService(
        client: MockClient((http.Request request) async {
          return http.Response(
            '<html><body>Service unavailable</body></html>',
            502,
            headers: <String, String>{
              'content-type': 'text/html; charset=utf-8',
            },
          );
        }),
      );

      expect(
        () => service.pull(
          webAppUrl: 'https://script.google.com/macros/s/test/exec',
          token: 'secret',
          entity: 'Transactions',
        ),
        throwsA(
          isA<SpreadsheetSyncException>()
              .having(
                (SpreadsheetSyncException error) => error.code,
                'code',
                'INVALID_RESPONSE',
              )
              .having(
                (SpreadsheetSyncException error) => error.statusCode,
                'statusCode',
                502,
              )
              .having(
                (SpreadsheetSyncException error) => error.contentType,
                'contentType',
                'text/html; charset=utf-8',
              )
              .having(
                (SpreadsheetSyncException error) => error.responseSnippet,
                'responseSnippet',
                contains('Service unavailable'),
              )
              .having(
                (SpreadsheetSyncException error) => error.message,
                'message',
                isNot(contains('secret')),
              ),
        ),
      );
    });

    test('redirect dibatasi maksimal agar tidak infinite loop', () async {
      var requestCount = 0;
      final List<String> methods = <String>[];
      final SpreadsheetSyncService service = SpreadsheetSyncService(
        client: MockClient((http.Request request) async {
          requestCount++;
          methods.add(request.method);
          return http.Response(
            '',
            302,
            headers: <String, String>{
              'location':
                  'https://script.googleusercontent.com/macros/echo?step=$requestCount',
              'content-type': 'text/html; charset=UTF-8',
            },
          );
        }),
      );

      await expectLater(
        service.push(
          webAppUrl: 'https://script.google.com/macros/s/test/exec',
          token: 'secret',
          entity: 'Categories',
          items: const <Map<String, dynamic>>[],
        ),
        throwsA(
          isA<SpreadsheetSyncException>()
              .having(
                (SpreadsheetSyncException error) => error.code,
                'code',
                'TOO_MANY_REDIRECTS',
              )
              .having(
                (SpreadsheetSyncException error) => error.message,
                'message',
                isNot(contains('secret')),
              ),
        ),
      );

      expect(requestCount, 4);
      expect(methods, <String>['POST', 'GET', 'GET', 'GET']);
    });

    test('items object kosong diperlakukan sebagai list kosong', () async {
      final SpreadsheetSyncService service = SpreadsheetSyncService(
        client: MockClient((http.Request request) async {
          return http.Response(
            jsonEncode(<String, dynamic>{
              'status': 'success',
              'inserted': 0,
              'updated': 0,
              'failed': 0,
              'serverTime': '2026-07-09T10:00:00.000Z',
              'items': <String, dynamic>{},
            }),
            200,
            headers: const <String, String>{
              'content-type': 'application/json; charset=utf-8',
            },
          );
        }),
      );

      final SpreadsheetSyncResponse response = await service.pull(
        webAppUrl: 'https://script.google.com/macros/s/test/exec',
        token: 'secret',
        entity: 'Transactions',
      );

      expect(response.items, isEmpty);
    });
  });
}
