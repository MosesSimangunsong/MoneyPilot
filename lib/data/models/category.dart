import 'package:isar/isar.dart';

part 'category.g.dart';

@collection
class Category {
  Category({
    this.id = Isar.autoIncrement,
    required this.uuid,
    required this.name,
    required this.type,
    required this.iconName,
    required this.colorHex,
    this.isDefault = false,
    this.isDeleted = false,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  Id id;

  @Index(unique: true, replace: true)
  late String uuid;

  @Index(caseSensitive: false)
  late String name;

  @Index()
  late String type;

  late String iconName;
  late String colorHex;

  bool isDefault;

  @Index()
  bool isDeleted;

  late DateTime createdAt;

  @Index()
  late DateTime updatedAt;

  DateTime? deletedAt;
}
