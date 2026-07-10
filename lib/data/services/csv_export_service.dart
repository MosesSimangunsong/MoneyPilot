import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../core/utils/date_time_utils.dart';
import '../models/category.dart';
import '../models/dividend.dart';
import '../models/money_transaction.dart';
import '../models/stock_transaction.dart';
import '../models/watchlist_item.dart';

class CsvExportService {
  const CsvExportService();

  Future<CsvExportResult> exportAll({
    required List<MoneyTransaction> transactions,
    required List<Category> categories,
    required List<StockTransaction> stockTransactions,
    required List<Dividend> dividends,
    required List<WatchlistItem> watchlist,
  }) async {
    final Directory baseDirectory = await getApplicationSupportDirectory();
    final Directory exportDirectory = Directory(
      '${baseDirectory.path}${Platform.pathSeparator}money_pilot_exports',
    );
    if (!await exportDirectory.exists()) {
      await exportDirectory.create(recursive: true);
    }

    final String exportStamp = DateTimeUtils.utcNow()
        .toIso8601String()
        .replaceAll(':', '-');

    final List<File> files = <File>[
      await _writeFile(
        exportDirectory,
        'transactions_$exportStamp.csv',
        _buildTransactionsCsv(transactions),
      ),
      await _writeFile(
        exportDirectory,
        'categories_$exportStamp.csv',
        _buildCategoriesCsv(categories),
      ),
      await _writeFile(
        exportDirectory,
        'stock_transactions_$exportStamp.csv',
        _buildStockTransactionsCsv(stockTransactions),
      ),
      await _writeFile(
        exportDirectory,
        'dividends_$exportStamp.csv',
        _buildDividendsCsv(dividends),
      ),
      await _writeFile(
        exportDirectory,
        'watchlist_$exportStamp.csv',
        _buildWatchlistCsv(watchlist),
      ),
    ];

    return CsvExportResult(
      directoryPath: exportDirectory.path,
      filePaths: files.map((File file) => file.path).toList(growable: false),
      exportedAt: DateTimeUtils.utcNow(),
    );
  }

  Future<File> _writeFile(
    Directory directory,
    String filename,
    String contents,
  ) async {
    final File file = File(
      '${directory.path}${Platform.pathSeparator}$filename',
    );
    return file.writeAsString(contents, flush: true);
  }

  String _buildTransactionsCsv(List<MoneyTransaction> items) {
    return _joinCsv(<List<String>>[
      <String>[
        'uuid',
        'type',
        'title',
        'amount',
        'categoryUuid',
        'categoryNameSnapshot',
        'paymentMethod',
        'note',
        'source',
        'syncStatus',
        'isDeleted',
        'transactionDate',
        'createdAt',
        'updatedAt',
        'deletedAt',
      ],
      ...items.map((MoneyTransaction item) {
        return <String>[
          item.uuid,
          item.type,
          item.title,
          '${item.amount}',
          item.categoryUuid,
          item.categoryNameSnapshot,
          item.paymentMethod,
          item.note ?? '',
          item.source,
          item.syncStatus,
          '${item.isDeleted}',
          item.transactionDate.toIso8601String(),
          item.createdAt.toIso8601String(),
          item.updatedAt.toIso8601String(),
          item.deletedAt?.toIso8601String() ?? '',
        ];
      }),
    ]);
  }

  String _buildCategoriesCsv(List<Category> items) {
    return _joinCsv(<List<String>>[
      <String>[
        'uuid',
        'name',
        'type',
        'iconName',
        'colorHex',
        'isDefault',
        'syncStatus',
        'isDeleted',
        'createdAt',
        'updatedAt',
        'deletedAt',
      ],
      ...items.map((Category item) {
        return <String>[
          item.uuid,
          item.name,
          item.type,
          item.iconName,
          item.colorHex,
          '${item.isDefault}',
          item.syncStatus,
          '${item.isDeleted}',
          item.createdAt.toIso8601String(),
          item.updatedAt.toIso8601String(),
          item.deletedAt?.toIso8601String() ?? '',
        ];
      }),
    ]);
  }

  String _buildStockTransactionsCsv(List<StockTransaction> items) {
    return _joinCsv(<List<String>>[
      <String>[
        'uuid',
        'symbol',
        'companyName',
        'actionType',
        'lot',
        'shares',
        'price',
        'fee',
        'note',
        'syncStatus',
        'isDeleted',
        'transactionDate',
        'createdAt',
        'updatedAt',
        'deletedAt',
      ],
      ...items.map((StockTransaction item) {
        return <String>[
          item.uuid,
          item.symbol,
          item.companyName ?? '',
          item.actionType,
          '${item.lot}',
          '${item.shares}',
          '${item.price}',
          '${item.fee}',
          item.note ?? '',
          item.syncStatus,
          '${item.isDeleted}',
          item.transactionDate.toIso8601String(),
          item.createdAt.toIso8601String(),
          item.updatedAt.toIso8601String(),
          item.deletedAt?.toIso8601String() ?? '',
        ];
      }),
    ]);
  }

  String _buildDividendsCsv(List<Dividend> items) {
    return _joinCsv(<List<String>>[
      <String>[
        'uuid',
        'symbol',
        'companyName',
        'grossAmount',
        'tax',
        'netAmount',
        'receivedDate',
        'linkedTransactionUuid',
        'note',
        'syncStatus',
        'isDeleted',
        'createdAt',
        'updatedAt',
        'deletedAt',
      ],
      ...items.map((Dividend item) {
        return <String>[
          item.uuid,
          item.symbol,
          item.companyName ?? '',
          '${item.grossAmount}',
          '${item.tax}',
          '${item.netAmount}',
          item.receivedDate.toIso8601String(),
          item.linkedTransactionUuid ?? '',
          item.note ?? '',
          item.syncStatus,
          '${item.isDeleted}',
          item.createdAt.toIso8601String(),
          item.updatedAt.toIso8601String(),
          item.deletedAt?.toIso8601String() ?? '',
        ];
      }),
    ]);
  }

  String _buildWatchlistCsv(List<WatchlistItem> items) {
    return _joinCsv(<List<String>>[
      <String>[
        'uuid',
        'symbol',
        'companyName',
        'market',
        'targetPrice',
        'note',
        'isDeleted',
        'createdAt',
        'updatedAt',
        'deletedAt',
      ],
      ...items.map((WatchlistItem item) {
        return <String>[
          item.uuid,
          item.symbol,
          item.companyName ?? '',
          item.market,
          item.targetPrice?.toString() ?? '',
          item.note ?? '',
          '${item.isDeleted}',
          item.createdAt.toIso8601String(),
          item.updatedAt.toIso8601String(),
          item.deletedAt?.toIso8601String() ?? '',
        ];
      }),
    ]);
  }

  String _joinCsv(List<List<String>> rows) {
    return rows
        .map((List<String> row) => row.map(_escapeCsvCell).join(','))
        .join('\n');
  }

  String _escapeCsvCell(String value) {
    final String escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }
}

class CsvExportResult {
  const CsvExportResult({
    required this.directoryPath,
    required this.filePaths,
    required this.exportedAt,
  });

  final String directoryPath;
  final List<String> filePaths;
  final DateTime exportedAt;
}
