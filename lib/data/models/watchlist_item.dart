import 'package:isar/isar.dart';

part 'watchlist_item.g.dart';

@collection
class WatchlistItem {
  WatchlistItem({
    this.id = Isar.autoIncrement,
    required this.uuid,
    required this.symbol,
    this.companyName,
    required this.market,
    this.targetPrice,
    this.note,
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
  late String market;
  double? targetPrice;
  String? note;

  @Index()
  bool isDeleted;

  late DateTime createdAt;

  @Index()
  late DateTime updatedAt;

  DateTime? deletedAt;
}
