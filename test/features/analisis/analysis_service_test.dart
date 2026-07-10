import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:app/core/utils/market_symbol_utils.dart';
import 'package:app/data/local/local_database_service.dart';
import 'package:app/data/repositories/category_repository.dart';
import 'package:app/data/repositories/news_repository.dart';
import 'package:app/data/repositories/portfolio_repository.dart';
import 'package:app/data/services/market_data_api_service.dart';
import 'package:app/data/services/news_api_service.dart';
import 'package:app/features/analisis/analysis_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:isar/isar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDirectory;
  late LocalDatabaseService databaseService;
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
      'money_pilot_analysis_test_',
    );
    databaseService = LocalDatabaseService();
    await databaseService.init(directoryPath: tempDirectory.path);
    await CategoryRepository(
      databaseService.isar,
    ).seedDefaultCategoriesIfNeeded();
    portfolioRepository = PortfolioRepository(databaseService.isar);
  });

  tearDown(() async {
    await databaseService.close();
    if (tempDirectory.existsSync()) {
      tempDirectory.deleteSync(recursive: true);
    }
  });

  test('mergeTrackedSymbols menggabungkan symbol tanpa duplikat', () async {
    await portfolioRepository.createStockTransaction(
      symbol: 'BBCA',
      actionType: 'buy',
      lot: 1,
      shares: 100,
      price: 9000,
      fee: 0,
      transactionDate: DateTime.utc(2026, 7, 10),
    );
    await portfolioRepository.createWatchlistItem(symbol: 'bbca');
    await portfolioRepository.createWatchlistItem(symbol: 'TLKM');

    final overview = await portfolioRepository.getPortfolioOverview();
    final watchlist = await portfolioRepository.getWatchlist();
    final List<String> result = AnalysisService.mergeTrackedSymbols(
      overview.positions,
      watchlist,
    );

    expect(result, <String>['BBCA', 'TLKM']);
  });

  test('normalizeSymbolForBackend mengubah BBCA menjadi BBCA.JK', () {
    expect(normalizeMarketSymbolForBackend('BBCA'), 'BBCA.JK');
    expect(normalizeMarketSymbolForBackend('AAPL', market: 'US'), 'AAPL');
  });

  test('loadDashboard tetap berjalan saat backend gagal', () async {
    await portfolioRepository.createWatchlistItem(symbol: 'BBCA');
    final AnalysisService service = AnalysisService(
      portfolioRepository: portfolioRepository,
      marketDataApiService: MarketDataApiService(
        client: MockClient((http.Request request) async {
          throw const SocketException('no network');
        }),
        baseUrl: 'http://localhost:5000',
      ),
      newsRepository: NewsRepository(
        NewsApiService(
          client: MockClient((http.Request request) async {
            throw const SocketException('no network');
          }),
          baseUrl: 'http://localhost:5000',
        ),
      ),
    );

    final AnalysisDashboardData data = await service.loadDashboard();

    expect(data.watchlist, hasLength(1));
    expect(data.backendConnected, isFalse);
    expect(data.backendStatusMessage, contains('Data lokal tetap tersedia'));
  });
}
