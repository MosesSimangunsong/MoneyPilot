import 'dart:io';

import 'package:app/data/models/category.dart';
import 'package:app/data/models/dividend.dart';
import 'package:app/data/models/money_transaction.dart';
import 'package:app/data/models/stock_transaction.dart';
import 'package:app/data/models/watchlist_item.dart';
import 'package:app/data/services/csv_export_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel pathProviderChannel = MethodChannel(
    'plugins.flutter.io/path_provider',
  );

  late Directory tempDirectory;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp(
      'money_pilot_csv_export_test_',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, (
          MethodCall methodCall,
        ) async {
          if (methodCall.method == 'getApplicationSupportDirectory') {
            return tempDirectory.path;
          }
          return null;
        });
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);
    if (tempDirectory.existsSync()) {
      tempDirectory.deleteSync(recursive: true);
    }
  });

  test('CsvExportService membuat file csv utama', () async {
    final CsvExportService service = const CsvExportService();

    final CsvExportResult result = await service.exportAll(
      transactions: <MoneyTransaction>[
        MoneyTransaction(
          uuid: 'trx-1',
          type: 'expense',
          title: 'Makan',
          amount: 20000,
          categoryUuid: 'cat-1',
          categoryNameSnapshot: 'Makanan',
          source: 'manual',
          transactionDate: DateTime.utc(2026, 7, 10),
          createdAt: DateTime.utc(2026, 7, 10),
          updatedAt: DateTime.utc(2026, 7, 10),
        ),
      ],
      categories: <Category>[
        Category(
          id: Isar.autoIncrement,
          uuid: 'cat-1',
          name: 'Makanan',
          type: 'expense',
          iconName: 'utensils',
          colorHex: '#2563EB',
          createdAt: DateTime.utc(2026, 7, 10),
          updatedAt: DateTime.utc(2026, 7, 10),
        ),
      ],
      stockTransactions: <StockTransaction>[
        StockTransaction(
          uuid: 'stock-1',
          symbol: 'BBCA',
          actionType: 'buy',
          lot: 1,
          shares: 100,
          price: 9000,
          fee: 0,
          transactionDate: DateTime.utc(2026, 7, 10),
          createdAt: DateTime.utc(2026, 7, 10),
          updatedAt: DateTime.utc(2026, 7, 10),
        ),
      ],
      dividends: <Dividend>[
        Dividend(
          uuid: 'div-1',
          symbol: 'BBCA',
          grossAmount: 10000,
          tax: 1000,
          netAmount: 9000,
          receivedDate: DateTime.utc(2026, 7, 10),
          createdAt: DateTime.utc(2026, 7, 10),
          updatedAt: DateTime.utc(2026, 7, 10),
        ),
      ],
      watchlist: <WatchlistItem>[
        WatchlistItem(
          uuid: 'watch-1',
          symbol: 'TLKM',
          market: 'IDX',
          createdAt: DateTime.utc(2026, 7, 10),
          updatedAt: DateTime.utc(2026, 7, 10),
        ),
      ],
    );

    expect(result.filePaths, hasLength(5));
    expect(File(result.filePaths.first).existsSync(), isTrue);
    expect(
      File(result.filePaths.first).readAsStringSync(),
      contains('"trx-1"'),
    );
  });
}
