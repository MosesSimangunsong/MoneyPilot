import '../../core/utils/date_time_utils.dart';
import '../models/category.dart';
import '../models/dividend.dart';
import '../models/money_transaction.dart';
import '../models/stock_transaction.dart';

class SpreadsheetSyncMapper {
  const SpreadsheetSyncMapper._();

  static Map<String, dynamic> categoryToPayload(Category category) {
    return <String, dynamic>{
      'uuid': category.uuid,
      'name': category.name,
      'type': category.type,
      'icon': category.iconName,
      'colorHex': category.colorHex,
      'isDefault': category.isDefault,
      'syncStatus': category.syncStatus,
      'syncErrorMessage': category.syncErrorMessage ?? '',
      'isDeleted': category.isDeleted,
      'createdAt': _toIsoString(category.createdAt),
      'updatedAt': _toIsoString(category.updatedAt),
      'deletedAt': _toNullableIsoString(category.deletedAt),
    };
  }

  static Category categoryFromPayload(Map<String, dynamic> payload) {
    return Category(
      uuid: _readString(payload, 'uuid'),
      name: _readString(payload, 'name'),
      type: _readString(payload, 'type'),
      iconName: _readString(payload, 'icon'),
      colorHex: _readString(payload, 'colorHex'),
      isDefault: _readBool(payload['isDefault']),
      syncStatus: _readStringOrFallback(payload, 'syncStatus', 'synced'),
      syncErrorMessage: _readNullableString(payload['syncErrorMessage']),
      isDeleted: _readBool(payload['isDeleted']),
      createdAt: _readDateTime(payload, 'createdAt'),
      updatedAt: _readDateTime(payload, 'updatedAt'),
      deletedAt: _readNullableDateTime(payload['deletedAt']),
    );
  }

  static Map<String, dynamic> transactionToPayload(MoneyTransaction item) {
    return <String, dynamic>{
      'uuid': item.uuid,
      'type': item.type,
      'title': item.title,
      'amount': item.amount,
      'categoryUuid': item.categoryUuid,
      'categoryNameSnapshot': item.categoryNameSnapshot,
      'paymentMethod': item.paymentMethod,
      'note': item.note ?? '',
      'source': item.source,
      'syncStatus': item.syncStatus,
      'syncErrorMessage': item.syncErrorMessage ?? '',
      'isDeleted': item.isDeleted,
      'transactionDate': _toIsoString(item.transactionDate),
      'createdAt': _toIsoString(item.createdAt),
      'updatedAt': _toIsoString(item.updatedAt),
      'deletedAt': _toNullableIsoString(item.deletedAt),
    };
  }

  static MoneyTransaction transactionFromPayload(Map<String, dynamic> payload) {
    return MoneyTransaction(
      uuid: _readString(payload, 'uuid'),
      type: _readString(payload, 'type'),
      title: _readString(payload, 'title'),
      amount: _readDouble(payload['amount']),
      categoryUuid: _readString(payload, 'categoryUuid'),
      categoryNameSnapshot: _readString(payload, 'categoryNameSnapshot'),
      paymentMethod: _readStringOrFallback(
        payload,
        'paymentMethod',
        'Tidak Dicatat',
      ),
      note: _readNullableString(payload['note']),
      source: _readString(payload, 'source'),
      syncStatus: _readStringOrFallback(payload, 'syncStatus', 'synced'),
      syncErrorMessage: _readNullableString(payload['syncErrorMessage']),
      isDeleted: _readBool(payload['isDeleted']),
      transactionDate: _readDateTime(payload, 'transactionDate'),
      createdAt: _readDateTime(payload, 'createdAt'),
      updatedAt: _readDateTime(payload, 'updatedAt'),
      deletedAt: _readNullableDateTime(payload['deletedAt']),
    );
  }

  static Map<String, dynamic> stockTransactionToPayload(StockTransaction item) {
    return <String, dynamic>{
      'uuid': item.uuid,
      'symbol': item.symbol,
      'companyName': item.companyName ?? '',
      'actionType': item.actionType,
      'lot': item.lot,
      'shares': item.shares,
      'price': item.price,
      'fee': item.fee,
      'syncStatus': item.syncStatus,
      'syncErrorMessage': item.syncErrorMessage ?? '',
      'isDeleted': item.isDeleted,
      'transactionDate': _toIsoString(item.transactionDate),
      'note': item.note ?? '',
      'createdAt': _toIsoString(item.createdAt),
      'updatedAt': _toIsoString(item.updatedAt),
      'deletedAt': _toNullableIsoString(item.deletedAt),
    };
  }

