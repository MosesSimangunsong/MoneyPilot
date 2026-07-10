import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:app/core/utils/date_time_utils.dart';
import 'package:app/data/local/local_database_service.dart';
import 'package:app/data/models/category.dart';
import 'package:app/data/models/dividend.dart';
import 'package:app/data/models/money_transaction.dart';
import 'package:app/data/models/stock_transaction.dart';
import 'package:app/data/models/watchlist_item.dart';
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
  late TransactionRepository transactionRepository;
  late PortfolioRepository portfolioRepository;

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
    transactionRepository = TransactionRepository(databaseService.isar);
    portfolioRepository = PortfolioRepository(databaseService.isar);

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

  test('push sukses membuat semua entity pending menjadi synced', () async {
    final Category expenseCategory = (await categoryRepository.getByType(
      'expense',
    )).first;
    final MoneyTransaction moneyTransaction = await transactionRepository
        .createTransaction(
          type: 'expense',
          title: 'Beli kopi',
          amount: 15000,
          categoryUuid: expenseCategory.uuid,
          source: 'manual',
          transactionDate: DateTime.utc(2026, 7, 9, 3),
        );
    final StockTransaction stockTransaction =
        await portfolioRepository.createStockTransaction(
          symbol: 'BBCA',
          actionType: 'buy',
          lot: 1,
          shares: 100,
          price: 9500,
          fee: 500,
          transactionDate: DateTime.utc(2026, 7, 9, 3),
        );
    final Dividend dividend = await portfolioRepository.createDividend(
      symbol: 'BBCA',
      grossAmount: 100000,
      tax: 10000,
      netAmount: 90000,
      receivedDate: DateTime.utc(2026, 7, 9, 3),
      linkedTransactionUuid: 'tx-income-1',
    );
    final WatchlistItem watchlist = await portfolioRepository
        .createWatchlistItem(symbol: 'bbca.jk');

    final _FakeSpreadsheetSyncService fakeService =
        _FakeSpreadsheetSyncService();
    final SyncRepository repository = SyncRepository(
      databaseService.isar,
      appSettingRepository: appSettingRepository,
      spreadsheetSyncService: fakeService,
    );

    final SyncRunSummary summary = await repository.syncAll();

    final MoneyTransaction? savedMoneyTransaction = await transactionRepository
        .getByUuid(moneyTransaction.uuid);
    final StockTransaction? savedStockTransaction = await portfolioRepository
        .getStockTransactionByUuid(stockTransaction.uuid);
    final Dividend? savedDividend = await databaseService.isar.dividends
        .filter()
        .uuidEqualTo(dividend.uuid)
        .findFirst();
    final WatchlistItem? savedWatchlist = await portfolioRepository
        .getWatchlistItemByUuid(watchlist.uuid);

    expect(summary.status, 'success');
    expect(summary.pushedTransactions, 1);
    expect(summary.pushedStockTransactions, 1);
    expect(summary.pushedDividends, 1);
    expect(summary.pushedWatchlist, 1);
    expect(savedMoneyTransaction?.syncStatus, 'synced');
    expect(savedStockTransaction?.syncStatus, 'synced');
    expect(savedDividend?.syncStatus, 'synced');
    expect(savedWatchlist?.syncStatus, 'synced');
    expect(fakeService.pushedEntities, contains(SheetEntity.transactions));
    expect(
      fakeService.pushedEntities,
      contains(SheetEntity.stockTransactions),
    );
    expect(fakeService.pushedEntities, contains(SheetEntity.dividends));
    expect(fakeService.pushedEntities, contains(SheetEntity.watchlist));
  });

  test('push gagal membuat entity investasi failed dan data lokal tetap aman', () async {
    final StockTransaction stockTransaction =
        await portfolioRepository.createStockTransaction(
          symbol: 'TLKM',
          actionType: 'buy',
          lot: 1,
          shares: 100,
          price: 3000,
          fee: 0,
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

    final SyncRunSummary summary = await repository.syncAll();
    final StockTransaction? saved = await portfolioRepository
        .getStockTransactionByUuid(stockTransaction.uuid);

    expect(summary.status, 'failed');
    expect(saved, isNotNull);
    expect(saved?.symbol, 'TLKM');
    expect(saved?.syncStatus, 'failed');
    expect(saved?.syncErrorMessage, contains('Token tidak valid.'));
  });

  test('pull stock transaction remote lebih baru meng-update local', () async {
    final StockTransaction transaction =
        await portfolioRepository.createStockTransaction(
          symbol: 'BBCA',
          actionType: 'buy',
          lot: 1,
          shares: 100,
          price: 9000,
          fee: 0,
          transactionDate: DateTime.utc(2026, 7, 9, 3),
        );

    transaction.syncStatus = 'synced';
    transaction.updatedAt = DateTime.utc(2026, 7, 9, 3);
    await databaseService.isar.writeTxn(() async {
      await databaseService.isar.stockTransactions.put(transaction);
    });

    final SyncRepository repository = SyncRepository(
      databaseService.isar,
      appSettingRepository: appSettingRepository,
      spreadsheetSyncService: _FakeSpreadsheetSyncService(
        pullStockTransactionItems: <Map<String, dynamic>>[
          <String, dynamic>{
            'uuid': transaction.uuid,
            'symbol': 'BBCA',
            'companyName': 'Bank Central Asia',
            'actionType': 'buy',
            'lot': 2,
            'shares': 200,
            'price': 9100,
            'fee': 1000,
            'transactionDate': '2026-07-09T03:00:00.000Z',
            'note': 'Remote update',
            'syncStatus': 'synced',
            'syncErrorMessage': '',
            'isDeleted': false,
            'createdAt': transaction.createdAt.toIso8601String(),
            'updatedAt': '2026-07-09T04:00:00.000Z',
            'deletedAt': '',
          },
        ],
      ),
    );

    await repository.syncAll();
    final StockTransaction? saved = await portfolioRepository
        .getStockTransactionByUuid(transaction.uuid);

    expect(saved?.shares, 200);
    expect(saved?.price, 9100);
    expect(saved?.note, 'Remote update');
  });

  test('pull stock transaction tidak duplikat jika uuid sudah ada', () async {
    final StockTransaction transaction =
        await portfolioRepository.createStockTransaction(
          symbol: 'ASII',
          actionType: 'buy',
          lot: 1,
          shares: 100,
          price: 5000,
          fee: 0,
          transactionDate: DateTime.utc(2026, 7, 9, 3),
        );

    final SyncRepository repository = SyncRepository(
      databaseService.isar,
      appSettingRepository: appSettingRepository,
      spreadsheetSyncService: _FakeSpreadsheetSyncService(
        pullStockTransactionItems: <Map<String, dynamic>>[
          <String, dynamic>{
            'uuid': transaction.uuid,
            'symbol': 'ASII',
            'companyName': '',
            'actionType': 'buy',
            'lot': 1,
            'shares': 100,
            'price': 5000,
            'fee': 0,
            'transactionDate': '2026-07-09T03:00:00.000Z',
            'note': '',
            'syncStatus': 'synced',
            'syncErrorMessage': '',
            'isDeleted': false,
            'createdAt': transaction.createdAt.toIso8601String(),
            'updatedAt': transaction.updatedAt.toIso8601String(),
            'deletedAt': '',
          },
        ],
      ),
    );

    await repository.syncAll();
    final List<StockTransaction> allItems = await databaseService
        .isar
        .stockTransactions
        .where()
        .findAll();

    expect(allItems, hasLength(1));
  });

  test('soft delete stock transaction dari pull tersync', () async {
    final StockTransaction transaction =
        await portfolioRepository.createStockTransaction(
          symbol: 'UNVR',
          actionType: 'buy',
          lot: 1,
          shares: 100,
          price: 4000,
          fee: 0,
          transactionDate: DateTime.utc(2026, 7, 9, 3),
        );

    transaction.syncStatus = 'synced';
    transaction.updatedAt = DateTime.utc(2026, 7, 9, 3);
    await databaseService.isar.writeTxn(() async {
      await databaseService.isar.stockTransactions.put(transaction);
    });

    final SyncRepository repository = SyncRepository(
      databaseService.isar,
      appSettingRepository: appSettingRepository,
      spreadsheetSyncService: _FakeSpreadsheetSyncService(
        pullStockTransactionItems: <Map<String, dynamic>>[
          <String, dynamic>{
            'uuid': transaction.uuid,
            'symbol': 'UNVR',
            'companyName': '',
            'actionType': 'buy',
            'lot': 1,
            'shares': 100,
            'price': 4000,
            'fee': 0,
            'transactionDate': '2026-07-09T03:00:00.000Z',
            'note': '',
            'syncStatus': 'synced',
            'syncErrorMessage': '',
            'isDeleted': true,
            'createdAt': transaction.createdAt.toIso8601String(),
            'updatedAt': '2026-07-09T04:00:00.000Z',
            'deletedAt': '2026-07-09T04:00:00.000Z',
          },
        ],
      ),
    );

    await repository.syncAll();
    final StockTransaction? saved = await portfolioRepository
        .getStockTransactionByUuid(transaction.uuid);

    expect(saved?.isDeleted, true);
    expect(
      saved?.deletedAt?.toUtc(),
      DateTime.utc(2026, 7, 9, 4),
    );
  });

  test('pull dividend tidak membuat duplicate money transaction', () async {
    final DividendWithIncomeResult result = await portfolioRepository
        .createDividendWithIncomeTransaction(
          symbol: 'BBCA',
          netAmount: 90000,
          grossAmount: 100000,
          tax: 10000,
          receivedDate: DateTime.utc(2026, 7, 9, 3),
        );
    result.dividend.syncStatus = 'synced';
    await databaseService.isar.writeTxn(() async {
      await databaseService.isar.dividends.put(result.dividend);
    });

    final SyncRepository repository = SyncRepository(
      databaseService.isar,
      appSettingRepository: appSettingRepository,
      spreadsheetSyncService: _FakeSpreadsheetSyncService(
        pullDividendItems: <Map<String, dynamic>>[
          <String, dynamic>{
            'uuid': result.dividend.uuid,
            'symbol': 'BBCA',
            'companyName': 'Bank Central Asia',
            'grossAmount': 100000,
            'tax': 10000,
            'netAmount': 90000,
            'receivedDate': '2026-07-09T03:00:00.000Z',
            'linkedTransactionUuid': result.incomeTransaction.uuid,
            'note': '',
            'syncStatus': 'synced',
            'syncErrorMessage': '',
            'isDeleted': false,
            'createdAt': result.dividend.createdAt.toIso8601String(),
            'updatedAt': '2026-07-09T04:00:00.000Z',
            'deletedAt': '',
          },
        ],
      ),
    );

    await repository.syncAll();

    final List<MoneyTransaction> incomeTransactions = await databaseService
        .isar
        .moneyTransactions
        .filter()
        .sourceEqualTo('portfolio_dividend')
        .findAll();
    final List<Dividend> dividends = await databaseService.isar.dividends
        .where()
        .findAll();

    expect(incomeTransactions, hasLength(1));
    expect(dividends, hasLength(1));
    expect(dividends.single.linkedTransactionUuid, result.incomeTransaction.uuid);
  });

  test('pull watchlist menormalkan symbol dan tidak duplikat', () async {
    final WatchlistItem local = await portfolioRepository.createWatchlistItem(
      symbol: 'BBCA',
      companyName: 'Bank Central Asia',
      market: 'IDX',
    );
    local.syncStatus = 'synced';
    local.updatedAt = DateTime.utc(2026, 7, 9, 3);
    await databaseService.isar.writeTxn(() async {
      await databaseService.isar.watchlistItems.put(local);
    });

    final SyncRepository repository = SyncRepository(
      databaseService.isar,
      appSettingRepository: appSettingRepository,
      spreadsheetSyncService: _FakeSpreadsheetSyncService(
        pullWatchlistItems: <Map<String, dynamic>>[
          <String, dynamic>{
            'uuid': 'watch-remote-1',
            'symbol': 'BBCA.JK',
            'companyName': 'Bank Central Asia Tbk',
            'market': 'IDX',
            'targetPrice': 10000,
            'note': 'Remote',
            'syncStatus': 'synced',
            'syncErrorMessage': '',
            'isDeleted': false,
            'createdAt': local.createdAt.toIso8601String(),
            'updatedAt': '2026-07-09T04:00:00.000Z',
            'deletedAt': '',
          },
        ],
      ),
    );

    await repository.syncAll();
    final List<WatchlistItem> items = await databaseService
        .isar
        .watchlistItems
        .where()
        .findAll();

    expect(items, hasLength(1));
    expect(items.single.symbol, 'BBCA');
    expect(items.single.uuid, 'watch-remote-1');
    expect(items.single.companyName, 'Bank Central Asia Tbk');
  });

  test('latest updatedAt wins untuk watchlist saat remote lebih lama', () async {
    final WatchlistItem local = await portfolioRepository.createWatchlistItem(
      symbol: 'TLKM',
      note: 'Lokal terbaru',
    );
    local.syncStatus = 'synced';
    local.updatedAt = DateTime.utc(2026, 7, 9, 5);
    await databaseService.isar.writeTxn(() async {
      await databaseService.isar.watchlistItems.put(local);
    });

    final SyncRepository repository = SyncRepository(
      databaseService.isar,
      appSettingRepository: appSettingRepository,
      spreadsheetSyncService: _FakeSpreadsheetSyncService(
        pullWatchlistItems: <Map<String, dynamic>>[
          <String, dynamic>{
            'uuid': local.uuid,
            'symbol': 'TLKM',
            'companyName': '',
            'market': 'IDX',
            'targetPrice': 3500,
            'note': 'Remote lama',
            'syncStatus': 'synced',
            'syncErrorMessage': '',
            'isDeleted': false,
            'createdAt': local.createdAt.toIso8601String(),
            'updatedAt': '2026-07-09T04:00:00.000Z',
            'deletedAt': '',
          },
        ],
      ),
    );

    await repository.syncAll();
    final WatchlistItem? saved = await portfolioRepository.getWatchlistItemByUuid(
      local.uuid,
    );

    expect(saved?.note, 'Lokal terbaru');
    expect(saved?.targetPrice, isNull);
  });
}

