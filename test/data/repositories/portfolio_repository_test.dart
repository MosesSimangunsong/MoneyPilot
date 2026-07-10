import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:app/data/local/local_database_service.dart';
import 'package:app/data/models/money_transaction.dart';
import 'package:app/data/repositories/category_repository.dart';
import 'package:app/data/repositories/portfolio_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDirectory;
  late LocalDatabaseService databaseService;
  late CategoryRepository categoryRepository;
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
      'money_pilot_portfolio_test_',
    );
    databaseService = LocalDatabaseService();
    await databaseService.init(directoryPath: tempDirectory.path);
    categoryRepository = CategoryRepository(databaseService.isar);
    portfolioRepository = PortfolioRepository(databaseService.isar);
    await categoryRepository.seedDefaultCategoriesIfNeeded();
  });

  tearDown(() async {
    await databaseService.close();
    if (tempDirectory.existsSync()) {
      tempDirectory.deleteSync(recursive: true);
    }
  });

  test('average price dan total shares benar setelah dua kali beli', () async {
    await portfolioRepository.createStockTransaction(
      symbol: 'BBCA',
      companyName: 'Bank Central Asia',
      actionType: 'buy',
      lot: 1,
      shares: 100,
      price: 9000,
      fee: 1000,
      transactionDate: DateTime.utc(2026, 7, 1),
    );
    await portfolioRepository.createStockTransaction(
      symbol: 'BBCA',
      companyName: 'Bank Central Asia',
      actionType: 'buy',
      lot: 1,
      shares: 100,
      price: 10000,
      fee: 1000,
      transactionDate: DateTime.utc(2026, 7, 2),
    );

    final PortfolioOverview overview = await portfolioRepository
        .getPortfolioOverview();
    final PortfolioPositionSummary summary = overview.positions.single;

    expect(summary.symbol, 'BBCA');
    expect(summary.totalShares, 200);
    expect(summary.totalLot, 2);
    expect(summary.totalCost, 1902000);
    expect(summary.averageBuyPrice, 9510);
  });

  test('jual sebagian mengurangi posisi tanpa merusak average price', () async {
    await portfolioRepository.createStockTransaction(
      symbol: 'BBCA',
      actionType: 'buy',
      lot: 2,
      shares: 200,
      price: 9000,
      fee: 0,
      transactionDate: DateTime.utc(2026, 7, 1),
    );
    await portfolioRepository.createStockTransaction(
      symbol: 'BBCA',
      actionType: 'sell',
      lot: 1,
      shares: 100,
      price: 9500,
      fee: 500,
      transactionDate: DateTime.utc(2026, 7, 3),
    );

    final PortfolioOverview overview = await portfolioRepository
        .getPortfolioOverview();
    final PortfolioPositionSummary summary = overview.positions.single;

    expect(summary.totalShares, 100);
    expect(summary.totalLot, 1);
    expect(summary.averageBuyPrice, 9000);
    expect(summary.totalCost, 900000);
  });

  test(
    'createDividendWithIncomeTransaction membuat dividend dan income transaction terkait',
    () async {
      final DividendWithIncomeResult result = await portfolioRepository
          .createDividendWithIncomeTransaction(
            symbol: 'BBCA',
            companyName: 'Bank Central Asia',
            grossAmount: 55000,
            tax: 5000,
            netAmount: 50000,
            receivedDate: DateTime.utc(2026, 7, 4),
            note: 'Dividen interim',
          );

      final List<MoneyTransaction> transactions = await databaseService
          .isar
          .moneyTransactions
          .filter()
          .isDeletedEqualTo(false)
          .findAll();
      final dividends = await portfolioRepository.getActiveDividends();

      expect(dividends, hasLength(1));
      expect(
        dividends.single.linkedTransactionUuid,
        result.incomeTransaction.uuid,
      );
      expect(
        result.dividend.linkedTransactionUuid,
        result.incomeTransaction.uuid,
      );
      expect(transactions, hasLength(1));
      expect(transactions.single.type, 'income');
      expect(transactions.single.source, 'portfolio_dividend');
      expect(transactions.single.categoryNameSnapshot, 'Dividen');
      expect(transactions.single.uuid, result.incomeTransaction.uuid);
    },
  );

  test(
    'soft delete transaksi saham menyembunyikan dari daftar aktif',
    () async {
      final transaction = await portfolioRepository.createStockTransaction(
        symbol: 'TLKM',
        actionType: 'buy',
        lot: 1,
        shares: 100,
        price: 3000,
        fee: 0,
        transactionDate: DateTime.utc(2026, 7, 5),
      );

      await portfolioRepository.softDeleteStockTransaction(transaction.uuid);

      final List active = await portfolioRepository
          .getActiveStockTransactions();
      final deleted = await portfolioRepository.getStockTransactionByUuid(
        transaction.uuid,
      );

      expect(active, isEmpty);
      expect(deleted?.isDeleted, isTrue);
      expect(deleted?.syncStatus, 'pending');
    },
  );

  test('timestamp transaksi saham tersimpan dalam UTC', () async {
    final transaction = await portfolioRepository.createStockTransaction(
      symbol: 'ASII',
      actionType: 'buy',
      lot: 1,
      shares: 100,
      price: 5000,
      fee: 0,
      transactionDate: DateTime(2026, 7, 6, 9, 30),
    );

    expect(transaction.createdAt.isUtc, isTrue);
    expect(transaction.updatedAt.isUtc, isTrue);
    expect(transaction.transactionDate.isUtc, isTrue);
  });

  test('watchlist bisa ditambah dan symbol dinormalisasi', () async {
    final item = await portfolioRepository.createWatchlistItem(
      symbol: 'bbca',
      companyName: 'Bank Central Asia',
      targetPrice: 10000,
      note: 'Pantau valuasi',
    );

    final List watchlist = await portfolioRepository.getWatchlist();

    expect(item.symbol, 'BBCA');
    expect(item.market, 'IDX');
    expect(item.createdAt.isUtc, isTrue);
    expect(item.updatedAt.isUtc, isTrue);
    expect(watchlist, hasLength(1));
  });

  test('watchlist bisa diedit', () async {
    final item = await portfolioRepository.createWatchlistItem(symbol: 'BBCA');

    final updated = await portfolioRepository.updateWatchlistItem(
      item.uuid,
      symbol: 'BBCA',
      targetPrice: 9800,
      note: 'Tunggu laporan kuartal',
    );

    expect(updated.targetPrice, 9800);
    expect(updated.note, 'Tunggu laporan kuartal');
    expect(updated.updatedAt.isUtc, isTrue);
  });

  test('soft delete watchlist menyembunyikan item aktif', () async {
    final item = await portfolioRepository.createWatchlistItem(symbol: 'TLKM');

    await portfolioRepository.softDeleteWatchlistItem(item.uuid);

    final List activeWatchlist = await portfolioRepository.getWatchlist();
    final deletedItem = await portfolioRepository.getWatchlistItemByUuid(
      item.uuid,
    );

    expect(activeWatchlist, isEmpty);
    expect(deletedItem?.isDeleted, isTrue);
    expect(deletedItem?.deletedAt, isNotNull);
  });

  test('watchlist deleted tidak muncul pada daftar aktif', () async {
    final item = await portfolioRepository.createWatchlistItem(symbol: 'BBCA');
    await portfolioRepository.createWatchlistItem(symbol: 'TLKM');

    await portfolioRepository.softDeleteWatchlistItem(item.uuid);
    final List activeWatchlist = await portfolioRepository.getWatchlist();

    expect(activeWatchlist, hasLength(1));
    expect(activeWatchlist.single.symbol, 'TLKM');
  });
}
