import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:app/data/local/local_database_service.dart';
import 'package:app/data/repositories/category_repository.dart';
import 'package:app/data/repositories/local_data_maintenance_repository.dart';
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
  late LocalDataMaintenanceRepository maintenanceRepository;

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
      'money_pilot_maintenance_test_',
    );
    databaseService = LocalDatabaseService();
    await databaseService.init(directoryPath: tempDirectory.path);
    categoryRepository = CategoryRepository(databaseService.isar);
    await categoryRepository.seedDefaultCategoriesIfNeeded();
    transactionRepository = TransactionRepository(databaseService.isar);
    portfolioRepository = PortfolioRepository(databaseService.isar);
    maintenanceRepository = LocalDataMaintenanceRepository(
      databaseService.isar,
    );
  });

  tearDown(() async {
    await databaseService.close();
    if (tempDirectory.existsSync()) {
      tempDirectory.deleteSync(recursive: true);
    }
  });

  test(
    'resetAllLocalData menghapus data utama dan seed ulang kategori',
    () async {
      final expenseCategory = (await categoryRepository.getByType(
        'expense',
      )).first;

      await transactionRepository.createTransaction(
        type: 'expense',
        title: 'Makan siang',
        amount: 25000,
        categoryUuid: expenseCategory.uuid,
        source: 'manual',
        transactionDate: DateTime.utc(2026, 7, 10),
      );
      await portfolioRepository.createStockTransaction(
        symbol: 'BBCA',
        actionType: 'buy',
        lot: 1,
        shares: 100,
        price: 9000,
        fee: 0,
        transactionDate: DateTime.utc(2026, 7, 10),
      );
      await portfolioRepository.createDividend(
        symbol: 'BBCA',
        grossAmount: 50000,
        tax: 5000,
        netAmount: 45000,
        receivedDate: DateTime.utc(2026, 7, 10),
      );
      await portfolioRepository.createWatchlistItem(symbol: 'TLKM');

      await maintenanceRepository.resetAllLocalData();

      final List activeTransactions = await transactionRepository
          .getActiveTransactions();
      final portfolioOverview = await portfolioRepository
          .getPortfolioOverview();
      final watchlist = await portfolioRepository.getWatchlist();
      final activeCategories = await categoryRepository
          .getAllActiveCategories();

      expect(activeTransactions, isEmpty);
      expect(portfolioOverview.positions, isEmpty);
      expect(portfolioOverview.dividends, isEmpty);
      expect(watchlist, isEmpty);
      expect(activeCategories, hasLength(18));
    },
  );
}
