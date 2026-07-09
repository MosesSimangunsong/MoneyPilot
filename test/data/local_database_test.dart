import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:app/core/utils/date_time_utils.dart';
import 'package:app/core/utils/id_generator.dart';
import 'package:app/data/local/local_database_service.dart';
import 'package:app/data/models/watchlist_item.dart';
import 'package:app/data/repositories/category_repository.dart';
import 'package:app/data/repositories/portfolio_repository.dart';
import 'package:app/data/repositories/transaction_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDirectory;
  late LocalDatabaseService databaseService;
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
          (package) => package['name'] == 'isar_flutter_libs',
          orElse: () => throw StateError(
            'Package isar_flutter_libs tidak ditemukan di package_config.',
          ),
        );
    final String rootUri = isarFlutterLibsPackage['rootUri'] as String;
    final String libraryPath = Uri.base
        .resolve('$rootUri/windows/isar.dll')
        .toFilePath(windows: Platform.isWindows);

    if (!File(libraryPath).existsSync()) {
      throw StateError('Library Isar Windows tidak ditemukan di $libraryPath.');
    }

    await Isar.initializeIsarCore(
      libraries: <Abi, String>{Abi.current(): libraryPath},
    );
  });

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp('money_pilot_test_');
    databaseService = LocalDatabaseService();
    await databaseService.init(directoryPath: tempDirectory.path);
    categoryRepository = CategoryRepository(databaseService.isar);
    transactionRepository = TransactionRepository(databaseService.isar);
    portfolioRepository = PortfolioRepository(databaseService.isar);
  });

  tearDown(() async {
    await databaseService.close();
    if (tempDirectory.existsSync()) {
      tempDirectory.deleteSync(recursive: true);
    }
  });

  test(
    'seed kategori default tidak duplikat saat dipanggil berkali-kali',
    () async {
      await categoryRepository.seedDefaultCategoriesIfNeeded();
      await categoryRepository.seedDefaultCategoriesIfNeeded();

      final categories = await categoryRepository.getAllActiveCategories();
      expect(categories, hasLength(18));
    },
  );

  test('MoneyTransaction menyimpan categoryNameSnapshot', () async {
    await categoryRepository.seedDefaultCategoriesIfNeeded();
    final category = (await categoryRepository.getByType('expense')).first;

    final transaction = await transactionRepository.createTransaction(
      type: 'expense',
      title: 'Makan siang',
      amount: 25000,
      categoryUuid: category.uuid,
      source: 'manual',
      transactionDate: DateTime.utc(2026, 7, 9),
    );

    expect(transaction.categoryNameSnapshot, category.name);
  });

  test('soft delete category tidak menghapus transaksi lama', () async {
    await categoryRepository.seedDefaultCategoriesIfNeeded();
    final category = (await categoryRepository.getByType('expense')).first;

    final transaction = await transactionRepository.createTransaction(
      type: 'expense',
      title: 'Kopi',
      amount: 18000,
      categoryUuid: category.uuid,
      source: 'manual',
      transactionDate: DateTime.utc(2026, 7, 9),
    );

    await categoryRepository.softDeleteCategory(category.uuid);

    final savedTransaction = await transactionRepository.getByUuid(
      transaction.uuid,
    );
    final deletedCategory = await categoryRepository.getByUuid(category.uuid);

    expect(savedTransaction, isNotNull);
    expect(savedTransaction?.categoryNameSnapshot, category.name);
    expect(deletedCategory?.isDeleted, isTrue);
  });

  test('Dividend model dapat menyimpan linkedTransactionUuid', () async {
    final dividend = await portfolioRepository.createDividend(
      symbol: 'BBCA.JK',
      grossAmount: 100000,
      tax: 10000,
      netAmount: 90000,
      receivedDate: DateTime.utc(2026, 7, 9),
      linkedTransactionUuid: 'trx-123',
      note: 'Dividen tahunan',
    );

    final dividends = await portfolioRepository.getActiveDividends();
    expect(dividends.single.uuid, dividend.uuid);
    expect(dividends.single.linkedTransactionUuid, 'trx-123');
  });

  test('WatchlistItem bisa dibuat dan dibaca', () async {
    final now = DateTimeUtils.utcNow();
    final item = WatchlistItem(
      uuid: IdGenerator.newUuid(),
      symbol: 'BBRI.JK',
      companyName: 'Bank Rakyat Indonesia',
      market: 'IDX',
      targetPrice: 4500,
      note: 'Pantau area akumulasi',
      createdAt: now,
      updatedAt: now,
    );

    await portfolioRepository.upsertWatchlistItem(item);
    final watchlist = await portfolioRepository.getWatchlist();

    expect(watchlist, hasLength(1));
    expect(watchlist.single.symbol, 'BBRI.JK');
    expect(watchlist.single.targetPrice, 4500);
  });
}