class SheetEntity {
  static const String categories = 'Categories';
  static const String transactions = 'Transactions';
  static const String stockTransactions = 'Stock_Transactions';
  static const String dividends = 'Dividends';
  static const String watchlist = 'Watchlist';
}

class _FakeSpreadsheetSyncService extends SpreadsheetSyncService {
  _FakeSpreadsheetSyncService({
    this.pushException,
    this.pullStockTransactionItems = const <Map<String, dynamic>>[],
    this.pullDividendItems = const <Map<String, dynamic>>[],
    this.pullWatchlistItems = const <Map<String, dynamic>>[],
  });

  final SpreadsheetSyncException? pushException;
  final List<Map<String, dynamic>> pullStockTransactionItems;
  final List<Map<String, dynamic>> pullDividendItems;
  final List<Map<String, dynamic>> pullWatchlistItems;
  final List<String> pushedEntities = <String>[];

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
    pushedEntities.add(entity);
    return const SpreadsheetSyncResponse(
      status: 'success',
      inserted: 1,
      updated: 0,
      failed: 0,
      serverTime: null,
      message: null,
      code: null,
      items: <Map<String, dynamic>>[],
    );
  }

  @override
  Future<SpreadsheetSyncResponse> pull({
    required String webAppUrl,
    required String token,
    required String entity,
    String? since,
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
        SheetEntity.stockTransactions => pullStockTransactionItems,
        SheetEntity.dividends => pullDividendItems,
        SheetEntity.watchlist => pullWatchlistItems,
        _ => const <Map<String, dynamic>>[],
      },
    );
  }
}
