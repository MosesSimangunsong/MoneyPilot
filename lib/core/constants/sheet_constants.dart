class SheetConstants {
  const SheetConstants._();

  static const String categories = 'Categories';
  static const String transactions = 'Transactions';
  static const String stockTransactions = 'Stock_Transactions';
  static const String dividends = 'Dividends';
  static const String watchlist = 'Watchlist';
  static const String syncMetadata = 'Sync_Metadata';
  static const String syncLog = 'Sync_Log';

  static const List<String> categoryHeaders = <String>[
    'uuid',
    'name',
    'type',
    'icon',
    'colorHex',
    'isDefault',
    'syncStatus',
    'syncErrorMessage',
    'isDeleted',
    'createdAt',
    'updatedAt',
    'deletedAt',
  ];

  static const List<String> transactionHeaders = <String>[
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
    'syncErrorMessage',
    'isDeleted',
    'transactionDate',
    'createdAt',
    'updatedAt',
    'deletedAt',
  ];

  static const List<String> stockTransactionHeaders = <String>[
    'uuid',
    'symbol',
    'companyName',
    'actionType',
    'lot',
    'shares',
    'price',
    'fee',
    'syncStatus',
    'syncErrorMessage',
    'isDeleted',
    'transactionDate',
    'note',
    'createdAt',
    'updatedAt',
    'deletedAt',
  ];

  static const List<String> dividendHeaders = <String>[
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
    'syncErrorMessage',
    'isDeleted',
    'createdAt',
    'updatedAt',
    'deletedAt',
  ];

  static const List<String> watchlistHeaders = <String>[
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
  ];

  static const Map<String, String> entityToSheetName = <String, String>{
    categories: categories,
    transactions: transactions,
    stockTransactions: stockTransactions,
    dividends: dividends,
    watchlist: watchlist,
  };

  static const Map<String, List<String>> entityToHeaders =
      <String, List<String>>{
        categories: categoryHeaders,
        transactions: transactionHeaders,
        stockTransactions: stockTransactionHeaders,
        dividends: dividendHeaders,
        watchlist: watchlistHeaders,
      };

  static const List<String> activeSyncEntities = <String>[
    categories,
    transactions,
  ];

  static List<String> headersForEntity(String entity) {
    return entityToHeaders[entity] ?? const <String>[];
  }
}
