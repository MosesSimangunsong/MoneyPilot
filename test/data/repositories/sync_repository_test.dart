import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:app/core/utils/date_time_utils.dart';
import 'package:app/data/local/local_database_service.dart';
import 'package:app/data/models/category.dart';
import 'package:app/data/models/money_transaction.dart';
import 'package:app/data/repositories/app_setting_repository.dart';
import 'package:app/data/repositories/category_repository.dart';
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

  test('push sukses membuat transaksi pending menjadi synced', () async {
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
      spreadsheetSyncService: _FakeSpreadsheetSyncService(),
    );

    final SyncRunSummary summary = await repository.syncAll();
    final MoneyTransaction? saved = await transactionRepository.getByUuid(
      transaction.uuid,
    );

    expect(summary.status, 'success');
    expect(saved?.syncStatus, 'synced');
    expect(saved?.syncErrorMessage, isNull);
  });

  test('push gagal membuat transaksi failed dan data lokal tetap aman', () async {
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

    final SyncRunSummary summary = await repository.syncAll();
    final MoneyTransaction? saved = await transactionRepository.getByUuid(
      transaction.uuid,
    );

    expect(summary.status, 'failed');
    expect(saved, isNotNull);
    expect(saved?.title, 'Transport');
    expect(saved?.syncStatus, 'failed');
    expect(saved?.syncErrorMessage, contains('Token tidak valid.'));
  });

  test('remote lebih baru meng-update local', () async {
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

    await repository.syncAll();
    final MoneyTransaction? saved = await transactionRepository.getByUuid(
      transaction.uuid,
    );

    expect(saved?.title, 'Judul baru dari spreadsheet');
    expect(saved?.amount, 18000);
    expect(saved?.paymentMethod, 'QRIS');
  });

  test('remote lebih lama tidak menimpa local', () async {
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

    await repository.syncAll();
    final MoneyTransaction? saved = await transactionRepository.getByUuid(
      transaction.uuid,
    );

    expect(saved?.title, 'Data lokal terbaru');
    expect(saved?.amount, 50000);
  });

  test('pull insert membuat transaksi lokal baru jika uuid belum ada', () async {
    final Category category = (await categoryRepository.getByType(
      'expense',
    )).first;

    final SyncRepository repository = SyncRepository(
      databaseService.isar,
      appSettingRepository: appSettingRepository,
      spreadsheetSyncService: _FakeSpreadsheetSyncService(
        pullTransactionItems: <Map<String, dynamic>>[
          <String, dynamic>{
            'uuid': 'tx-remote-new',
            'type': 'expense',
            'title': 'Transaksi dari spreadsheet',
            'amount': 99000,
            'categoryUuid': category.uuid,
            'categoryNameSnapshot': category.name,
            'paymentMethod': 'Transfer',
            'note': 'Remote',
            'source': 'spreadsheet',
            'syncStatus': 'synced',
            'syncErrorMessage': '',
            'isDeleted': false,
            'transactionDate': '2026-07-09T03:00:00.000Z',
            'createdAt': '2026-07-09T03:00:00.000Z',
            'updatedAt': '2026-07-09T04:00:00.000Z',
            'deletedAt': '',
          },
        ],
      ),
    );

    await repository.syncAll();
    final MoneyTransaction? inserted = await transactionRepository.getByUuid(
      'tx-remote-new',
    );

    expect(inserted, isNotNull);
    expect(inserted?.title, 'Transaksi dari spreadsheet');
    expect(inserted?.syncStatus, 'synced');
  });

  test('soft delete pull menandai lokal terhapus jika remote lebih baru', () async {
    final Category category = (await categoryRepository.getByType(
      'expense',
    )).first;
    final MoneyTransaction transaction = await transactionRepository
        .createTransaction(
          type: 'expense',
          title: 'Akan dihapus',
          amount: 5000,
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
        pullTransactionItems: <Map<String, dynamic>>[
          <String, dynamic>{
            'uuid': transaction.uuid,
            'type': 'expense',
            'title': 'Akan dihapus',
            'amount': 5000,
            'categoryUuid': category.uuid,
            'categoryNameSnapshot': category.name,
            'paymentMethod': 'Tunai',
            'note': '',
            'source': 'manual',
            'syncStatus': 'synced',
            'syncErrorMessage': '',
            'isDeleted': true,
            'transactionDate': '2026-07-09T03:00:00.000Z',
            'createdAt': transaction.createdAt.toIso8601String(),
            'updatedAt': '2026-07-09T04:00:00.000Z',
            'deletedAt': '2026-07-09T04:00:00.000Z',
          },
        ],
      ),
    );

    await repository.syncAll();
    final MoneyTransaction? saved = await transactionRepository.getByUuid(
      transaction.uuid,
    );

    expect(saved?.isDeleted, true);
    expect(saved?.deletedAt, DateTime.utc(2026, 7, 9, 4));
  });
}

class _FakeSpreadsheetSyncService extends SpreadsheetSyncService {
  _FakeSpreadsheetSyncService({
    this.pushException,
    this.pullTransactionItems = const <Map<String, dynamic>>[],
  });

  final SpreadsheetSyncException? pushException;
  final List<Map<String, dynamic>> pullTransactionItems;

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
        'Categories' => const <Map<String, dynamic>>[],
        'Transactions' => pullTransactionItems,
        _ => const <Map<String, dynamic>>[],
      },
    );
  }
}
