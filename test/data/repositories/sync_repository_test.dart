import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:app/core/utils/date_time_utils.dart';
import 'package:app/data/local/local_database_service.dart';
import 'package:app/data/models/category.dart';
import 'package:app/data/models/dividend.dart';
import 'package:app/data/models/money_transaction.dart';
import 'package:app/data/models/stock_transaction.dart';
import 'package:app/data/repositories/app_setting_repository.dart';
import 'package:app/data/repositories/category_repository.dart';
import 'package:app/data/repositories/portfolio_repository.dart';
import 'package:app/data/repositories/sync_repository.dart';
import 'package:app/data/repositories/transaction_repository.dart';
import 'package:app/data/services/spreadsheet_sync_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDirectory;
  late LocalDatabaseService databaseService;
  late AppSettingRepository appSettingRepository;
  late CategoryRepository categoryRepository;
  late PortfolioRepository portfolioRepository;
  late TransactionRepository transactionRepository;

  setUpAll(() async {
    final File packageConfigFile = File('.dart_tool/package_config.json');
    final Map<String, dynamic> packageConfig =
        jsonDecode(await packageConfigFile.readAsString())
            as Map<String, dynamic>;
    final List<dynamic> packages =
        packageConfig['packages'] as List<dynamic>? ?? <dynamic>[];
    final Map<String, dynamic> isarFlutterLibsPackage = packages
        .cast<Map<String, dynamic>>()
        .firstWhere(
          (Map<String, dynamic> package) =>
              package['name'] == 'isar_flutter_libs',
          orElse: () => throw StateError(
            'Package isar_flutter_libs tidak ditemukan di package_config.',
          ),
        );
    final String rootUri = isarFlutterLibsPackage['rootUri'] as String;
    final String libraryPath = Uri.base
        .resolve('$rootUri/windows/isar.dll')
        .toFilePath(windows: Platform.isWindows);

    await Isar.initializeIsarCore(
      libraries: <Abi, String>{Abi.current(): libraryPath},
    );
  });

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp(
      'money_pilot_sync_test_',
    );
    databaseService = LocalDatabaseService();
    await databaseService.init(directoryPath: tempDirectory.path);
    appSettingRepository = AppSettingRepository(databaseService.isar);
    categoryRepository = CategoryRepository(databaseService.isar);
    portfolioRepository = PortfolioRepository(databaseService.isar);
    transactionRepository = TransactionRepository(databaseService.isar);

    await appSettingRepository.updateSpreadsheetConfig(
      gasWebhookUrl: 'https://script.google.com/macros/s/test/exec',
      gasSecretToken: 'secret',
    );
    await categoryRepository.seedDefaultCategoriesIfNeeded();
  });

  tearDown(() async {
    await databaseService.close();
    if (tempDirectory.existsSync()) {
      tempDirectory.deleteSync(recursive: true);
    }
  });

  test('successful push membuat syncStatus menjadi synced', () async {
    final Category category = (await categoryRepository.getByType(
      'expense',
    )).first;
    final MoneyTransaction transaction = await transactionRepository
        .createTransaction(
          type: 'expense',
          title: 'Beli kopi',
          amount: 15000,
          categoryUuid: category.uuid,
          source: 'manual',
          transactionDate: DateTime.utc(2026, 7, 9, 3),
        );

    final SyncRepository repository = SyncRepository(
      databaseService.isar,
      appSettingRepository: appSettingRepository,
      spreadsheetSyncService: _FakeSpreadsheetSyncService(
        pushResponse: const SpreadsheetSyncResponse(
          status: 'success',
          inserted: 1,
          updated: 0,
          failed: 0,
          serverTime: null,
          message: null,
          code: null,
          items: <Map<String, dynamic>>[],
        ),
        pullCategoryItems: const <Map<String, dynamic>>[],
        pullTransactionItems: const <Map<String, dynamic>>[],
      ),
    );

    final SyncRunSummary summary = await repository.syncNow();
    final MoneyTransaction? saved = await transactionRepository.getByUuid(
      transaction.uuid,
    );

    expect(summary.status, 'success');
    expect(saved?.syncStatus, 'synced');
    expect(saved?.syncErrorMessage, isNull);
    expect(summary.pushedStockTransactions, 0);
    expect(summary.pushedDividends, 0);
  });

  test('stock transactions dan dividends ikut tersinkron saat push', () async {
    final StockTransaction stockTransaction = await portfolioRepository
        .createStockTransaction(
          symbol: 'BBCA',
          companyName: 'Bank Central Asia',
          actionType: 'buy',
          lot: 1,
          shares: 100,
          price: 9000,
          fee: 1000,
          transactionDate: DateTime.utc(2026, 7, 9, 3),
          note: 'Beli awal',
        );
    final dividendResult = await portfolioRepository
        .createDividendWithIncomeTransaction(
          symbol: 'BBCA',
          companyName: 'Bank Central Asia',
          grossAmount: 55000,
          tax: 5000,
          netAmount: 50000,
          receivedDate: DateTime.utc(2026, 7, 9, 4),
          note: 'Dividen interim',
        );

    final List<String> pushedEntities = <String>[];
    final SyncRepository repository = SyncRepository(
      databaseService.isar,
      appSettingRepository: appSettingRepository,
      spreadsheetSyncService: _FakeSpreadsheetSyncService(
        onPush:
            ({
              required String entity,
              required List<Map<String, dynamic>> items,
            }) {
              pushedEntities.add(entity);
            },
        pushResponse: const SpreadsheetSyncResponse(
          status: 'success',
          inserted: 1,
          updated: 0,
          failed: 0,
          serverTime: null,
          message: null,
          code: null,
          items: <Map<String, dynamic>>[],
        ),
        pullCategoryItems: const <Map<String, dynamic>>[],
        pullTransactionItems: const <Map<String, dynamic>>[],
        pullStockTransactionItems: const <Map<String, dynamic>>[],
        pullDividendItems: const <Map<String, dynamic>>[],
      ),
    );

    final SyncRunSummary summary = await repository.syncNow();
    final StockTransaction? savedStock = await databaseService
        .isar
        .stockTransactions
        .filter()
        .uuidEqualTo(stockTransaction.uuid)
        .findFirst();
    final Dividend? savedDividend = await databaseService.isar.dividends
        .filter()
        .uuidEqualTo(dividendResult.dividend.uuid)
        .findFirst();

    expect(summary.status, 'success');
    expect(summary.pushedStockTransactions, 1);
    expect(summary.pushedDividends, 1);
    expect(pushedEntities, contains('Stock_Transactions'));
    expect(pushedEntities, contains('Dividends'));
    expect(savedStock?.syncStatus, 'synced');
    expect(savedDividend?.syncStatus, 'synced');
  });

  test('response error membuat syncStatus menjadi failed', () async {
    final Category category = (await categoryRepository.getByType(
      'expense',
    )).first;
    final MoneyTransaction transaction = await transactionRepository
        .createTransaction(
          type: 'expense',
          title: 'Transport',
          amount: 22000,
          categoryUuid: category.uuid,
          source: 'manual',
          transactionDate: DateTime.utc(2026, 7, 9, 3),
        );

    final SyncRepository repository = SyncRepository(
      databaseService.isar,
      appSettingRepository: appSettingRepository,
      spreadsheetSyncService: _FakeSpreadsheetSyncService(
        pushException: const SpreadsheetSyncException(
          message: 'Token tidak valid.',
          code: 'INVALID_TOKEN',
        ),
      ),
    );

    final SyncRunSummary summary = await repository.syncNow();
    final MoneyTransaction? saved = await transactionRepository.getByUuid(
      transaction.uuid,
    );

    expect(summary.status, 'failed');
    expect(
      summary.message,
      'Gagal pada tahap push Categories. Token tidak valid.',
    );
    expect(saved?.syncStatus, 'failed');
    expect(
      saved?.syncErrorMessage,
      'Gagal pada tahap push Categories. Token tidak valid.',
    );
  });

  test(
    'pull stock transactions dan dividends lebih baru meng-update lokal',
    () async {
      final StockTransaction stockTransaction = await portfolioRepository
          .createStockTransaction(
            symbol: 'BBCA',
            companyName: 'Nama lokal',
            actionType: 'buy',
            lot: 1,
            shares: 100,
            price: 9000,
            fee: 0,
            transactionDate: DateTime.utc(2026, 7, 9, 3),
          );
      final dividendResult = await portfolioRepository
          .createDividendWithIncomeTransaction(
            symbol: 'BBCA',
            companyName: 'Nama lokal',
            grossAmount: 50000,
            tax: 0,
            netAmount: 50000,
            receivedDate: DateTime.utc(2026, 7, 9, 3),
            note: 'Lokal',
          );

      stockTransaction.syncStatus = 'synced';
      stockTransaction.updatedAt = DateTime.utc(2026, 7, 9, 3);
      dividendResult.dividend.syncStatus = 'synced';
      dividendResult.dividend.updatedAt = DateTime.utc(2026, 7, 9, 3);
      await databaseService.isar.writeTxn(() async {
        await databaseService.isar.stockTransactions.put(stockTransaction);
        await databaseService.isar.dividends.put(dividendResult.dividend);
      });

      final SyncRepository repository = SyncRepository(
        databaseService.isar,
        appSettingRepository: appSettingRepository,
        spreadsheetSyncService: _FakeSpreadsheetSyncService(
          pullCategoryItems: const <Map<String, dynamic>>[],
          pullTransactionItems: const <Map<String, dynamic>>[],
          pullStockTransactionItems: <Map<String, dynamic>>[
            <String, dynamic>{
              'uuid': stockTransaction.uuid,
              'symbol': 'BBCA',
              'companyName': 'Nama spreadsheet',
              'actionType': 'buy',
              'lot': 2,
              'shares': 200,
              'price': 9500,
              'fee': 1500,
              'syncStatus': 'synced',
              'syncErrorMessage': '',
              'isDeleted': false,
              'transactionDate': '2026-07-09T03:00:00.000Z',
              'note': 'Update dari spreadsheet',
              'createdAt': stockTransaction.createdAt.toIso8601String(),
              'updatedAt': '2026-07-09T04:00:00.000Z',
              'deletedAt': '',
            },
          ],
          pullDividendItems: <Map<String, dynamic>>[
            <String, dynamic>{
              'uuid': dividendResult.dividend.uuid,
              'symbol': 'BBCA',
              'companyName': 'Nama spreadsheet',
              'grossAmount': 60000,
              'tax': 10000,
              'netAmount': 50000,
              'receivedDate': '2026-07-09T03:00:00.000Z',
              'linkedTransactionUuid':
                  dividendResult.dividend.linkedTransactionUuid,
              'note': 'Update dividen spreadsheet',
              'syncStatus': 'synced',
              'syncErrorMessage': '',
              'isDeleted': false,
              'createdAt': dividendResult.dividend.createdAt.toIso8601String(),
              'updatedAt': '2026-07-09T04:00:00.000Z',
              'deletedAt': '',
            },
          ],
        ),
      );

      final SyncRunSummary summary = await repository.syncNow();
      final StockTransaction? savedStock = await databaseService
          .isar
          .stockTransactions
          .filter()
          .uuidEqualTo(stockTransaction.uuid)
          .findFirst();
      final Dividend? savedDividend = await databaseService.isar.dividends
          .filter()
          .uuidEqualTo(dividendResult.dividend.uuid)
          .findFirst();

      expect(summary.pulledStockTransactions, 1);
      expect(summary.pulledDividends, 1);
      expect(savedStock?.companyName, 'Nama spreadsheet');
      expect(savedStock?.shares, 200);
      expect(savedDividend?.companyName, 'Nama spreadsheet');
      expect(savedDividend?.grossAmount, 60000);
      expect(savedDividend?.syncStatus, 'synced');
    },
  );

  test('pull data lebih baru meng-update lokal', () async {
    final Category category = (await categoryRepository.getByType(
      'expense',
    )).first;
    final MoneyTransaction transaction = await transactionRepository
        .createTransaction(
          type: 'expense',
          title: 'Judul lama',
          amount: 15000,
          categoryUuid: category.uuid,
          source: 'manual',
          transactionDate: DateTime.utc(2026, 7, 9, 3),
        );

    transaction.syncStatus = 'synced';
    transaction.updatedAt = DateTime.utc(2026, 7, 9, 3);
    await databaseService.isar.writeTxn(() async {
      await databaseService.isar.moneyTransactions.put(transaction);
    });

    final SyncRepository repository = SyncRepository(
      databaseService.isar,
      appSettingRepository: appSettingRepository,
      spreadsheetSyncService: _FakeSpreadsheetSyncService(
        pullCategoryItems: const <Map<String, dynamic>>[],
        pullTransactionItems: <Map<String, dynamic>>[
          <String, dynamic>{
            'uuid': transaction.uuid,
            'type': 'expense',
            'title': 'Judul baru dari spreadsheet',
            'amount': 18000,
            'categoryUuid': category.uuid,
            'categoryNameSnapshot': category.name,
            'paymentMethod': 'QRIS',
            'note': '',
            'source': 'manual',
            'syncStatus': 'synced',
            'syncErrorMessage': '',
            'isDeleted': false,
            'transactionDate': '2026-07-09T03:00:00.000Z',
            'createdAt': transaction.createdAt.toIso8601String(),
            'updatedAt': '2026-07-09T04:00:00.000Z',
            'deletedAt': '',
          },
        ],
      ),
    );

    await repository.syncNow();
    final MoneyTransaction? saved = await transactionRepository.getByUuid(
      transaction.uuid,
    );

    expect(saved?.title, 'Judul baru dari spreadsheet');
    expect(saved?.amount, 18000);
    expect(saved?.paymentMethod, 'QRIS');
    expect(saved?.syncStatus, 'synced');
  });

  test('pull data lebih lama tidak menimpa lokal', () async {
    final Category category = (await categoryRepository.getByType(
      'expense',
    )).first;
    final MoneyTransaction transaction = await transactionRepository
        .createTransaction(
          type: 'expense',
          title: 'Data lokal terbaru',
          amount: 50000,
          categoryUuid: category.uuid,
          source: 'manual',
          transactionDate: DateTime.utc(2026, 7, 9, 3),
        );

    transaction.syncStatus = 'synced';
    transaction.updatedAt = DateTime.utc(2026, 7, 9, 5);
    await databaseService.isar.writeTxn(() async {
      await databaseService.isar.moneyTransactions.put(transaction);
    });

    final SyncRepository repository = SyncRepository(
      databaseService.isar,
      appSettingRepository: appSettingRepository,
      spreadsheetSyncService: _FakeSpreadsheetSyncService(
        pullCategoryItems: const <Map<String, dynamic>>[],
        pullTransactionItems: <Map<String, dynamic>>[
          <String, dynamic>{
            'uuid': transaction.uuid,
            'type': 'expense',
            'title': 'Data lama spreadsheet',
            'amount': 10000,
            'categoryUuid': category.uuid,
            'categoryNameSnapshot': category.name,
            'paymentMethod': 'Tunai',
            'note': '',
            'source': 'manual',
            'syncStatus': 'synced',
            'syncErrorMessage': '',
            'isDeleted': false,
            'transactionDate': '2026-07-09T03:00:00.000Z',
            'createdAt': transaction.createdAt.toIso8601String(),
            'updatedAt': '2026-07-09T04:00:00.000Z',
            'deletedAt': '',
          },
        ],
      ),
    );

    await repository.syncNow();
    final MoneyTransaction? saved = await transactionRepository.getByUuid(
      transaction.uuid,
    );

    expect(saved?.title, 'Data lokal terbaru');
    expect(saved?.amount, 50000);
  });

  test(
    'latest updatedAt wins untuk kategori dan transaksi saat pull',
    () async {
      final Category category = (await categoryRepository.getByType(
        'expense',
      )).first;
      category.syncStatus = 'synced';
      category.updatedAt = DateTime.utc(2026, 7, 9, 5);
      await databaseService.isar.writeTxn(() async {
        await databaseService.isar.categorys.put(category);
      });

      final SyncRepository repository = SyncRepository(
        databaseService.isar,
        appSettingRepository: appSettingRepository,
        spreadsheetSyncService: _FakeSpreadsheetSyncService(
          pullCategoryItems: <Map<String, dynamic>>[
            <String, dynamic>{
              'uuid': category.uuid,
              'name': 'Nama lama spreadsheet',
              'type': category.type,
              'icon': category.iconName,
              'colorHex': category.colorHex,
              'isDefault': true,
              'syncStatus': 'synced',
              'syncErrorMessage': '',
              'isDeleted': false,
              'createdAt': category.createdAt.toIso8601String(),
              'updatedAt': '2026-07-09T04:00:00.000Z',
              'deletedAt': '',
            },
          ],
          pullTransactionItems: const <Map<String, dynamic>>[],
        ),
      );

      await repository.syncNow();
      final Category? savedCategory = await categoryRepository.getByUuid(
        category.uuid,
      );

      expect(savedCategory?.name, isNot('Nama lama spreadsheet'));
      expect(savedCategory?.updatedAt, DateTime.utc(2026, 7, 9, 5));
    },
  );
}

