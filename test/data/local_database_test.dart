import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:app/core/utils/date_time_utils.dart';
import 'package:app/core/utils/id_generator.dart';
import 'package:app/data/local/local_database_service.dart';
import 'package:app/data/models/category.dart';
import 'package:app/data/models/money_transaction.dart';
import 'package:app/data/models/watchlist_item.dart';
import 'package:app/data/repositories/category_repository.dart';
import 'package:app/data/repositories/portfolio_repository.dart';
import 'package:app/data/repositories/transaction_repository.dart';
import 'package:app/data/repositories/voice_transcript_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDirectory;
  late LocalDatabaseService databaseService;
  late CategoryRepository categoryRepository;
  late TransactionRepository transactionRepository;
  late PortfolioRepository portfolioRepository;
  late VoiceTranscriptRepository voiceTranscriptRepository;

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
    voiceTranscriptRepository = VoiceTranscriptRepository(databaseService.isar);
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

  test('deteksi duplikasi kategori aktif berdasarkan nama dan tipe', () async {
    final DateTime now = DateTimeUtils.utcNow();
    await categoryRepository.upsertCategory(
      Category(
        uuid: 'category-expense-ngopi',
        name: 'Ngopi',
        type: 'expense',
        iconName: 'utensils',
        colorHex: '#2563EB',
        createdAt: now,
        updatedAt: now,
      ),
    );

    final bool duplicateExpense = await categoryRepository
        .hasActiveCategoryWithName('ngopi', 'expense');
    final bool duplicateIncome = await categoryRepository
        .hasActiveCategoryWithName('Ngopi', 'income');

    expect(duplicateExpense, isTrue);
    expect(duplicateIncome, isFalse);
  });

  test(
    'kategori yang sudah di-soft delete tidak dihitung sebagai duplikasi',
    () async {
      final DateTime now = DateTimeUtils.utcNow();
      final category = await categoryRepository.upsertCategory(
        Category(
          uuid: 'category-income-bonus',
          name: 'Bonus Proyek',
          type: 'income',
          iconName: 'briefcase-business',
          colorHex: '#0F766E',
          createdAt: now,
          updatedAt: now,
        ),
      );

      await categoryRepository.softDeleteCategory(category.uuid);

      final bool hasDuplicate = await categoryRepository
          .hasActiveCategoryWithName('Bonus Proyek', 'income');

      expect(hasDuplicate, isFalse);
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

  test('create transaction manual berhasil', () async {
    await categoryRepository.seedDefaultCategoriesIfNeeded();
    final category = (await categoryRepository.getByType('income')).first;

    final transaction = await transactionRepository.createTransaction(
      type: 'income',
      title: 'Honor freelance',
      amount: 500000,
      categoryUuid: category.uuid,
      paymentMethod: 'Transfer',
      note: 'Proyek landing page',
      source: 'manual',
      transactionDate: DateTime.utc(2026, 7, 1),
    );

    final saved = await transactionRepository.getByUuid(transaction.uuid);
    expect(saved, isNotNull);
    expect(saved?.title, 'Honor freelance');
    expect(saved?.syncStatus, 'pending');
    expect(saved?.paymentMethod, 'Transfer');
    expect(saved?.createdAt.isUtc, isTrue);
    expect(saved?.updatedAt.isUtc, isTrue);
    expect(saved?.transactionDate.isUtc, isTrue);
  });

  test('update transaction mengubah syncStatus menjadi pending', () async {
    await categoryRepository.seedDefaultCategoriesIfNeeded();
    final category = (await categoryRepository.getByType('expense')).first;

    final transaction = await transactionRepository.createTransaction(
      type: 'expense',
      title: 'Makan malam',
      amount: 30000,
      categoryUuid: category.uuid,
      source: 'manual',
      transactionDate: DateTime.utc(2026, 7, 2),
    );

    transaction.syncStatus = 'synced';
    await databaseService.isar.writeTxn(() async {
      await databaseService.isar.moneyTransactions.put(transaction);
    });

    final updated = await transactionRepository.updateTransaction(
      uuid: transaction.uuid,
      type: 'expense',
      title: 'Makan malam revisi',
      amount: 45000,
      categoryUuid: category.uuid,
      transactionDate: DateTime.utc(2026, 7, 2),
      paymentMethod: 'Tunai',
      note: 'Tambah minum',
    );

    expect(updated.title, 'Makan malam revisi');
    expect(updated.amount, 45000);
    expect(updated.syncStatus, 'pending');
    expect(updated.updatedAt.isUtc, isTrue);
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

  test('soft delete transaction tidak muncul di daftar aktif', () async {
    await categoryRepository.seedDefaultCategoriesIfNeeded();
    final category = (await categoryRepository.getByType('expense')).first;

    final transaction = await transactionRepository.createTransaction(
      type: 'expense',
      title: 'Transport online',
      amount: 22000,
      categoryUuid: category.uuid,
      source: 'manual',
      transactionDate: DateTime.utc(2026, 7, 3),
    );

    await transactionRepository.softDeleteTransaction(transaction.uuid);

    final activeTransactions = await transactionRepository
        .getActiveTransactions();
    final deleted = await transactionRepository.getByUuid(transaction.uuid);

    expect(activeTransactions, isEmpty);
    expect(deleted?.isDeleted, isTrue);
    expect(deleted?.deletedAt, isNotNull);
    expect(deleted?.syncStatus, 'pending');
  });

  test('getTransactionsByMonth mengembalikan data sesuai bulan', () async {
    await categoryRepository.seedDefaultCategoriesIfNeeded();
    final expenseCategory = (await categoryRepository.getByType(
      'expense',
    )).first;

    await transactionRepository.createTransaction(
      type: 'expense',
      title: 'Belanja Juli',
      amount: 90000,
      categoryUuid: expenseCategory.uuid,
      source: 'manual',
      transactionDate: DateTime.utc(2026, 7, 4),
    );
    await transactionRepository.createTransaction(
      type: 'expense',
      title: 'Belanja Agustus',
      amount: 120000,
      categoryUuid: expenseCategory.uuid,
      source: 'manual',
      transactionDate: DateTime.utc(2026, 8, 1),
    );

    final julyTransactions = await transactionRepository.getTransactionsByMonth(
      DateTime.utc(2026, 7, 1),
    );

    expect(julyTransactions, hasLength(1));
    expect(julyTransactions.single.title, 'Belanja Juli');
  });

  test(
    'categoryNameSnapshot tetap sama walaupun nama kategori berubah',
    () async {
      await categoryRepository.seedDefaultCategoriesIfNeeded();
      final category = (await categoryRepository.getByType('expense')).first;
      final String originalName = category.name;

      final transaction = await transactionRepository.createTransaction(
        type: 'expense',
        title: 'Kopi pagi',
        amount: 20000,
        categoryUuid: category.uuid,
        source: 'manual',
        transactionDate: DateTime.utc(2026, 7, 5),
      );

      category.name = 'Nama kategori baru';
      await categoryRepository.upsertCategory(category);

      final savedTransaction = await transactionRepository.getByUuid(
        transaction.uuid,
      );

      expect(savedTransaction?.categoryNameSnapshot, originalName);
    },
  );

  test('perhitungan ringkasan bulanan benar', () async {
    await categoryRepository.seedDefaultCategoriesIfNeeded();
    final incomeCategory = (await categoryRepository.getByType('income')).first;
    final expenseCategory = (await categoryRepository.getByType(
      'expense',
    )).first;

    await transactionRepository.createTransaction(
      type: 'income',
      title: 'Gaji paruh waktu',
      amount: 1500000,
      categoryUuid: incomeCategory.uuid,
      source: 'manual',
      transactionDate: DateTime.utc(2026, 7, 1),
    );
    await transactionRepository.createTransaction(
      type: 'expense',
      title: 'Sewa kos',
      amount: 600000,
      categoryUuid: expenseCategory.uuid,
      source: 'manual',
      transactionDate: DateTime.utc(2026, 7, 2),
    );
    await transactionRepository.createTransaction(
      type: 'expense',
      title: 'Makan',
      amount: 120000,
      categoryUuid: expenseCategory.uuid,
      source: 'manual',
      transactionDate: DateTime.utc(2026, 7, 3),
    );
    await transactionRepository.createTransaction(
      type: 'income',
      title: 'Pemasukan Agustus',
      amount: 100000,
      categoryUuid: incomeCategory.uuid,
      source: 'manual',
      transactionDate: DateTime.utc(2026, 8, 1),
    );

    final summary = await transactionRepository.getMonthlySummary(
      DateTime.utc(2026, 7, 1),
    );

    expect(summary.incomeTotal, 1500000);
    expect(summary.expenseTotal, 720000);
    expect(summary.cashflow, 780000);
    expect(summary.transactionCount, 3);
    expect(summary.recentTransactions, hasLength(3));
    expect(summary.recentTransactions.first.title, 'Makan');
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
    expect(watchlist.single.symbol, 'BBRI');
    expect(watchlist.single.targetPrice, 4500);
    expect(watchlist.single.syncStatus, 'pending');
  });

  test(
    'VoiceTranscript bisa disimpan dan ditandai menjadi transaksi',
    () async {
      final transcript = await voiceTranscriptRepository.createTranscript(
        rawText: 'Saya beli kopi 15 ribu',
        parsedType: 'expense',
        parsedAmount: 15000,
        parsedCategoryUuid: 'expense-food',
        confidenceScore: 0.9,
      );

      await voiceTranscriptRepository.markConverted(
        transcriptUuid: transcript.uuid,
        transactionUuid: 'trx-voice-1',
      );

      final saved = await voiceTranscriptRepository.getByUuid(transcript.uuid);
      expect(saved, isNotNull);
      expect(saved?.convertedToTransaction, isTrue);
      expect(saved?.transactionUuid, 'trx-voice-1');
      expect(saved?.createdAt.isUtc, isTrue);
    },
  );

  test(
    'transaksi voice yang dikonfirmasi tersimpan ke repository existing dan memengaruhi summary',
    () async {
      await categoryRepository.seedDefaultCategoriesIfNeeded();
      final Category category = (await categoryRepository.getByType(
        'expense',
      )).firstWhere((Category item) => item.name == 'Makanan & Minuman');

      final transcript = await voiceTranscriptRepository.createTranscript(
        rawText: 'Beli nasi goreng dua puluh lima ribu hari ini',
        parsedType: 'expense',
        parsedAmount: 25000,
        parsedCategoryUuid: category.uuid,
        confidenceScore: 90,
      );

      final MoneyTransaction transaction = await transactionRepository
          .createTransaction(
            type: 'expense',
            title: 'Beli Nasi Goreng',
            amount: 25000,
            categoryUuid: category.uuid,
            source: 'voice',
            transactionDate: DateTime.utc(2026, 7, 11),
          );

      await voiceTranscriptRepository.markConverted(
        transcriptUuid: transcript.uuid,
        transactionUuid: transaction.uuid,
      );

      final MoneyTransaction? savedTransaction = await transactionRepository
          .getByUuid(transaction.uuid);
      final MonthlyTransactionSummary summary = await transactionRepository
          .getMonthlySummary(DateTime.utc(2026, 7, 1));
      final savedTranscript = await voiceTranscriptRepository.getByUuid(
        transcript.uuid,
      );

      expect(savedTransaction, isNotNull);
      expect(savedTransaction?.source, 'voice');
      expect(savedTransaction?.uuid, isNotEmpty);
      expect(savedTransaction?.syncStatus, 'pending');
      expect(summary.expenseTotal, 25000);
      expect(summary.transactionCount, 1);
      expect(savedTranscript?.convertedToTransaction, isTrue);
      expect(savedTranscript?.transactionUuid, transaction.uuid);
    },
  );
}
