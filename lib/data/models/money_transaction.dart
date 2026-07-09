import 'package:isar/isar.dart';

part 'money_transaction.g.dart';

@collection
class MoneyTransaction {
  MoneyTransaction({
    this.id = Isar.autoIncrement,
    required this.uuid,
    required this.type,
    required this.title,
    required this.amount,
    required this.categoryUuid,
    required this.categoryNameSnapshot,
    this.paymentMethod = 'Tidak Dicatat',
    this.note,
    required this.source,
    this.syncStatus = 'pending',
    this.syncErrorMessage,
    this.isDeleted = false,
    required this.transactionDate,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  Id id;

  @Index(unique: true, replace: true)
  late String uuid;

  @Index()
  late String type;

  @Index(caseSensitive: false)
  late String title;

  late double amount;

  @Index()
  late String categoryUuid;

  late String categoryNameSnapshot;
  late String paymentMethod;
  String? note;

  @Index()
  late String source;

  @Index()
  late String syncStatus;

  String? syncErrorMessage;

  @Index()
  bool isDeleted;

  @Index()
  late DateTime transactionDate;

  late DateTime createdAt;

  @Index()
  late DateTime updatedAt;

  DateTime? deletedAt;
}
