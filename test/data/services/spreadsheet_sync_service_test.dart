import 'dart:convert';

import 'package:app/data/models/category.dart';
import 'package:app/data/models/money_transaction.dart';
import 'package:app/data/services/spreadsheet_sync_mapper.dart';
import 'package:app/data/services/spreadsheet_sync_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('SpreadsheetSyncMapper category', () {
    test('Category -> Map mempertahankan field penting', () {
      final Category category = Category(
        uuid: 'cat-food',
        name: 'Makanan & Minuman',
        type: 'expense',
        iconName: 'utensils',
        colorHex: '#2563EB',
        isDefault: true,
        isDeleted: false,
        createdAt: DateTime.utc(2026, 7, 9, 3),
        updatedAt: DateTime.utc(2026, 7, 9, 3),
      );

      final Map<String, dynamic> payload =
          SpreadsheetSyncMapper.categoryToPayload(category);

      expect(payload['uuid'], 'cat-food');
      expect(payload['isDefault'], true);
      expect(payload['isDeleted'], false);
      expect(payload['updatedAt'], '2026-07-09T03:00:00.000Z');
    });

    test('Map -> Category mempertahankan isDefault dan isDeleted', () {
      final Category category = SpreadsheetSyncMapper.categoryFromPayload(
        <String, dynamic>{
          'uuid': 'cat-food',
          'name': 'Makanan & Minuman',
          'type': 'expense',
          'icon': 'utensils',
          'colorHex': '#2563EB',
          'isDefault': true,
          'syncStatus': 'synced',
          'syncErrorMessage': '',
          'isDeleted': true,
          'createdAt': '2026-07-09T03:00:00.000Z',
          'updatedAt': '2026-07-09T04:00:00.000Z',
          'deletedAt': '2026-07-09T04:00:00.000Z',
        },
      );

      expect(category.isDefault, true);
      expect(category.isDeleted, true);
      expect(category.deletedAt, DateTime.utc(2026, 7, 9, 4));
    });
  });

  group('SpreadsheetSyncMapper transaction', () {
    test('MoneyTransaction -> Map mempertahankan snapshot dan payment method', () {
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
        isDeleted: false,
        transactionDate: DateTime.utc(2026, 7, 9, 3),
        createdAt: DateTime.utc(2026, 7, 9, 3),
        updatedAt: DateTime.utc(2026, 7, 9, 3),
      );

      final Map<String, dynamic> payload =
          SpreadsheetSyncMapper.transactionToPayload(transaction);

      expect(payload['categoryNameSnapshot'], 'Makanan & Minuman');
      expect(payload['paymentMethod'], 'QRIS');
      expect(payload['transactionDate'], '2026-07-09T03:00:00.000Z');
    });

    test('Map -> MoneyTransaction mempertahankan field penting', () {
      final MoneyTransaction transaction =
          SpreadsheetSyncMapper.transactionFromPayload(<String, dynamic>{
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
          });

      expect(transaction.amount, 15000);
      expect(transaction.categoryNameSnapshot, 'Makanan & Minuman');
      expect(transaction.paymentMethod, 'QRIS');
      expect(transaction.transactionDate, DateTime.utc(2026, 7, 9, 3));
    });
  });

  group('SpreadsheetSyncService', () {
    test('success JSON diparse dengan benar', () async {
      final SpreadsheetSyncService service = SpreadsheetSyncService(
        client: MockClient((http.Request request) async {
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
      expect(response.inserted, 1);
      expect(response.serverTime, DateTime.utc(2026, 7, 9, 10));
    });

    test('error JSON melempar SpreadsheetSyncException', () async {
      final SpreadsheetSyncService service = SpreadsheetSyncService(
        client: MockClient((http.Request request) async {
          return http.Response(
            jsonEncode(<String, dynamic>{
              'status': 'error',
              'message': 'Token tidak valid.',
              'code': 'INVALID_TOKEN',
            }),
            200,
            headers: const <String, String>{
              'content-type': 'application/json; charset=utf-8',
            },
          );
        }),
      );

      await expectLater(
        service.pull(
          webAppUrl: 'https://script.google.com/macros/s/test/exec',
          token: 'secret',
          entity: 'Transactions',
          since: '2026-07-09T00:00:00.000Z',
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

    test('invalid JSON melempar diagnostics aman', () async {
      final SpreadsheetSyncService service = SpreadsheetSyncService(
        client: MockClient((http.Request request) async {
          return http.Response(
            '<html><body>Moved Temporarily</body></html>',
            200,
            headers: const <String, String>{
              'content-type': 'text/html; charset=utf-8',
            },
          );
        }),
      );

      await expectLater(
        service.pull(
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
                (SpreadsheetSyncException error) => error.contentType,
                'contentType',
                'text/html; charset=utf-8',
              )
              .having(
                (SpreadsheetSyncException error) => error.message,
                'message',
                isNot(contains('secret')),
              ),
        ),
      );
    });

    test('network failure melempar error yang aman', () async {
      final SpreadsheetSyncService service = SpreadsheetSyncService(
        client: MockClient((http.Request request) async {
          throw http.ClientException('Koneksi gagal');
        }),
      );

      await expectLater(
        service.push(
          webAppUrl: 'https://script.google.com/macros/s/test/exec',
          token: 'secret',
          entity: 'Transactions',
          items: const <Map<String, dynamic>>[],
        ),
        throwsA(
          isA<SpreadsheetSyncException>()
              .having(
                (SpreadsheetSyncException error) => error.code,
                'code',
                'NETWORK_ERROR',
              )
              .having(
                (SpreadsheetSyncException error) => error.message,
                'message',
                isNot(contains('secret')),
              ),
        ),
      );
    });

    test('missing token divalidasi sebelum request', () async {
      final SpreadsheetSyncService service = SpreadsheetSyncService();

      expect(
        () => service.push(
          webAppUrl: 'https://script.google.com/macros/s/test/exec',
          token: '   ',
          entity: 'Transactions',
          items: const <Map<String, dynamic>>[],
        ),
        throwsA(
          isA<SpreadsheetSyncException>().having(
            (SpreadsheetSyncException error) => error.code,
            'code',
            'MISSING_TOKEN',
          ),
        ),
      );
    });
  });
}
