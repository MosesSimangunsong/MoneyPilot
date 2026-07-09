import 'package:isar/isar.dart';

part 'dividend.g.dart';

@collection
class Dividend {
  Dividend({
    this.id = Isar.autoIncrement,
    required this.uuid,
    required this.symbol,
    this.companyName,
    required this.grossAmount,
    required this.tax,
    required this.netAmount,
    required this.receivedDate,
    this.linkedTransactionUuid,
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
  late double grossAmount;
  late double tax;
  late double netAmount;

  @Index()
  late DateTime receivedDate;

  String? linkedTransactionUuid;
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
