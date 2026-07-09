import 'package:isar/isar.dart';

part 'stock_transaction.g.dart';

@collection
class StockTransaction {
  StockTransaction({
    this.id = Isar.autoIncrement,
    required this.uuid,
    required this.symbol,
    this.companyName,
    required this.actionType,
    required this.lot,
    required this.shares,
    required this.price,
    required this.fee,
    required this.transactionDate,
    this.note,
    this.syncStatus = 'pending',
    this.syncErrorMessage,
    this.isDeleted = false,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  Id id;

  @Index(unique: true, replace: true)
  late String uuid;

  @Index(caseSensitive: false)
  late String symbol;

  String? companyName;

  @Index()
  late String actionType;

  late int lot;
  late int shares;
  late double price;
  late double fee;

  @Index()
  late DateTime transactionDate;

  String? note;

  @Index()
  late String syncStatus;

  String? syncErrorMessage;

  @Index()
  bool isDeleted;

  late DateTime createdAt;

  @Index()
  late DateTime updatedAt;

  DateTime? deletedAt;
}