class _FakeSpreadsheetSyncService extends SpreadsheetSyncService {
  _FakeSpreadsheetSyncService({
    this.pushResponse = const SpreadsheetSyncResponse(
      status: 'success',
      inserted: 0,
      updated: 0,
      failed: 0,
      serverTime: null,
      message: null,
      code: null,
      items: <Map<String, dynamic>>[],
    ),
    this.pullCategoryItems = const <Map<String, dynamic>>[],
    this.pullTransactionItems = const <Map<String, dynamic>>[],
    this.pullStockTransactionItems = const <Map<String, dynamic>>[],
    this.pullDividendItems = const <Map<String, dynamic>>[],
    this.onPush,
    this.pushException,
  });

  final SpreadsheetSyncResponse pushResponse;
  final List<Map<String, dynamic>> pullCategoryItems;
  final List<Map<String, dynamic>> pullTransactionItems;
  final List<Map<String, dynamic>> pullStockTransactionItems;
  final List<Map<String, dynamic>> pullDividendItems;
  final void Function({
    required String entity,
    required List<Map<String, dynamic>> items,
  })?
  onPush;
  final SpreadsheetSyncException? pushException;

  @override
  Future<SpreadsheetSyncResponse> push({
    required String webAppUrl,
    required String token,
    required String entity,
    required List<Map<String, dynamic>> items,
  }) async {
    if (pushException != null) {
      throw pushException!;
    }
    onPush?.call(entity: entity, items: items);
    return pushResponse;
  }

  @override
  Future<SpreadsheetSyncResponse> pull({
    required String webAppUrl,
    required String token,
    required String entity,
    DateTime? since,
  }) async {
    return SpreadsheetSyncResponse(
      status: 'success',
      inserted: 0,
      updated: 0,
      failed: 0,
      serverTime: DateTimeUtils.utcNow(),
      message: null,
      code: null,
      items: switch (entity) {
        'Categories' => pullCategoryItems,
        'Transactions' => pullTransactionItems,
        'Stock_Transactions' => pullStockTransactionItems,
        'Dividends' => pullDividendItems,
        _ => const <Map<String, dynamic>>[],
      },
    );
  }
}