  static StockTransaction stockTransactionFromPayload(
    Map<String, dynamic> payload,
  ) {
    return StockTransaction(
      uuid: _readString(payload, 'uuid'),
      symbol: _readString(payload, 'symbol'),
      companyName: _readNullableString(payload['companyName']),
      actionType: _readString(payload, 'actionType'),
      lot: _readInt(payload['lot']),
      shares: _readInt(payload['shares']),
      price: _readDouble(payload['price']),
      fee: _readDouble(payload['fee']),
      transactionDate: _readDateTime(payload, 'transactionDate'),
      note: _readNullableString(payload['note']),
      syncStatus: _readStringOrFallback(payload, 'syncStatus', 'synced'),
      syncErrorMessage: _readNullableString(payload['syncErrorMessage']),
      isDeleted: _readBool(payload['isDeleted']),
      createdAt: _readDateTime(payload, 'createdAt'),
      updatedAt: _readDateTime(payload, 'updatedAt'),
      deletedAt: _readNullableDateTime(payload['deletedAt']),
    );
  }

  static Map<String, dynamic> dividendToPayload(Dividend item) {
    return <String, dynamic>{
      'uuid': item.uuid,
      'symbol': item.symbol,
      'companyName': item.companyName ?? '',
      'grossAmount': item.grossAmount,
      'tax': item.tax,
      'netAmount': item.netAmount,
      'receivedDate': _toIsoString(item.receivedDate),
      'linkedTransactionUuid': item.linkedTransactionUuid ?? '',
      'note': item.note ?? '',
      'syncStatus': item.syncStatus,
      'syncErrorMessage': item.syncErrorMessage ?? '',
      'isDeleted': item.isDeleted,
      'createdAt': _toIsoString(item.createdAt),
      'updatedAt': _toIsoString(item.updatedAt),
      'deletedAt': _toNullableIsoString(item.deletedAt),
    };
  }

  static Dividend dividendFromPayload(Map<String, dynamic> payload) {
    return Dividend(
      uuid: _readString(payload, 'uuid'),
      symbol: _readString(payload, 'symbol'),
      companyName: _readNullableString(payload['companyName']),
      grossAmount: _readDouble(payload['grossAmount']),
      tax: _readDouble(payload['tax']),
      netAmount: _readDouble(payload['netAmount']),
      receivedDate: _readDateTime(payload, 'receivedDate'),
      linkedTransactionUuid: _readNullableString(
        payload['linkedTransactionUuid'],
      ),
      note: _readNullableString(payload['note']),
      syncStatus: _readStringOrFallback(payload, 'syncStatus', 'synced'),
      syncErrorMessage: _readNullableString(payload['syncErrorMessage']),
      isDeleted: _readBool(payload['isDeleted']),
      createdAt: _readDateTime(payload, 'createdAt'),
      updatedAt: _readDateTime(payload, 'updatedAt'),
      deletedAt: _readNullableDateTime(payload['deletedAt']),
    );
  }

  static String _toIsoString(DateTime value) {
    return DateTimeUtils.normalizeUtc(value).toIso8601String();
  }

  static String _toNullableIsoString(DateTime? value) {
    if (value == null) {
      return '';
    }
    return _toIsoString(value);
  }

  static String _readString(Map<String, dynamic> payload, String key) {
    final String? value = _readNullableString(payload[key]);
    if (value == null) {
      throw FormatException('Field "$key" wajib diisi.');
    }
    return value;
  }

  static String _readStringOrFallback(
    Map<String, dynamic> payload,
    String key,
    String fallback,
  ) {
    final String? value = _readNullableString(payload[key]);
    return value ?? fallback;
  }

  static String? _readNullableString(dynamic value) {
    if (value == null) {
      return null;
    }
    final String normalized = value.toString().trim();
    if (normalized.isEmpty) {
      return null;
    }
    return normalized;
  }

  static bool _readBool(dynamic value) {
    if (value is bool) {
      return value;
    }
    final String normalized = value?.toString().trim().toLowerCase() ?? '';
    return normalized == 'true' || normalized == '1' || normalized == 'yes';
  }

  static double _readDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    final String normalized = value?.toString().trim() ?? '';
    final double? parsed = double.tryParse(normalized);
    if (parsed == null) {
      throw FormatException('Nilai angka tidak valid: $value');
    }
    return parsed;
  }

  static int _readInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.round();
    }
    final String normalized = value?.toString().trim() ?? '';
    final int? parsed = int.tryParse(normalized);
    if (parsed != null) {
      return parsed;
    }
    final double? parsedDouble = double.tryParse(normalized);
    if (parsedDouble == null) {
      throw FormatException('Nilai integer tidak valid: $value');
    }
    return parsedDouble.round();
  }

  static DateTime _readDateTime(Map<String, dynamic> payload, String key) {
    final String value = _readString(payload, key);
    final DateTime? parsed = DateTime.tryParse(value);
    if (parsed == null) {
      throw FormatException(
        'Field "$key" bukan timestamp ISO 8601 yang valid.',
      );
    }
    return DateTimeUtils.normalizeUtc(parsed);
  }

  static DateTime? _readNullableDateTime(dynamic value) {
    final String? normalized = _readNullableString(value);
    if (normalized == null) {
      return null;
    }
    final DateTime? parsed = DateTime.tryParse(normalized);
    if (parsed == null) {
      throw FormatException('Timestamp tidak valid: $value');
    }
    return DateTimeUtils.normalizeUtc(parsed);
  }
}
